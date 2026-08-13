# Synthetic example data.
#
# Everything in this file is simulated from a documented statistical
# model under an explicit seed. No measured data ships with the
# package, and no function here reads anything from outside it.
#
# The compact demonstration experiment lives here. Its on-disk writers
# are in R/example-files.R, the ten-compound screen in
# R/example-screen.R and the export tree in R/example-exports.R.


#' Generate a synthetic `cr_experiment`
#'
#' Simulates a compact demonstration experiment: one 96-unit plate
#' format, six treatment levels, four exposure levels, two plates and
#' two pre-treatment intervals. It is small enough that every example
#' in the package can build a fresh copy in well under a second, and
#' structured enough that the batch, quality-control and effect-size
#' functions all have something to work on.
#'
#' Use [cr_example_screen()] instead when a multi-compound screen with
#' per-batch controls, merged analysis units and a specificity arm is
#' needed.
#'
#' @section Generating model:
#' Values are drawn independently per cell from log-normal
#' distributions, so that the marker channels are right-skewed the way
#' measured intensities are:
#'
#' \describe{
#'   \item{unit intercept}{Each unit draws \eqn{u \sim N(0, 0.15^2)},
#'     added to the log mean of every channel in that unit. This is what
#'     makes the unit, and not the cell, the honest replicate.}
#'   \item{target signal}{`marker_1` is
#'     \eqn{\mathrm{LogNormal}(\log 500 + u + e \log 2,\ 0.5^2)}, where
#'     \eqn{e} is the treatment effect in log2 units: `0` untreated,
#'     `1.0` and `3.0` for the low and high exposure level of
#'     `CompoundA`, `3.3` for the positive control, `0.4` for
#'     `CompoundB` and `0.7` for `CompoundC`.}
#'   \item{further channels}{`marker_2` moves against the target signal
#'     at \eqn{-0.4e}, `marker_3` weakly with it at \eqn{0.3e}.}
#'   \item{nuclear stain}{`DAPI` is
#'     \eqn{\mathrm{LogNormal}(\log 500 + u,\ 0.3^2)} and carries no
#'     treatment effect.}
#'   \item{morphology}{Nuclear `area` is
#'     \eqn{\mathrm{LogNormal}(\log 400,\ 0.25^2)} and `circularity` is
#'     \eqn{\mathrm{Beta}(5, 2)}.}
#'   \item{plate position}{Units on the outer rows and columns get a
#'     fixed `+0.07` log bump on every channel, an edge effect for the
#'     plate map to show.}
#'   \item{debris}{Five per cent of the cells of each unit are shrunk to
#'     a twentieth of their area and a tenth of their nuclear signal, so
#'     that the quality-control filters have something to remove.}
#'   \item{artefacts}{Two named units are multiplied up on `marker_1`
#'     and down on `area`, a saturated pair for the outlier screens.}
#' }
#'
#' The random number generator state of the caller is restored on exit,
#' so calling this function does not disturb a seeded analysis.
#'
#' @param seed Random seed. `NULL` uses the current RNG state.
#' @param n_cells_per_well Mean number of cells per unit (Poisson, with
#'   a floor of ten).
#' @param n_wells_per_replicate Number of units per replicate.
#'
#' @return A `cr_experiment` whose `cells` table holds one row per cell
#'   (`cell_id`, `well`, `x`, `y`, `area`, `circularity`, `DAPI`,
#'   `marker_1`, `marker_2`, `marker_3`) and whose `design` table holds
#'   one row per unit, as described in [cr_example_design()].
#'
#' @seealso [cr_example_design()], [cr_example_screen()],
#'   [cr_example_files()].
#' @family example data
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' exp
#' head(exp$design, 3)
cr_example_experiment <- function(seed = 42,
                                  n_cells_per_well = 150,
                                  n_wells_per_replicate = 4) {
  .cr_with_seed(seed, {
    design <- cr_example_design(
      plate_format = 96,
      n_wells_per_replicate = n_wells_per_replicate
    )

    cells_list <- lapply(seq_len(nrow(design)), function(i) {
      row <- design[i, ]
      n <- max(10L, stats::rpois(1, n_cells_per_well))
      .cr_simulate_well(row$well, row$treatment, row$replicate, n)
    })
    cells <- dplyr::bind_rows(cells_list)
    cells$cell_id <- sprintf("c%06d", seq_len(nrow(cells)))

    # Two units carry a saturation artefact, so that the outlier screens
    # have a real target rather than only tail noise.
    artefact <- c("A01", "H12")
    hit <- cells$well %in% artefact
    if (any(hit)) {
      cells$marker_1[hit] <- cells$marker_1[hit] * stats::runif(sum(hit), 3, 6)
      cells$area[hit] <- cells$area[hit] * stats::runif(sum(hit), 0.1, 0.3)
    }

    channels <- tibble::tibble(
      channel = c("DAPI", "marker_1", "marker_2", "marker_3"),
      role = c("nuclear_stain", "marker", "marker", "marker"),
      target = c(NA_character_, "target signal", "secondary readout",
                 "tertiary readout"),
      fluorophore = c("blue", "green", "orange", "far-red")
    )

    cr_build_experiment(
      cells = cells,
      design = design,
      channels = channels,
      plate_info = list(
        format = 96,
        microscope = "Example Widefield",
        date = "2026-01-01",
        operator = "example"
      ),
      metadata = list(project = "cellreportR example", sop = "SYN-001"),
      batch_vars = c("plate", "interval")
    )
  })
}

