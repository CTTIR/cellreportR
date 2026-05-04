#' Generate a synthetic `cr_experiment`
#'
#' Creates a realistic synthetic cell-culture microscopy data set for
#' demonstration and testing. The simulated experiment has six
#' treatment groups, four replicates per group and 96 wells in total.
#' Four fluorescence channels are generated: a nuclear stain (`DAPI`),
#' a damage marker (`marker_1`), a viability marker (`marker_2`) and a
#' secondary readout (`marker_3`).
#'
#' @param seed Random seed.
#' @param n_cells_per_well Mean number of cells per well (Poisson).
#' @param n_wells_per_replicate Number of wells per replicate.
#' @return A `cr_experiment`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' print(exp)
cr_example_experiment <- function(seed = 42,
                                  n_cells_per_well = 150,
                                  n_wells_per_replicate = 4) {
  set.seed(seed)

  design <- cr_example_design(plate_format = 96,
                              n_wells_per_replicate = n_wells_per_replicate)

  cells_list <- lapply(seq_len(nrow(design)), function(i) {
    row <- design[i, ]
    n <- max(10L, stats::rpois(1, n_cells_per_well))
    .cr_simulate_well(row$well, row$treatment, row$replicate, n)
  })
  cells <- dplyr::bind_rows(cells_list)
  cells$cell_id <- sprintf("c%06d", seq_len(nrow(cells)))

  # Introduce contamination / artifacts in 2 wells to exercise QC
  contaminated <- c("A01", "H12")
  hit <- cells$well %in% contaminated
  if (any(hit)) {
    cells$marker_1[hit] <- cells$marker_1[hit] * stats::runif(sum(hit), 3, 6)
    cells$area[hit] <- cells$area[hit] * stats::runif(sum(hit), 0.1, 0.3)
  }

  channels <- tibble::tibble(
    channel = c("DAPI", "marker_1", "marker_2", "marker_3"),
    role = c("nuclear_stain", "marker", "marker", "marker"),
    antibody = c(NA, "damage-Ab", "viability-Ab", "secondary-Ab"),
    fluorophore = c("DAPI", "AF488", "AF555", "AF647")
  )

  cr_build_experiment(
    cells = cells,
    design = design,
    channels = channels,
    plate_info = list(
      format = 96,
      microscope = "Example Widefield",
      date = as.character(Sys.Date()),
      operator = "example"
    ),
    metadata = list(project = "cellreportR example", sop = "SYN-001")
  )
}

#' Generate an example experimental design
#'
#' @param plate_format 96 or 384.
#' @param n_wells_per_replicate Number of wells per replicate per
#'   treatment group.
#' @return A tibble of design columns: `well`, `treatment`, `dose`,
#'   `dose_unit`, `replicate`, `group`, `timepoint`.
#' @export
#' @examples
#' cr_example_design(96)
cr_example_design <- function(plate_format = 96,
                              n_wells_per_replicate = 4) {
  if (!plate_format %in% c(96, 384)) {
    cli::cli_abort("Only 96 and 384-well formats are supported.")
  }

  treatments <- tibble::tribble(
    ~treatment,             ~dose, ~dose_unit, ~group,
    "Untreated",              0,     "uM",    "control",
    "PosControl",           100,     "uM",    "positive",
    "CompoundA_low",         50,     "uM",    "treated",
    "CompoundA_high",       500,     "uM",    "treated",
    "CompoundA_ScavX",       50,     "uM",    "rescue",
    "CompoundA_ScavY",       50,     "uM",    "rescue"
  )

  n_groups <- nrow(treatments)
  n_replicates <- 4
  wells_needed <- n_groups * n_replicates * n_wells_per_replicate
  capacity <- plate_format
  if (wells_needed > capacity) {
    cli::cli_abort("{wells_needed} wells needed but plate only has {capacity}.")
  }

  if (plate_format == 96) {
    rows <- LETTERS[1:8]; cols <- 1:12
  } else {
    rows <- LETTERS[1:16]; cols <- 1:24
  }
  all_wells <- as.vector(outer(rows, sprintf("%02d", cols), paste0))

  wells <- all_wells[seq_len(wells_needed)]

  design <- tibble::tibble(
    well = wells,
    treatment = rep(treatments$treatment,
                    each = n_replicates * n_wells_per_replicate),
    dose = rep(treatments$dose,
               each = n_replicates * n_wells_per_replicate),
    dose_unit = rep(treatments$dose_unit,
                    each = n_replicates * n_wells_per_replicate),
    group = rep(treatments$group,
                each = n_replicates * n_wells_per_replicate),
    replicate = rep(rep(seq_len(n_replicates),
                        each = n_wells_per_replicate),
                    times = n_groups),
    timepoint = 24
  )
  design
}

