#' Export results to CSV, Excel or RDS
#'
#' Writes a single flat table of results. Anything the reporting layer
#' produces is accepted: a `cr_report`, a `cr_result`, the list
#' returned by [cr_test_all()], a named list of tables, or a plain data
#' frame.
#'
#' @param results A `cr_report`, a `cr_result`, a list of `cr_result`
#'   objects, a named list of data frames, or a data frame.
#' @param path Output file path. The extension determines the format
#'   unless `format` is given.
#' @param format One of `"csv"`, `"xlsx"`, `"rds"`. `NULL` (default)
#'   infers it from the extension of `path`, falling back to `"csv"`.
#' @return The output path (invisibly).
#' @seealso [cr_export_tables()] to write several tables at once and
#'   [cr_macros()] to emit individual numbers.
#' @family reporting
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' rep <- cr_report(exp)
#' f <- tempfile(fileext = ".csv")
#' cr_export_results(rep$tables$disposition, f)
#' utils::read.csv(f)
cr_export_results <- function(results, path, format = NULL) {
  .cr_check_path(path)
  if (is.null(format)) {
    format <- tolower(.cr_file_ext(path))
    if (!nzchar(format)) format <- "csv"
  }
  format <- tolower(as.character(format)[[1L]])

  if (identical(format, "rds")) {
    saveRDS(results, path)
    return(invisible(path))
  }
  if (identical(format, "xlsx") && .cr_is_table_list(results)) {
    return(invisible(cr_export_tables(results, path, format = "xlsx",
                                      one_file = TRUE)[[1L]]))
  }

  tbl <- .cr_result_to_tibble(results)
  switch(
    format,
    csv = readr::write_csv(tbl, path),
    tsv = readr::write_tsv(tbl, path),
    xlsx = {
      if (!requireNamespace("writexl", quietly = TRUE)) {
        cli::cli_abort("Exporting Excel files requires {.pkg writexl}.")
      }
      writexl::write_xlsx(tbl, path)
    },
    cli::cli_abort(c(
      "Unsupported format {.val {format}}.",
      "i" = "Use {.val csv}, {.val tsv}, {.val xlsx} or {.val rds}."
    ))
  )
  invisible(path)
}

#' Export a set of tables to CSV or Excel
#'
#' Writes the named list produced by [cr_tables()]. Excel output can go
#' into one workbook with a sheet per table; CSV always writes one file
#' per table into a directory, because a CSV file holds exactly one
#' table.
#'
#' @param tables A named list of data frames, or a single data frame.
#' @param path Destination. For a single Excel workbook this is the
#'   file path; otherwise it is a directory, which is created when
#'   needed.
#' @param format `"csv"` (default) or `"xlsx"`.
#' @param one_file Whether to write one Excel workbook with a sheet per
#'   table. Ignored for CSV.
#' @return A character vector of written paths (invisibly).
#' @seealso [cr_tables()], [cr_export_results()].
#' @family reporting
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' tabs <- cr_tables(exp)
#' out <- tempfile("tables_")
#' paths <- cr_export_tables(tabs, out)
#' basename(paths)
cr_export_tables <- function(tables, path,
                             format = c("csv", "xlsx"),
                             one_file = TRUE) {
  format <- match.arg(format)
  .cr_check_path(path)
  if (is.data.frame(tables)) tables <- list(table = tables)
  if (!is.list(tables) || !length(tables)) {
    cli::cli_abort("{.arg tables} must be a non-empty named list of data frames.")
  }
  tables <- .cr_as_named_list(tables, "tables")
  not_tbl <- !vapply(tables, is.data.frame, logical(1))
  if (any(not_tbl)) {
    cli::cli_abort(c(
      "Every element of {.arg tables} must be a data frame.",
      "x" = "Not a data frame: {.val {names(tables)[not_tbl]}}."
    ))
  }

  if (identical(format, "xlsx")) {
    if (!requireNamespace("writexl", quietly = TRUE)) {
      cli::cli_abort("Exporting Excel files requires {.pkg writexl}.")
    }
    if (isTRUE(one_file)) {
      file <- if (nzchar(.cr_file_ext(path))) path else paste0(path, ".xlsx")
      .cr_ensure_dir(dirname(file))
      sheets <- tables
      names(sheets) <- make.unique(substr(.cr_slug(names(tables)), 1L, 31L))
      writexl::write_xlsx(sheets, file)
      return(invisible(file))
    }
    .cr_ensure_dir(path)
    files <- file.path(path, paste0(.cr_slug(names(tables)), ".xlsx"))
    for (i in seq_along(tables)) writexl::write_xlsx(tables[[i]], files[i])
    return(invisible(files))
  }

  .cr_ensure_dir(path)
  files <- file.path(path, paste0(.cr_slug(names(tables)), ".csv"))
  for (i in seq_along(tables)) readr::write_csv(tables[[i]], files[i])
  invisible(files)
}