#' Generate an example experimental design
#'
#' Builds the unit-level design table used by
#' [cr_example_experiment()]. Six treatment levels are crossed with two
#' plates and two pre-treatment intervals, so that a batch is the
#' *combination* of plate and interval rather than a single column and
#' every batch still contains untreated units to standardise against.
#'
#' Treatment names are deliberately abstract. `Untreated` is the vehicle
#' level, `PosControl` a positive control, and `CompoundA` appears at a
#' low and a high exposure level so that a dose axis exists;
#' `CompoundB` and `CompoundC` are further compounds at the low exposure
#' level. The four distinct values of `dose` are the four exposure
#' levels of the demonstration assay.
#'
#' @param plate_format Either `96` or `384`.
#' @param n_wells_per_replicate Number of units per replicate per
#'   treatment level.
#'
#' @return A tibble with one row per unit and the columns `well`,
#'   `treatment`, `dose`, `dose_unit`, `group`, `replicate`, `plate`,
#'   `interval` and `timepoint`.
#'
#' @seealso [cr_example_experiment()], [cr_example_screen()].
#' @family example data
#' @export
#' @examples
#' design <- cr_example_design(96)
#' table(design$treatment, design$interval)
cr_example_design <- function(plate_format = 96,
                              n_wells_per_replicate = 4) {
  if (!plate_format %in% c(96, 384)) {
    cli::cli_abort("Only 96 and 384-well formats are supported.")
  }

  treatments <- tibble::tribble(
    ~treatment,        ~dose, ~dose_unit, ~group,
    "Untreated",           0,     "uM",   "control",
    "PosControl",        100,     "uM",   "positive",
    "CompoundA_low",      50,     "uM",   "treated",
    "CompoundA_high",    500,     "uM",   "treated",
    "CompoundB",          50,     "uM",   "combination",
    "CompoundC",          50,     "uM",   "combination"
  )

  n_groups <- nrow(treatments)
  n_replicates <- 4
  wells_needed <- n_groups * n_replicates * n_wells_per_replicate
  capacity <- plate_format
  if (wells_needed > capacity) {
    cli::cli_abort("{wells_needed} wells needed but plate only has {capacity}.")
  }

  if (plate_format == 96) {
    rows <- LETTERS[1:8]
    cols <- 1:12
  } else {
    rows <- LETTERS[1:16]
    cols <- 1:24
  }
  all_wells <- as.vector(outer(rows, sprintf("%02d", cols), paste0))
  wells <- all_wells[seq_len(wells_needed)]

  per_level <- n_replicates * n_wells_per_replicate
  replicate <- rep(rep(seq_len(n_replicates), each = n_wells_per_replicate),
                   times = n_groups)
  within_replicate <- rep(seq_len(n_wells_per_replicate),
                          times = n_replicates * n_groups)

  tibble::tibble(
    well = wells,
    treatment = rep(treatments$treatment, each = per_level),
    dose = rep(treatments$dose, each = per_level),
    dose_unit = rep(treatments$dose_unit, each = per_level),
    group = rep(treatments$group, each = per_level),
    replicate = replicate,
    # Plate and interval are crossed with treatment, so that every batch
    # holds untreated units to standardise against.
    plate = ifelse(within_replicate <= ceiling(n_wells_per_replicate / 2),
                   "Plate_1", "Plate_2"),
    interval = ifelse(replicate <= ceiling(n_replicates / 2),
                      "15min", "60min"),
    timepoint = 24
  )
}

# ---- internal generators ---------------------------------------------------

# Simulate one unit of cells. The model is documented in the
# "Generating model" section of cr_example_experiment().
.cr_simulate_well <- function(well, treatment, replicate, n) {
  eff <- switch(
    treatment,
    "Untreated"      = 0,
    "PosControl"     = 3.3,
    "CompoundA_low"  = 1.0,
    "CompoundA_high" = 3.0,
    "CompoundB"      = 0.4,
    "CompoundC"      = 0.7,
    0
  )

  # Unit-to-unit random intercept: the reason the unit and not the cell
  # is the replicate.
  well_noise <- stats::rnorm(1, 0, 0.15)

  # The second readout moves against the target signal.
  secondary_eff <- -eff * 0.4

  row_letter <- substr(well, 1, 1)
  col_number <- suppressWarnings(as.integer(substr(well, 2, nchar(well))))
  edge <- (row_letter %in% c("A", "H") || col_number %in% c(1, 12))
  edge_bump <- if (edge) 0.07 else 0

  x <- stats::runif(n, 0, 2000)
  y <- stats::runif(n, 0, 2000)

  dapi <- stats::rlnorm(n, meanlog = log(500) + well_noise + edge_bump,
                        sdlog = 0.3)

  m1_baseline <- log(500) + well_noise + edge_bump
  m1_mean <- m1_baseline + eff * log(2) + stats::rnorm(1, 0, 0.05)
  marker_1 <- stats::rlnorm(n, meanlog = m1_mean, sdlog = 0.5)

  m2_mean <- log(800) + secondary_eff * log(2) + well_noise + edge_bump
  marker_2 <- stats::rlnorm(n, meanlog = m2_mean, sdlog = 0.35)

  m3_mean <- log(300) + 0.3 * eff * log(2) + well_noise + edge_bump
  marker_3 <- stats::rlnorm(n, meanlog = m3_mean, sdlog = 0.4)

  area <- stats::rlnorm(n, meanlog = log(400), sdlog = 0.25)
  circ <- stats::rbeta(n, 5, 2)

  # Debris: small objects with almost no nuclear signal.
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

# Version 0.1.0
