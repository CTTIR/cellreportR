#' Convert well IDs to row and column indices
#'
#' Splits well identifiers of the form `"A01"` into the letter row
#' and numeric column.
#'
#' @param well A character vector of well IDs (e.g. `"A01"`, `"H12"`,
#'   `"P24"`).
#' @return A tibble with columns `well`, `row` (integer, 1 = A) and
#'   `col` (integer).
#' @export
#' @examples
#' cr_well_to_rowcol(c("A01", "B05", "H12"))
cr_well_to_rowcol <- function(well) {
  well <- as.character(well)
  letters_part <- sub("^([A-Za-z]+).*$", "\\1", well)
  number_part <- sub("^[A-Za-z]+(\\d+)$", "\\1", well)
  row <- .cr_letters_to_row(letters_part)
  col <- suppressWarnings(as.integer(number_part))
  tibble::tibble(well = well, row = row, col = col)
}

#' Convert row and column indices to well IDs
#'
#' @param row Integer vector of row numbers (1 = A, 2 = B, ...).
#' @param col Integer vector of column numbers.
#' @param pad Number of digits to pad the column number to
#'   (default 2, yielding `"A01"` rather than `"A1"`).
#' @return A character vector of well IDs.
#' @export
#' @examples
#' cr_rowcol_to_well(c(1, 2, 8), c(1, 5, 12))
cr_rowcol_to_well <- function(row, col, pad = 2) {
  if (length(row) != length(col)) {
    cli::cli_abort("`row` and `col` must have the same length.")
  }
  letter <- .cr_row_to_letters(row)
  paste0(letter, formatC(col, width = pad, flag = "0"))
}

.cr_letters_to_row <- function(x) {
  sapply(toupper(x), function(s) {
    if (is.na(s) || !nchar(s)) return(NA_integer_)
    chars <- strsplit(s, "")[[1]]
    nums <- match(chars, LETTERS)
    Reduce(function(a, b) a * 26 + b, nums)
  }, USE.NAMES = FALSE)
}

.cr_row_to_letters <- function(n) {
  vapply(n, function(i) {
    if (is.na(i) || i < 1) return(NA_character_)
    result <- ""
    while (i > 0) {
      r <- (i - 1) %% 26
      result <- paste0(LETTERS[r + 1], result)
      i <- (i - 1) %/% 26
    }
    result
  }, character(1), USE.NAMES = FALSE)
}

#' List channels in a `cr_experiment`
#'
#' @param experiment A `cr_experiment`.
#' @return A character vector of channel names.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' cr_channels(exp)
cr_channels <- function(experiment) {
  cr_validate_experiment(experiment)
  experiment$channels$channel
}

#' Count cells in a `cr_experiment`
#'
#' @param experiment A `cr_experiment`.
#' @param by Optional character vector of grouping columns from the
#'   `design` or `cells` table. If `NULL`, returns total count.
#' @return Either a scalar integer (no grouping) or a tibble with
#'   cell counts per group.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' cr_n_cells(exp)
#' cr_n_cells(exp, by = "treatment")
cr_n_cells <- function(experiment, by = NULL) {
  cr_validate_experiment(experiment)
  if (is.null(by)) return(nrow(experiment$cells))
  spatial <- experiment$spatial_unit
  joined <- dplyr::left_join(experiment$cells, experiment$design,
                             by = spatial)
  joined |>
    dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
    dplyr::summarise(n_cells = dplyr::n(), .groups = "drop")
}

#' Filter cells in a `cr_experiment`
#'
#' A thin wrapper around `dplyr::filter()` applied to the `cells`
#' slot. Filtering is additive: rows excluded here are removed from
#' the returned experiment and logged in `qc_log`.
#'
#' @param experiment A `cr_experiment`.
#' @param ... Filtering expressions passed on to `dplyr::filter()`.
#' @return A modified `cr_experiment`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' cr_filter_cells(exp, area > 50)
cr_filter_cells <- function(experiment, ...) {
  cr_validate_experiment(experiment)
  before <- nrow(experiment$cells)
  experiment$cells <- dplyr::filter(experiment$cells, ...)
  after <- nrow(experiment$cells)
  experiment <- .cr_log_qc(experiment, "cr_filter_cells",
                           paste(deparse(substitute(list(...))),
                                 collapse = " "),
                           before, after)
  experiment
}

#' Merge multiple experiments
#'
#' Combines two or more `cr_experiment` objects that share the same
#' schema (channel panel, spatial unit). Useful for multi-plate
#' studies. Well/slide names must be unique across inputs (prefix
#' them with a plate identifier if necessary).
#'
#' @param ... `cr_experiment` objects.
#' @return A single merged `cr_experiment`.
#' @export
#' @examples
#' e1 <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' e2 <- cr_example_experiment(seed = 2, n_cells_per_well = 10)
#' e2$cells$well <- paste0("p2_", e2$cells$well)
#' e2$design$well <- paste0("p2_", e2$design$well)
#' merged <- cr_merge_experiments(e1, e2)
cr_merge_experiments <- function(...) {
  exps <- list(...)
  if (!length(exps)) cli::cli_abort("Nothing to merge.")
  lapply(exps, cr_validate_experiment)
  spatial <- exps[[1]]$spatial_unit
  if (any(vapply(exps, function(e) e$spatial_unit != spatial, logical(1)))) {
    cli::cli_abort("All experiments must share the same spatial unit.")
  }
  cells <- dplyr::bind_rows(lapply(exps, `[[`, "cells"))
  design <- dplyr::bind_rows(lapply(exps, `[[`, "design"))
  channels <- dplyr::distinct(dplyr::bind_rows(lapply(exps, `[[`, "channels")))
  if (anyDuplicated(design[[spatial]])) {
    cli::cli_abort("Duplicated {.field {spatial}} values across experiments. Make wells/slides unique before merging.")
  }
  cr_build_experiment(
    cells = cells,
    design = design,
    channels = channels,
    plate_info = list(merged_from = length(exps)),
    metadata = list(merged = TRUE)
  )
}

# Internal: append an entry to qc_log
.cr_log_qc <- function(experiment, step, parameters, before, after) {
  entry <- tibble::tibble(
    step = step,
    parameters = parameters,
    cells_before = as.integer(before),
    cells_after = as.integer(after),
    cells_removed = as.integer(before - after),
    percent_removed = if (before > 0) 100 * (before - after) / before else 0,
    timestamp = Sys.time()
  )
  experiment$qc_log <- dplyr::bind_rows(experiment$qc_log, entry)
  experiment
}

# Internal: safe join of cells with design, preserving grouping
.cr_join_design <- function(experiment) {
  dplyr::left_join(experiment$cells, experiment$design,
                   by = experiment$spatial_unit)
}
