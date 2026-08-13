#' Collect the tables of an analysis
#'
#' Gathers every tabular artifact of an experiment or report into one
#' named list, ready for [cr_export_tables()]. Empty tables are
#' dropped, so the result reflects what actually exists.
#'
#' @param x A `cr_report` or a `cr_experiment`.
#' @param results Optional results to summarize when `x` is a
#'   `cr_experiment`. Ignored for a `cr_report`, which carries its own.
#' @param which Optional character vector selecting a subset of tables
#'   by name. Unknown names are an error that lists what is available.
#' @return A named list of tibbles.
#' @seealso [cr_export_tables()], [cr_table_disposition()],
#'   [cr_table_qc()].
#' @family reporting
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' tabs <- cr_tables(exp)
#' names(tabs)
#' tabs$disposition
cr_tables <- function(x, results = NULL, which = NULL) {
  if (inherits(x, "cr_report")) {
    experiment <- x$experiment
    results <- x$results
    out <- list(
      summary = x$summary,
      effects = x$effects,
      sizes = x$sizes,
      qc = x$qc
    )
    out <- c(out, x$tables)
  } else if (inherits(x, "cr_experiment")) {
    experiment <- x
    results <- .cr_as_results(results)
    out <- list(
      summary = .cr_report_summary(results, NULL, NULL),
      qc = cr_table_qc(x),
      disposition = tryCatch(cr_table_disposition(x), error = function(e) NULL)
    )
  } else {
    cli::cli_abort(c(
      "{.arg x} must be a {.cls cr_report} or a {.cls cr_experiment}.",
      "x" = "Got {.cls {class(x)[[1L]]}}."
    ))
  }

  out$design <- experiment$design
  out$channels <- experiment$channels
  if (length(results)) {
    out$effect_sizes <- .cr_bind_slot(results, "effect_sizes")
    out$fold_change <- .cr_bind_slot(results, "fold_change")
  }

  out <- out[!duplicated(names(out))]
  keep <- vapply(out, function(tb) {
    is.data.frame(tb) && nrow(tb) > 0L
  }, logical(1))
  out <- lapply(out[keep], tibble::as_tibble)

  if (!is.null(which)) {
    missing <- setdiff(which, names(out))
    if (length(missing)) {
      cli::cli_abort(c(
        "Unknown table{?s}: {.val {missing}}.",
        "i" = "Available: {.val {names(out)}}"
      ))
    }
    out <- out[which]
  }
  out
}

#' Tabulate the quality-control record
#'
#' Normalizes the several shapes a QC record can take — an
#' experiment's QC log, a gate object, or a plain data frame — into one
#' tibble suitable for a supplement.
#'
#' @param x A `cr_experiment`, a `cr_report`, a data frame, or a list
#'   holding data frames (for example a gate object with a `units`
#'   element).
#' @return A tibble. For a list of several data frames the elements are
#'   stacked and identified by a `component` column.
#' @seealso [cr_tables()].
#' @family reporting
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' exp <- cr_filter_cells(exp, area > 100)
#' cr_table_qc(exp)
cr_table_qc <- function(x) {
  if (inherits(x, "cr_experiment")) return(tibble::as_tibble(x$qc_log))
  if (inherits(x, "cr_report")) return(tibble::as_tibble(x$qc))
  if (is.data.frame(x)) return(tibble::as_tibble(x))
  if (is.null(x)) return(tibble::tibble())
  if (is.list(x)) {
    if (is.data.frame(x[["units"]])) return(tibble::as_tibble(x[["units"]]))
    dfs <- Filter(is.data.frame, x)
    if (length(dfs)) {
      return(dplyr::bind_rows(dfs, .id = "component"))
    }
  }
  cli::cli_abort(c(
    "Cannot build a QC table from {.cls {class(x)[[1L]]}}.",
    "i" = "Supply a {.cls cr_experiment}, a data frame, or a list of data frames."
  ))
}

# Version 0.1.0
