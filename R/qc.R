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
#' Flags cells whose area is far above the population median, which
#' in microscopy typically indicates segmented doublets. The cells
#' are removed and recorded in the QC log.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Unused in the default method but kept for API
#'   symmetry; future implementations may use DNA content.
#' @param threshold_method Currently only `"area"` is supported.
#' @param k Multiplicative threshold: cells with area > `k * median`
#'   are removed. Default `2.5`.
#' @return A modified `cr_experiment`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_qc_doublets(exp, threshold_method = "area")
cr_qc_doublets <- function(experiment,
                           channel = NULL,
                           threshold_method = "area",
                           k = 2.5) {
  cr_validate_experiment(experiment)
  cells <- experiment$cells
  before <- nrow(cells)
  if (threshold_method == "area" && "area" %in% names(cells)) {
    cutoff <- k * stats::median(cells$area, na.rm = TRUE)
    cells <- cells[cells$area <= cutoff, , drop = FALSE]
  } else {
    cli::cli_warn("Doublet method {.val {threshold_method}} not applied (missing data).")
  }
  experiment$cells <- cells
  experiment <- .cr_log_qc(experiment, "cr_qc_doublets",
                           .cr_params_str(list(method = threshold_method, k = k)),
                           before, nrow(cells))
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
#' @return A tibble with one row per QC step.
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
  if (!length(params)) return("")
  paste(names(params), vapply(params, function(v) {
    if (is.null(v)) "NULL" else as.character(v)[1]
  }, character(1)), sep = "=", collapse = ", ")
}
