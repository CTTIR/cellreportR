# Synthetic multi-compound screen.
#
# The compact demonstration experiment in R/example-data.R is a single
# plate. The screen simulated here is the shape the screening functions
# were written for: several compounds, two experiments, plates within
# experiments, a vehicle control inside every batch, analysis units
# assembled from more than one file, and an arm that is deliberately not
# part of the screen. The matching on-disk export tree is written by
# cr_example_exports() in R/example-exports.R.


# Fixed vocabulary of the synthetic screen.
.cr_screen_intervals <- c("15min", "60min")
.cr_screen_doses <- c(0, 10, 50, 250)

#' Generate a synthetic multi-compound screen
#'
#' Simulates a screen of up to ten compounds, each acquired at four
#' exposure levels and two pre-treatment intervals, on two plates and in
#' two experiments. Unlike [cr_example_experiment()] the analysis unit is
#' not the raw plate well: units carry file provenance, some are
#' assembled from more than one acquisition, and one arm is set aside
#' instead of screened.
#'
#' Everything the screening functions need is present: a vehicle control
#' inside every batch for [cr_batch_reference()] and
#' [cr_standardize_batch()], one unit that fails a control-referenced
#' gate for [cr_qc_gate()], enough units per arm for [cr_effect_grid()],
#' plates crossed with arms for [cr_blocked_effect()], and a
#' reagent-omitted arm in `set_aside`.
#'
#' @section Generating model:
#' A batch is the combination of `compound`, `experiment`, `plate` and
#' `interval`. Writing \eqn{p_c} for the potency of compound \eqn{c},
#' \eqn{d} for the exposure level and \eqn{u_w} for the unit intercept:
#'
#' \describe{
#'   \item{potency}{\eqn{p_c} runs from `1.6` down to `0.1` in equal
#'     steps from `CompoundA` to the last compound, so the rank order of
#'     the screen is known in advance and the top hit is a hit by
#'     construction rather than by chance.}
#'   \item{exposure}{The response saturates in dose as
#'     \eqn{d / (d + 40)}, so the four exposure levels are not equally
#'     spaced in effect.}
#'   \item{interval}{The longer pre-treatment interval multiplies the
#'     effect by `1.15`.}
#'   \item{effect}{\eqn{e = p_c \cdot d/(d + 40) \cdot g_{interval}}, in
#'     log2 units against the vehicle of the same batch.}
#'   \item{unit intercept}{\eqn{u_w \sim N(0, 0.12^2)} on the log scale,
#'     one draw per unit.}
#'   \item{acquisition offsets}{The second experiment has a `1.35` times
#'     higher raw baseline and the second plate a `1.08` times higher
#'     one. Both act on control and treated units alike, which is what
#'     standardising against the control of a unit's own batch removes,
#'     and why raw signal is not comparable across experiments.}
#'   \item{target signal}{\eqn{\mathrm{LogNormal}(\log(400 \cdot g_{exp}
#'     \cdot g_{plate}) + u_w + e \log 2,\ 0.45^2)}.}
#'   \item{nuclear signal}{\eqn{\mathrm{LogNormal}(\log 600 + u_w,\
#'     0.3^2)}, with no treatment effect.}
#'   \item{morphology}{Nuclear `area` is
#'     \eqn{\mathrm{LogNormal}(\log 180,\ 0.3^2)} and `circularity` is
#'     \eqn{\mathrm{Beta}(6, 2)}. Four per cent of objects are shrunk to
#'     an eighth of their area, the sub-threshold debris that
#'     [cr_exclude_small()] is meant to drop.}
#' }
#'
#' @section Planted edge cases:
#' \describe{
#'   \item{gate failure}{One treated unit of the first compound is given
#'     a negative effect, so it sits below the control of its own batch
#'     and fails a control-referenced gate.}
#'   \item{two-pass acquisition}{One unit's cells are split across two
#'     files, the second carrying a `(split)` marker and a `.1`
#'     replicate suffix. Left unmerged it would count twice.}
#'   \item{repeated read}{One unit's cells are split across a file and
#'     its `(repeat)` sibling, which has to merge into it.}
#'   \item{look-alike suffix}{One separate unit is named with a `.2`
#'     replicate suffix, which must *not* merge with the unit named `2`:
#'     it is a different physical unit on a different plate.}
#'   \item{arm outside the screen}{A reagent-omitted arm is generated and
#'     placed in `set_aside` rather than in the analysis pool.}
#' }
#'
#' The random number generator state of the caller is restored on exit.
#'
#' @param seed Random seed. `NULL` uses the current RNG state.
#' @param n_compounds Number of compounds, 1 to 10. They are named
#'   `CompoundA` to `CompoundJ`.
#' @param n_cells_per_well Mean number of cells per unit (Poisson, with a
#'   floor of ten).
#' @param n_units_per_arm Units per compound, experiment, interval and
#'   exposure level. Three or more is needed for the effect-size grid.
#' @param n_experiments Number of experiments, 1 or 2.
#'
#' @return A `cr_experiment` with
#'   \describe{
#'     \item{`cells`}{one row per cell: `cell_id`, `well_id`,
#'       `source_file`, `source_path`, `x`, `y`, `area`, `circularity`,
#'       `nuclear_signal`, `target_signal`.}
#'     \item{`design`}{one row per unit: `well_id`, `compound`,
#'       `experiment`, `plate`, `well`, `interval`, `dose`, `dose_unit`,
#'       `treatment`, `group`, `replicate`.}
#'     \item{`provenance`}{one row per acquisition file, with marker
#'       flags and the number of files each unit was assembled from.}
#'     \item{`set_aside`}{a list whose `reagent_omitted` element holds
#'       the specificity arm.}
#'   }
#'   `unit_var` is `"well_id"` and `batch_vars` is
#'   `c("compound", "experiment", "plate", "interval")`.
#'
#' @seealso [cr_example_experiment()], [cr_example_exports()],
#'   [cr_batch_reference()], [cr_effect_grid()].
#' @family example data
#' @export
#' @examples
#' screen <- cr_example_screen(seed = 1, n_compounds = 3,
#'                             n_cells_per_well = 12)
#' screen
#' table(screen$design$compound, screen$design$treatment)
#'
#' # Units assembled from more than one acquisition file
#' prov <- screen$provenance
#' unique(prov$well_id[prov$n_files > 1])
cr_example_screen <- function(seed = 42,
                              n_compounds = 10,
                              n_cells_per_well = 40,
                              n_units_per_arm = 3,
                              n_experiments = 2) {
  .cr_screen_count(n_compounds, 1, 10)
  .cr_screen_count(n_units_per_arm, 1, 24)
  .cr_screen_count(n_experiments, 1, 2)
  .cr_screen_count(n_cells_per_well, 1, 5000)

  .cr_with_seed(seed, {
    design <- .cr_screen_design(n_compounds, n_units_per_arm, n_experiments)
    cells <- .cr_screen_cells(design, n_cells_per_well)
    cells <- .cr_screen_split_files(cells, design)
    aside <- .cr_screen_aside(design, n_cells_per_well)
    provenance <- .cr_screen_provenance(cells, design)

    channels <- tibble::tibble(
      channel = c("nuclear_signal", "target_signal"),
      role = c("nuclear_stain", "marker"),
      target = c("nuclear counterstain", "target signal"),
      fluorophore = c("blue", "green")
    )

    drop <- c("source_file", "source_path", "effect", "unit")
    cr_build_experiment(
      cells = cells,
      design = design[, setdiff(names(design), drop)],
      channels = channels,
      plate_info = list(
        format = 96,
        microscope = "Example Widefield",
        date = "2026-01-01",
        operator = "example"
      ),
      metadata = list(
        project = "cellreportR example screen",
        design = "compounds x exposure levels x pre-treatment intervals",
        control_level = "Vehicle"
      ),
      unit_var = "well_id",
      batch_vars = c("compound", "experiment", "plate", "interval"),
      provenance = provenance,
      set_aside = list(reagent_omitted = aside)
    )
  })
}