#' Export plots to PNG, PDF or SVG in batch
#'
#' @param plots A named list of ggplot2 objects. Unnamed elements are
#'   numbered.
#' @param path Output directory, created when needed.
#' @param format `"png"`, `"pdf"` or `"svg"`.
#' @param width,height Figure dimensions in inches.
#' @param dpi Resolution for raster outputs.
#' @param ... Further arguments passed to `ggplot2::ggsave()`.
#' @return A character vector of written file paths (invisibly).
#' @seealso [cr_export_tables()].
#' @family reporting
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' p1 <- cr_plot_intensity(exp, "marker_1")
#' out <- tempfile("plots_")
#' cr_export_plots(list(intensity = p1), out, width = 4, height = 3)
cr_export_plots <- function(plots, path,
                            format = c("png", "pdf", "svg"),
                            width = 6, height = 4, dpi = 300, ...) {
  format <- match.arg(format)
  .cr_check_path(path)
  if (inherits(plots, "ggplot")) plots <- list(plot = plots)
  if (!is.list(plots) || !length(plots)) {
    cli::cli_abort("{.arg plots} must be a non-empty list of {.pkg ggplot2} objects.")
  }
  plots <- .cr_as_named_list(plots, "plot")
  .cr_ensure_dir(path)

  paths <- file.path(path, paste0(.cr_slug(names(plots)), ".", format))
  for (i in seq_along(plots)) {
    ggplot2::ggsave(paths[i], plot = plots[[i]], width = width,
                    height = height, dpi = dpi, ...)
  }
  invisible(paths)
}

# Internal helpers ----------------------------------------------------------

# Flatten whatever the analysis layer returned into one tibble.
.cr_result_to_tibble <- function(results) {
  if (is.data.frame(results)) return(tibble::as_tibble(results))
  if (inherits(results, "cr_report")) {
    if (nrow(results$summary)) return(tibble::as_tibble(results$summary))
    return(.cr_result_to_tibble(results$results))
  }
  if (inherits(results, "cr_result")) {
    lvl <- if (nrow(results$rep_level)) results$rep_level else results$cell_level
    return(dplyr::bind_cols(
      tibble::as_tibble(as.list(results$comparison)),
      lvl,
      .name_repair = "unique_quiet"
    ))
  }
  if (is.list(results)) {
    s <- attr(results, "summary")
    if (!is.null(s)) return(tibble::as_tibble(s))
    parts <- lapply(results, .cr_result_to_tibble)
    return(dplyr::bind_rows(parts))
  }
  cli::cli_abort(c(
    "Unsupported type in {.fn cr_export_results}.",
    "x" = "Got {.cls {class(results)[[1L]]}}."
  ))
}

# TRUE for a list of several data frames, which is written as a workbook.
.cr_is_table_list <- function(x) {
  is.list(x) && !is.data.frame(x) && length(x) > 1L &&
    all(vapply(x, is.data.frame, logical(1)))
}

# File extension without depending on the tools package.
.cr_file_ext <- function(path) {
  base <- basename(as.character(path)[[1L]])
  pos <- regexpr("\\.([[:alnum:]]+)$", base)
  if (pos < 0L) "" else substring(base, pos + 1L)
}

.cr_check_path <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    cli::cli_abort("{.arg path} must be a single non-empty file path.")
  }
  invisible(TRUE)
}

.cr_ensure_dir <- function(path) {
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
  invisible(path)
}

# Make a name safe to use as a file or sheet name.
.cr_slug <- function(x) {
  x <- gsub("[^A-Za-z0-9._-]+", "_", as.character(x))
  x <- gsub("^_+|_+$", "", x)
  x[!nzchar(x)] <- "table"
  make.unique(x, sep = "_")
}

# Version 0.1.0
