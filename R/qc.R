#' Filter cells by morphology
#'
#' Removes debris and artifacts by thresholding morphological
#' measurements. Any parameter left at `NA` is not applied.
#'
#' @param experiment A `cr_experiment`.
#' @param min_area,max_area Numeric area thresholds. Cells outside the
#'   inclusive interval are removed.
#' @param min_circularity,max_circularity Circularity thresholds
#'   (range 0-1).
#' @return A modified `cr_experiment` with fewer cells and a QC log
#'   entry.
#' @seealso [cr_exclude_small()] for a data-derived (quantile) area
#'   threshold, and [cr_qc_summary()] for the log.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 50)
#' exp2 <- cr_qc_filter(exp, min_area = 100, max_area = 2000)
#' cr_n_cells(exp2)
cr_qc_filter <- function(experiment,
                         min_area = NA,
                         max_area = NA,
                         min_circularity = NA,
                         max_circularity = NA) {
  cr_validate_experiment(experiment)
  cells <- experiment$cells
  before <- nrow(cells)
  params <- list()
  if (!is.na(min_area) && "area" %in% names(cells)) {
    cells <- cells[cells$area >= min_area, , drop = FALSE]
    params$min_area <- min_area
  }
  if (!is.na(max_area) && "area" %in% names(cells)) {
    cells <- cells[cells$area <= max_area, , drop = FALSE]
    params$max_area <- max_area
  }
  if (!is.na(min_circularity) && "circularity" %in% names(cells)) {
    cells <- cells[cells$circularity >= min_circularity, , drop = FALSE]
    params$min_circularity <- min_circularity
  }
  if (!is.na(max_circularity) && "circularity" %in% names(cells)) {
    cells <- cells[cells$circularity <= max_circularity, , drop = FALSE]
    params$max_circularity <- max_circularity
  }
  experiment$cells <- cells
  experiment <- .cr_log_qc(experiment, "cr_qc_filter",
                           .cr_params_str(params),
                           before, nrow(cells))
  experiment
}

#' Flag or remove doublets
#'
#' Flags cells whose size or DNA content is far above the population
#' median, which in microscopy typically indicates segmented
#' doublets. The cells are removed and recorded in the QC log.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Name of the channel column used when
#'   `threshold_method = "channel"` (for example a nuclear stain whose
#'   integrated intensity scales with DNA content). Ignored for
#'   `threshold_method = "area"`.
#' @param threshold_method `"area"` (default) thresholds the
#'   segmentation area; `"channel"` thresholds `channel`.
#' @param k Multiplicative threshold: cells whose value exceeds
#'   `k * median` are removed. Default `2.5`.
#' @return A modified `cr_experiment`.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_qc_doublets(exp, threshold_method = "area")
#' cr_qc_doublets(exp, channel = "DAPI", threshold_method = "channel")
cr_qc_doublets <- function(experiment,
                           channel = NULL,
                           threshold_method = c("area", "channel"),
                           k = 2.5) {
  cr_validate_experiment(experiment)
  threshold_method <- match.arg(threshold_method)
  cells <- experiment$cells
  before <- nrow(cells)
  var <- if (threshold_method == "area") "area" else channel
  if (is.null(var) || !var %in% names(cells)) {
    cli::cli_warn(c(
      "Doublet method {.val {threshold_method}} not applied.",
      "x" = "Column {.field {var %||% 'channel'}} is missing from the cells table."
    ))
  } else {
    cutoff <- k * stats::median(cells[[var]], na.rm = TRUE)
    cells <- cells[!is.na(cells[[var]]) & cells[[var]] <= cutoff, , drop = FALSE]
  }
  experiment$cells <- cells
  experiment <- .cr_log_qc(
    experiment, "cr_qc_doublets",
    .cr_params_str(list(method = threshold_method, variable = var, k = k)),
    before, nrow(cells)
  )
  experiment
}

#' Gate cells by intensity
#'
#' Removes cells whose intensity on a given channel is outside the
#' interval `[min_intensity, max_intensity]`.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Name of the channel column in `cells`.
#' @param min_intensity,max_intensity Lower and upper bounds. Leave
#'   `NA` to skip either.
#' @return A modified `cr_experiment`.
#' @seealso [cr_qc_gate()] for a gate against each unit's own
#'   in-batch control rather than an absolute bound.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_qc_intensity(exp, channel = "DAPI", min_intensity = 50)
cr_qc_intensity <- function(experiment,
                            channel,
                            min_intensity = NA,
                            max_intensity = NA) {
  cr_validate_experiment(experiment)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  cells <- experiment$cells
  before <- nrow(cells)
  v <- cells[[channel]]
  keep <- rep(TRUE, length(v))
  if (!is.na(min_intensity)) keep <- keep & v >= min_intensity
  if (!is.na(max_intensity)) keep <- keep & v <= max_intensity
  experiment$cells <- cells[keep, , drop = FALSE]
  experiment <- .cr_log_qc(
    experiment, "cr_qc_intensity",
    .cr_params_str(list(channel = channel,
                        min_intensity = min_intensity,
                        max_intensity = max_intensity)),
    before, nrow(experiment$cells)
  )
  experiment
}

