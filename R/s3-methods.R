#' Print method for `cr_experiment`
#' @param x A `cr_experiment`.
#' @param ... Unused.
#' @return `x` invisibly.
#' @export
print.cr_experiment <- function(x, ...) {
  cli::cli_rule(left = "cr_experiment")
  spatial <- x$spatial_unit
  cli::cli_bullets(c(
    "*" = "Cells: {.val {nrow(x$cells)}} across {.val {length(unique(x$cells[[spatial]]))}} {spatial}s",
    "*" = "Channels: {.val {x$channels$channel}}",
    "*" = "Design: {.val {length(unique(x$design$treatment))}} treatment group{?s}",
    "*" = "QC steps applied: {.val {nrow(x$qc_log)}}"
  ))
  if (length(x$metadata)) {
    cli::cli_alert_info("Metadata fields: {.field {names(x$metadata)}}")
  }
  invisible(x)
}

#' Summary method for `cr_experiment`
#' @param object A `cr_experiment`.
#' @param ... Unused.
#' @return A tibble summarising the experiment (invisibly printed).
#' @export
summary.cr_experiment <- function(object, ...) {
  spatial <- object$spatial_unit
  tbl <- dplyr::left_join(
    object$cells[, c("cell_id", spatial)],
    object$design,
    by = spatial
  )
  out <- dplyr::summarise(
    dplyr::group_by(tbl, .data$treatment),
    n_wells = dplyr::n_distinct(.data[[spatial]]),
    n_cells = dplyr::n(),
    .groups = "drop"
  )
  print(out)
  invisible(out)
}

#' Print method for `cr_result`
#' @param x A `cr_result`.
#' @param ... Unused.
#' @return `x` invisibly.
#' @export
print.cr_result <- function(x, ...) {
  cli::cli_rule(left = "cr_result")
  cmp <- x$comparison
  cli::cli_bullets(c(
    "*" = "Channel: {.val {cmp$channel %||% NA}}",
    "*" = "Treatment: {.val {cmp$treatment %||% NA}}",
    "*" = "Control: {.val {cmp$control %||% NA}}",
    "*" = "Test: {.val {cmp$test %||% NA}}"
  ))
  if (nrow(x$cell_level)) {
    cli::cli_alert_info("Cell-level p = {.val {signif(x$cell_level$p_value[1], 3)}}")
  }
  if (nrow(x$rep_level)) {
    cli::cli_alert_info("Replicate-level p = {.val {signif(x$rep_level$p_value[1], 3)}}")
  }
  if (nrow(x$effect_sizes)) {
    cli::cli_alert_info("Effect sizes: {.field {x$effect_sizes$method}}")
  }
  if (!is.null(x$roc)) {
    cli::cli_alert_info("AUC = {.val {signif(x$roc$auc, 3)}}")
  }
  invisible(x)
}

#' Summary method for `cr_result`
#' @param object A `cr_result`.
#' @param ... Unused.
#' @return The result list, invisibly.
#' @export
summary.cr_result <- function(object, ...) {
  print(object)
  invisible(object)
}

#' Print method for `cr_report`
#' @param x A `cr_report`.
#' @param ... Unused.
#' @return `x` invisibly.
#' @export
print.cr_report <- function(x, ...) {
  cli::cli_rule(left = "cr_report")
  cli::cli_bullets(c(
    "*" = "Analyses: {.val {length(x$results)}}",
    "*" = "Plots queued: {.val {length(x$plots)}}"
  ))
  if (nrow(x$summary)) {
    print(x$summary)
  }
  invisible(x)
}

#' Summary method for `cr_report`
#' @param object A `cr_report`.
#' @param ... Unused.
#' @return `object` invisibly.
#' @export
summary.cr_report <- function(object, ...) {
  print(object)
  invisible(object)
}