#' Write example files in multiple formats to a directory
#'
#' Writes the example cells and design tables in several on-disk
#' formats to demonstrate the `cr_read_*` importers.
#'
#' @param dir Directory to write into. Must exist.
#' @param seed Seed passed to [cr_example_experiment()].
#' @return A character vector of written file paths (invisibly).
#' @export
#' @examples
#' d <- tempfile("cr_example_"); dir.create(d)
#' cr_example_files(d)
cr_example_files <- function(dir = tempdir(), seed = 42) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  exp <- cr_example_experiment(seed = seed, n_cells_per_well = 50)

  out <- character()

  cells_path <- file.path(dir, "cells.csv")
  readr::write_csv(exp$cells, cells_path)
  out <- c(out, cells_path)

  if (requireNamespace("writexl", quietly = TRUE)) {
    design_path <- file.path(dir, "design.xlsx")
    writexl::write_xlsx(exp$design, design_path)
    out <- c(out, design_path)
  } else {
    design_path <- file.path(dir, "design.csv")
    readr::write_csv(exp$design, design_path)
    out <- c(out, design_path)
  }

  cp_tbl <- .cr_to_cellprofiler(exp$cells)
  cp_path <- file.path(dir, "cells_cellprofiler.csv")
  readr::write_csv(cp_tbl, cp_path)
  out <- c(out, cp_path)

  qp_tbl <- .cr_to_qupath(exp$cells)
  qp_path <- file.path(dir, "cells_qupath.tsv")
  readr::write_tsv(qp_tbl, qp_path)
  out <- c(out, qp_path)

  invisible(out)
}

# Internal: simulate one well of cells with realistic fluorescence.
.cr_simulate_well <- function(well, treatment, replicate, n) {
  # Treatment-dependent effect on marker_1 (log2 FC)
  eff <- switch(
    treatment,
    "Untreated"        = 0,
    "PosControl"       = 3.3,
    "CompoundA_low"    = 1.0,
    "CompoundA_high"   = 3.0,
    "CompoundA_ScavX"  = 0.4,
    "CompoundA_ScavY"  = 0.7,
    0
  )

  # Small well-to-well random intercept
  well_noise <- stats::rnorm(1, 0, 0.15)

  # Marker_2 (viability) negatively correlates with damage
  viability_eff <- -eff * 0.4

  # Plate edge effect
  row_letter <- substr(well, 1, 1)
  col_number <- suppressWarnings(as.integer(substr(well, 2, nchar(well))))
  edge <- (row_letter %in% c("A", "H") || col_number %in% c(1, 12))
  edge_bump <- if (edge) 0.07 else 0

  # Position (uniform inside a unit square; scale up to "pixels")
  x <- stats::runif(n, 0, 2000)
  y <- stats::runif(n, 0, 2000)

  # DAPI — log-normal
  dapi <- stats::rlnorm(n, meanlog = log(500) + well_noise + edge_bump, sdlog = 0.3)

  # Damage marker 1 — log-normal, sensitive to treatment
  m1_baseline <- log(500) + well_noise + edge_bump
  m1_mean <- m1_baseline + eff * log(2) + stats::rnorm(1, 0, 0.05)
  marker_1 <- stats::rlnorm(n, meanlog = m1_mean, sdlog = 0.5)

  # Viability marker
  m2_mean <- log(800) + viability_eff * log(2) + well_noise + edge_bump
  marker_2 <- stats::rlnorm(n, meanlog = m2_mean, sdlog = 0.35)

  # Secondary readout (weak effect)
  m3_mean <- log(300) + 0.3 * eff * log(2) + well_noise + edge_bump
  marker_3 <- stats::rlnorm(n, meanlog = m3_mean, sdlog = 0.4)

  # Morphology
  area <- stats::rlnorm(n, meanlog = log(400), sdlog = 0.25)
  circ <- stats::rbeta(n, 5, 2)

  # Add 5% debris (very small area, very low DAPI)
  n_debris <- max(0, round(0.05 * n))
  if (n_debris > 0) {
    idx <- sample(n, n_debris)
    area[idx] <- area[idx] * 0.05
    dapi[idx] <- dapi[idx] * 0.1
  }

  tibble::tibble(
    cell_id = NA_character_,
    well = well,
    x = x,
    y = y,
    area = area,
    circularity = circ,
    DAPI = dapi,
    marker_1 = marker_1,
    marker_2 = marker_2,
    marker_3 = marker_3
  )
}

# Internal converters for demo file formats
.cr_to_cellprofiler <- function(cells) {
  out <- tibble::tibble(
    ImageNumber = as.integer(factor(cells$well)),
    ObjectNumber = seq_len(nrow(cells)),
    Metadata_Well = cells$well,
    AreaShape_Area = cells$area,
    AreaShape_FormFactor = cells$circularity,
    Location_Center_X = cells$x,
    Location_Center_Y = cells$y,
    Intensity_MeanIntensity_DAPI = cells$DAPI,
    Intensity_MeanIntensity_marker_1 = cells$marker_1,
    Intensity_MeanIntensity_marker_2 = cells$marker_2,
    Intensity_MeanIntensity_marker_3 = cells$marker_3
  )
  out
}

.cr_to_qupath <- function(cells) {
  tibble::tibble(
    Image = paste0(cells$well, ".ome.tif"),
    `Object ID` = cells$cell_id,
    `Name` = "Cell",
    `Parent` = cells$well,
    `Centroid X um` = cells$x,
    `Centroid Y um` = cells$y,
    `Cell: Area um^2` = cells$area,
    `Cell: Circularity` = cells$circularity,
    `Cell: DAPI mean` = cells$DAPI,
    `Cell: marker_1 mean` = cells$marker_1,
    `Cell: marker_2 mean` = cells$marker_2,
    `Cell: marker_3 mean` = cells$marker_3
  )
}