#' Manually exclude wells or cells
#'
#' Removes entire wells/slides and/or specific cell IDs (for example
#' contaminated wells or cells with focus issues).
#'
#' @param experiment A `cr_experiment`.
#' @param well Character vector of well / slide identifiers to
#'   remove. Default `NULL`.
#' @param cell_ids Character vector of cell IDs to remove.
#' @return A modified `cr_experiment`.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' cr_qc_manual(exp, well = c("A01", "H12"))
cr_qc_manual <- function(experiment, well = NULL, cell_ids = NULL) {
  cr_validate_experiment(experiment)
  spatial <- experiment$spatial_unit
  cells <- experiment$cells
  before <- nrow(cells)
  if (!is.null(well)) {
    cells <- cells[!cells[[spatial]] %in% well, , drop = FALSE]
  }
  if (!is.null(cell_ids)) {
    cells <- cells[!cells$cell_id %in% cell_ids, , drop = FALSE]
  }
  experiment$cells <- cells
  experiment <- .cr_log_qc(
    experiment, "cr_qc_manual",
    .cr_params_str(list(wells = length(well), cells = length(cell_ids))),
    before, nrow(cells)
  )
  experiment
}

#' Summarise QC steps applied to an experiment
#'
#' @param experiment A `cr_experiment`.
#' @return A tibble with one row per QC step: `step`, `parameters`,
#'   `cells_before`, `cells_after`, `cells_removed`,
#'   `percent_removed` and `timestamp`.
#' @seealso [cr_qc_report()] for a per-unit rather than per-step view.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' exp <- cr_qc_filter(exp, min_area = 50)
#' cr_qc_summary(exp)
cr_qc_summary <- function(experiment) {
  cr_validate_experiment(experiment)
  experiment$qc_log
}

# Internal: format a small list of parameters as a string
.cr_params_str <- function(params) {
  params <- params[!vapply(params, is.null, logical(1))]
  if (!length(params)) return("")
  paste(names(params), vapply(params, function(v) {
    if (is.null(v)) "NULL" else as.character(v)[1]
  }, character(1)), sep = "=", collapse = ", ")
}

# Internal: resolve the analysis unit column of an experiment.
# Falls back to the spatial unit so that experiments built before the
# unit slot existed keep working.
.cr_qc_unit <- function(experiment, unit = NULL) {
  unit <- unit %||% experiment$unit_var %||% experiment$spatial_unit
  if (!is.character(unit) || length(unit) != 1L) {
    cli::cli_abort("{.arg unit} must be a single column name.")
  }
  if (!unit %in% names(experiment$cells)) {
    cli::cli_abort(c(
      "Unit column {.field {unit}} not found in the cells table.",
      "i" = "Available: {.field {utils::head(names(experiment$cells), 10)}}"
    ))
  }
  unit
}

# Internal: cells augmented with the design columns they do not carry
.cr_qc_cells <- function(experiment) {
  cells <- experiment$cells
  design <- experiment$design
  spatial <- experiment$spatial_unit
  extra <- setdiff(names(design), names(cells))
  if (!length(extra)) return(cells)
  dplyr::left_join(cells, design[c(spatial, extra)], by = spatial)
}

# Internal: abort when required columns are absent
.cr_qc_require <- function(tbl, cols, what = "cells table") {
  cols <- cols[!is.na(cols)]
  missing <- setdiff(cols, names(tbl))
  if (length(missing)) {
    cli::cli_abort(c(
      "{length(missing)} required column{?s} missing from the {what}.",
      "x" = "Not found: {.field {missing}}.",
      "i" = "Available: {.field {utils::head(names(tbl), 12)}}"
    ))
  }
  invisible(TRUE)
}

# Internal: collapse several columns into one grouping key
.cr_qc_key <- function(tbl, vars) {
  do.call(paste, c(unname(as.list(tbl[vars])), sep = "\r"))
}

# Internal: validate an optional positive whole-number argument
.cr_qc_count <- function(x, arg) {
  if (is.null(x)) return(invisible(TRUE))
  if (!is.numeric(x) || length(x) != 1L || !is.finite(x) || x < 1) {
    cli::cli_abort("{.arg {arg}} must be a single positive number of cells.")
  }
  invisible(TRUE)
}

# Internal: evaluate `expr` under `seed`, restoring the caller's RNG
# state on exit. `seed = NULL` evaluates `expr` untouched.
.cr_with_seed <- function(seed, expr) {
  if (is.null(seed)) return(expr)
  has_old <- exists(".Random.seed", envir = globalenv(), inherits = FALSE)
  if (has_old) {
    old <- get(".Random.seed", envir = globalenv(), inherits = FALSE)
  }
  on.exit({
    if (has_old) {
      assign(".Random.seed", old, envir = globalenv())
    } else if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
      rm(".Random.seed", envir = globalenv())
    }
  }, add = TRUE)
  set.seed(seed)
  expr
}

# Version 0.1.0