# ---- internal: screen construction -----------------------------------------

# A single whole number within bounds.
.cr_screen_count <- function(x, lo, hi, arg = rlang::caller_arg(x)) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      x < lo || x > hi || x != round(x)) {
    cli::cli_abort(
      c("{.arg {arg}} must be a whole number between {lo} and {hi}.",
        "x" = "Got {.val {x}}.")
    )
  }
  invisible(TRUE)
}

# The unit-level design of the synthetic screen, carrying the per-unit
# effect and the default acquisition file of each unit.
.cr_screen_design <- function(n_compounds, n_units_per_arm, n_experiments) {
  compounds <- paste0("Compound", LETTERS[seq_len(n_compounds)])
  experiments <- paste0("Exp_", seq_len(n_experiments))
  intervals <- .cr_screen_intervals
  doses <- .cr_screen_doses

  grid <- expand.grid(
    unit = seq_len(n_units_per_arm),
    dose = doses,
    interval = intervals,
    experiment = experiments,
    compound = compounds,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  grid <- tibble::as_tibble(grid)

  row_index <- (match(grid$interval, intervals) - 1L) * length(doses) +
    match(grid$dose, doses)
  grid$plate <- paste0("Plate_", ((grid$unit - 1L) %% 2L) + 1L)
  grid$well <- sprintf("%s%02d", LETTERS[row_index], grid$unit)
  grid$well_id <- paste(grid$compound, grid$experiment, grid$plate,
                        grid$well, sep = "_")
  grid$treatment <- ifelse(grid$dose == 0, "Vehicle",
                           paste0("Dose_", grid$dose))
  grid$group <- ifelse(grid$dose == 0, "control", "treated")
  grid$replicate <- grid$unit
  grid$dose_unit <- "uM"

  potency <- seq(1.6, 0.1, length.out = n_compounds)
  names(potency) <- compounds
  interval_gain <- ifelse(grid$interval == "60min", 1.15, 1)
  grid$effect <- unname(potency[grid$compound]) *
    (grid$dose / (grid$dose + 40)) * interval_gain

  # One treated unit sits below the control of its own batch.
  fail <- .cr_screen_pick(grid, compounds[[1L]], experiments[[1L]],
                          "60min", max(doses), 1L)
  if (length(fail)) grid$effect[fail] <- -0.6

  core <- ifelse(
    grid$dose == 0,
    sprintf("%s_%s_vehicle", grid$compound, grid$interval),
    sprintf("%s_%s_%duM_treated", grid$compound, grid$interval, grid$dose)
  )
  grid$source_file <- sprintf("%s_%d.csv", core, grid$unit)

  # A look-alike replicate suffix on a genuinely separate unit.
  sep <- .cr_screen_pick(grid, compounds[[1L]], experiments[[1L]],
                         "60min", max(doses), 3L)
  if (length(sep)) grid$source_file[sep] <- sprintf("%s_2.2.csv", core[sep])

  grid$source_path <- file.path("Run1", grid$compound, grid$experiment,
                                grid$plate, grid$source_file)

  cols <- c("well_id", "compound", "experiment", "plate", "well", "interval",
            "dose", "dose_unit", "treatment", "group", "replicate", "unit",
            "effect", "source_file", "source_path")
  grid[, cols]
}

# Row indices of one arm of the design grid.
.cr_screen_pick <- function(grid, compound, experiment, interval, dose, unit) {
  which(grid$compound == compound & grid$experiment == experiment &
          grid$interval == interval & grid$dose == dose & grid$unit == unit)
}

# Draw the cells of every unit of the design.
.cr_screen_cells <- function(design, n_cells_per_well) {
  n_units <- nrow(design)
  n_cells <- pmax(10L, stats::rpois(n_units, n_cells_per_well))
  idx <- rep(seq_len(n_units), times = n_cells)
  total <- length(idx)

  unit_noise <- stats::rnorm(n_units, 0, 0.12)
  exp_gain <- ifelse(design$experiment == "Exp_2", 1.35, 1)
  plate_gain <- ifelse(design$plate == "Plate_2", 1.08, 1)
  baseline <- log(400 * exp_gain * plate_gain)

  target <- stats::rlnorm(
    total,
    meanlog = baseline[idx] + unit_noise[idx] + design$effect[idx] * log(2),
    sdlog = 0.45
  )
  nuclear <- stats::rlnorm(total, meanlog = log(600) + unit_noise[idx],
                           sdlog = 0.3)
  area <- stats::rlnorm(total, meanlog = log(180), sdlog = 0.3)

  # Sub-threshold objects for the area exclusion to find.
  debris <- stats::runif(total) < 0.04
  area[debris] <- area[debris] * 0.125

  tibble::tibble(
    cell_id = sprintf("c%07d", seq_len(total)),
    well_id = design$well_id[idx],
    source_file = design$source_file[idx],
    source_path = design$source_path[idx],
    x = stats::runif(total, 0, 1500),
    y = stats::runif(total, 0, 1500),
    area = area,
    circularity = stats::rbeta(total, 6, 2),
    nuclear_signal = nuclear,
    target_signal = target
  )
}

# Re-attribute part of two units to a second acquisition file, so that
# the unit assignment has genuinely multi-file units to resolve.
.cr_screen_split_files <- function(cells, design) {
  compound <- design$compound[[1L]]
  experiment <- design$experiment[[1L]]
  plan <- list(
    list(unit = 1L, marker = " (split)", suffix = ".1"),
    list(unit = 2L, marker = " (repeat)", suffix = "")
  )
  for (p in plan) {
    rows <- .cr_screen_pick(design, compound, experiment, "15min",
                            max(.cr_screen_doses), p$unit)
    if (!length(rows)) next
    in_unit <- which(cells$well_id == design$well_id[[rows[[1L]]]])
    if (length(in_unit) < 4L) next
    second <- in_unit[seq(floor(length(in_unit) / 2) + 1L, length(in_unit))]
    stem <- sub("\\.csv$", "", design$source_file[[rows[[1L]]]])
    stem <- sub("_([0-9]+)$", paste0("_\\1", p$suffix), stem)
    new_file <- paste0(stem, p$marker, ".csv")
    cells$source_file[second] <- new_file
    cells$source_path[second] <- file.path(
      dirname(design$source_path[[rows[[1L]]]]), new_file
    )
  }
  cells
}

# The specificity arm: acquired with the detection reagent omitted and
# therefore never part of the screening pool.
.cr_screen_aside <- function(design, n_cells_per_well) {
  all_compounds <- unique(design$compound)
  compounds <- all_compounds[seq_len(min(2L, length(all_compounds)))]
  top_dose <- max(.cr_screen_doses)

  arm <- expand.grid(
    unit = seq_len(3L),
    dose = c(0, top_dose),
    compound = compounds,
    KEEP.OUT.ATTRS = FALSE,
    stringsAsFactors = FALSE
  )
  arm <- tibble::as_tibble(arm)
  arm$experiment <- design$experiment[[1L]]
  arm$interval <- "60min"
  arm$plate <- "Plate_1"
  arm$treatment <- ifelse(arm$dose == 0, "Vehicle", paste0("Dose_", arm$dose))
  arm$arm <- ifelse(arm$dose == 0, "reagent omitted + vehicle",
                    "reagent omitted + exposed")
  arm$well_id <- sprintf("%s_%s_omitted_%s%02d", arm$compound, arm$experiment,
                         ifelse(arm$dose == 0, "A", "B"), arm$unit)
  mode <- ifelse(arm$dose == 0, "vehicle",
                 sprintf("%duM_treated", top_dose))
  arm$source_file <- sprintf("%s_60min_%s (no reagent)_%d.csv",
                             arm$compound, mode, arm$unit)

  n_cells <- pmax(10L, stats::rpois(nrow(arm), n_cells_per_well))
  idx <- rep(seq_len(nrow(arm)), times = n_cells)
  total <- length(idx)
  unit_noise <- stats::rnorm(nrow(arm), 0, 0.12)

  tibble::tibble(
    cell_id = sprintf("o%06d", seq_len(total)),
    well_id = arm$well_id[idx],
    source_file = arm$source_file[idx],
    compound = arm$compound[idx],
    experiment = arm$experiment[idx],
    plate = arm$plate[idx],
    interval = arm$interval[idx],
    dose = arm$dose[idx],
    treatment = arm$treatment[idx],
    arm = arm$arm[idx],
    area = stats::rlnorm(total, meanlog = log(180), sdlog = 0.3),
    nuclear_signal = stats::rlnorm(total, meanlog = log(600) + unit_noise[idx],
                                   sdlog = 0.3),
    # No detection reagent: background only, and unmoved by exposure.
    target_signal = stats::rlnorm(total, meanlog = log(48) + unit_noise[idx],
                                  sdlog = 0.4)
  )
}

# One row per acquisition file, with the marker flags recovered from the
# file name and the number of files each unit was assembled from.
.cr_screen_provenance <- function(cells, design) {
  prov <- dplyr::summarise(
    dplyr::group_by(cells, .data$source_path, .data$source_file,
                    .data$well_id),
    n_cells = dplyr::n(),
    .groups = "drop"
  )
  keys <- c("well_id", "compound", "experiment", "plate", "interval",
            "dose", "treatment")
  prov <- dplyr::left_join(prov, design[, keys], by = "well_id")
  prov <- dplyr::ungroup(
    dplyr::mutate(dplyr::group_by(prov, .data$well_id),
                  n_files = dplyr::n())
  )
  prov$merge_unit <- grepl("(split)", prov$source_file, fixed = TRUE)
  prov$reacquisition <- grepl("(repeat)", prov$source_file, fixed = TRUE)
  prov$omitted_reagent <- FALSE
  prov$partial_plate <- FALSE
  prov$variant <- NA_character_
  prov[order(prov$source_path), ]
}

# Version 0.1.0
