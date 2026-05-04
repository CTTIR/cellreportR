#' Summarize cell-level data to the well / slide level
#'
#' Aggregates the per-cell values for a channel to a single number
#' per spatial unit.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param fun Aggregation function. Default `stats::median`.
#' @return A tibble with one row per spatial unit containing
#'   `well` (or `slide`), `n_cells`, the aggregated `value`, and
#'   the treatment columns from `design`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_summarize_wells(exp, channel = "marker_1")
cr_summarize_wells <- function(experiment, channel, fun = stats::median) {
  cr_validate_experiment(experiment)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  spatial <- experiment$spatial_unit
  by <- experiment$cells[[spatial]]
  v <- experiment$cells[[channel]]
  ag <- tapply(v, by, function(x) fun(x, na.rm = TRUE))
  n <- tapply(v, by, length)
  out <- tibble::tibble(
    !!spatial := names(ag),
    n_cells = as.integer(n),
    value = as.numeric(ag)
  )
  names(out)[1] <- spatial
  out <- dplyr::left_join(out, experiment$design, by = spatial)
  out
}

#' Compute per-well summary metrics
#'
#' Returns a rich set of per-well summary statistics for a single
#' channel: mean, median, SD, MAD, CV, cell count and percent
#' positive above a threshold. Useful as input for QC dashboards.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param positive_threshold Optional numeric threshold. Cells above
#'   it are considered "positive".
#' @return A tibble with one row per spatial unit.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_compute_metrics(exp, channel = "marker_1")
cr_compute_metrics <- function(experiment, channel,
                               positive_threshold = NULL) {
  cr_validate_experiment(experiment)
  spatial <- experiment$spatial_unit
  cells <- experiment$cells
  if (!channel %in% names(cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  split_by_well <- split(cells[[channel]], cells[[spatial]])
  out <- tibble::tibble(
    !!spatial := names(split_by_well),
    n_cells = vapply(split_by_well, length, integer(1)),
    mean = vapply(split_by_well, function(x) mean(x, na.rm = TRUE),
                  numeric(1)),
    median = vapply(split_by_well, function(x) stats::median(x, na.rm = TRUE),
                    numeric(1)),
    sd = vapply(split_by_well, function(x) stats::sd(x, na.rm = TRUE),
                numeric(1)),
    mad = vapply(split_by_well, function(x) stats::mad(x, na.rm = TRUE),
                 numeric(1)),
    cv = NA_real_,
    pct_positive = NA_real_
  )
  names(out)[1] <- spatial
  out$cv <- ifelse(out$mean > 0, out$sd / out$mean, NA_real_)
  if (!is.null(positive_threshold)) {
    out$pct_positive <- vapply(split_by_well, function(x) {
      if (!length(x)) return(NA_real_)
      100 * mean(x > positive_threshold, na.rm = TRUE)
    }, numeric(1))
  }
  out <- dplyr::left_join(out, experiment$design, by = spatial)
  out
}

#' Compute fold change relative to a control group
#'
#' Returns log2 fold changes at the cell and replicate levels
#' (relative to the reference control).
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param control_group Value in `design$treatment` that defines the
#'   reference.
#' @param method `"median"` (default) or `"mean"` — the estimator
#'   used to aggregate within a replicate before taking log2 ratios.
#' @return A list with components `cell` (tibble, one row per cell
#'   with `log2_fc`), `well` (one row per spatial unit) and `summary`
#'   (per treatment, median FC and 95 percent CI across replicates).
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_fold_change(exp, channel = "marker_1", control_group = "Untreated")
cr_fold_change <- function(experiment,
                           channel,
                           control_group,
                           method = c("median", "mean")) {
  cr_validate_experiment(experiment)
  method <- match.arg(method)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  fun <- if (method == "median") stats::median else mean
  wells <- cr_summarize_wells(experiment, channel, fun)
  if (!control_group %in% wells$treatment) {
    cli::cli_abort("Control group {.val {control_group}} not found in design.")
  }
  ctrl_ref <- fun(wells$value[wells$treatment == control_group], na.rm = TRUE)
  if (is.na(ctrl_ref) || ctrl_ref <= 0) {
    cli::cli_abort("Control reference is NA or non-positive.")
  }
  wells$log2_fc <- log2(pmax(wells$value, 1e-6) / ctrl_ref)

  spatial <- experiment$spatial_unit
  # cell-level FC (relative to the same pooled control)
  cell_tbl <- dplyr::left_join(
    experiment$cells[, c("cell_id", spatial, channel)],
    experiment$design[, c(spatial, "treatment")],
    by = spatial
  )
  names(cell_tbl)[3] <- "value"
  cell_tbl$log2_fc <- log2(pmax(cell_tbl$value, 1e-6) / ctrl_ref)

  summary_tbl <- wells |>
    dplyr::group_by(.data$treatment) |>
    dplyr::summarise(
      n_wells = dplyr::n(),
      median_log2_fc = stats::median(.data$log2_fc, na.rm = TRUE),
      mean_log2_fc = mean(.data$log2_fc, na.rm = TRUE),
      sd_log2_fc = stats::sd(.data$log2_fc, na.rm = TRUE),
      .groups = "drop"
    )

  list(cell = cell_tbl, well = wells, summary = summary_tbl)
}
