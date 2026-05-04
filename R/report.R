#' Generate a structured analysis report
#'
#' Renders an R Markdown report template bundled with the package.
#' The report includes experimental setup, QC log, normalization
#' notes, a comparison summary, per-comparison detail plots, optional
#' dose-response fits, and a session info appendix.
#'
#' @param experiment A `cr_experiment`.
#' @param results List of `cr_result` objects produced by
#'   [cr_test()], [cr_test_all()] or [cr_logistic()].
#' @param template Path to an R Markdown template. If `NULL`, the
#'   bundled template is used.
#' @param output_dir Output directory (default `tempdir()`).
#' @param format One of `"html"` or `"pdf"`.
#' @param title Report title.
#' @param author Author name for the report header.
#' @return Path to the rendered report (invisibly).
#' @export
#' @examples
#' \dontrun{
#' # Requires a working pandoc installation.
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
#' out <- cr_report(exp, res)
#' out
#' }
cr_report <- function(experiment,
                      results,
                      template = NULL,
                      output_dir = tempdir(),
                      format = c("html", "pdf"),
                      title = "cellreportR analysis report",
                      author = "") {
  cr_validate_experiment(experiment)
  format <- match.arg(format)
  if (!requireNamespace("rmarkdown", quietly = TRUE) ||
      !requireNamespace("knitr", quietly = TRUE)) {
    cli::cli_abort("Generating reports requires {.pkg rmarkdown} and {.pkg knitr}.")
  }
  if (is.null(template)) {
    template <- system.file("rmd", "cellreportR_report.Rmd",
                            package = "cellreportR")
    if (!nzchar(template)) {
      cli::cli_abort("Bundled report template not found. Install the package first.")
    }
  }
  if (!file.exists(template)) {
    cli::cli_abort("Template not found: {.path {template}}")
  }
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  # Work on a copy so the template directory is not polluted.
  work_rmd <- file.path(output_dir, "cellreportR_report.Rmd")
  file.copy(template, work_rmd, overwrite = TRUE)

  out_format <- switch(format,
                       html = "html_document",
                       pdf = "pdf_document")

  params <- list(
    experiment = experiment,
    results = results,
    title = title,
    author = author
  )
  out_file <- rmarkdown::render(
    input = work_rmd,
    output_format = out_format,
    output_dir = output_dir,
    params = params,
    envir = new.env(parent = globalenv()),
    quiet = TRUE
  )
  invisible(out_file)
}

#' Export results to CSV, Excel or RDS
#'
#' @param results Either a single `cr_result`, a list of `cr_result`s
#'   (with optional summary attribute), or a tibble.
#' @param path Output file path. Extension determines the format
#'   unless `format` is given.
#' @param format One of `"csv"`, `"xlsx"`, `"rds"`.
#' @return The output path (invisibly).
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' all_res <- cr_test_all(exp, "marker_1", "Untreated",
#'                        level = "replicate")
#' f <- tempfile(fileext = ".csv")
#' cr_export_results(all_res, f)
#' }
cr_export_results <- function(results, path,
                              format = NULL) {
  if (is.null(format)) {
    format <- tolower(tools::file_ext(path))
    if (!nzchar(format)) format <- "csv"
  }
  tbl <- .cr_result_to_tibble(results)
  switch(
    format,
    csv = readr::write_csv(tbl, path),
    xlsx = {
      if (!requireNamespace("writexl", quietly = TRUE)) {
        cli::cli_abort("Exporting Excel files requires {.pkg writexl}.")
      }
      writexl::write_xlsx(tbl, path)
    },
    rds = saveRDS(results, path),
    cli::cli_abort("Unsupported format {.val {format}}.")
  )
  invisible(path)
}

.cr_result_to_tibble <- function(results) {
  if (is.data.frame(results)) return(tibble::as_tibble(results))
  if (inherits(results, "cr_result")) {
    lvl <- if (nrow(results$rep_level)) results$rep_level else results$cell_level
    return(dplyr::bind_cols(
      tibble::as_tibble(as.list(results$comparison)),
      lvl
    ))
  }
  if (is.list(results)) {
    s <- attr(results, "summary")
    if (!is.null(s)) return(tibble::as_tibble(s))
    parts <- lapply(results, .cr_result_to_tibble)
    return(dplyr::bind_rows(parts))
  }
  cli::cli_abort("Unsupported type in {.fn cr_export_results}.")
}

#' Export plots to PNG, PDF or SVG in batch
#'
#' @param plots A named list of ggplot2 objects.
#' @param path Output directory.
#' @param format `"png"`, `"pdf"` or `"svg"`.
#' @param width,height Figure dimensions in inches.
#' @param dpi Resolution for raster outputs.
#' @return Character vector of written file paths (invisibly).
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' p1 <- cr_plot_intensity(exp, "marker_1")
#' out <- tempfile("plots_"); dir.create(out)
#' cr_export_plots(list(intensity = p1), out)
cr_export_plots <- function(plots, path,
                            format = c("png", "pdf", "svg"),
                            width = 6, height = 4, dpi = 300) {
  format <- match.arg(format)
  if (!dir.exists(path)) dir.create(path, recursive = TRUE)
  if (!length(names(plots))) {
    names(plots) <- paste0("plot_", seq_along(plots))
  }
  paths <- character(length(plots))
  for (i in seq_along(plots)) {
    nm <- names(plots)[i]
    file <- file.path(path, paste0(nm, ".", format))
    ggplot2::ggsave(file, plot = plots[[i]], width = width,
                    height = height, dpi = dpi)
    paths[i] <- file
  }
  invisible(paths)
}
