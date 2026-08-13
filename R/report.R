#' Assemble a structured analysis report
#'
#' Collects everything a write-up needs into one `cr_report` object:
#' the experiment, the statistical results, the quality-control record,
#' the effect-size grid, the sample-size table, any supplementary
#' tables and any plots. Assembling first and formatting later is what
#' keeps a number in the text tied to the object it came from — tables,
#' generated macros and the rendered document are then all derived from
#' the same assembly rather than transcribed from each other.
#'
#' @param experiment A `cr_experiment`.
#' @param results Optional `cr_result`, list of `cr_result` objects (as
#'   returned by [cr_test_all()]), or a data frame of results.
#' @param qc Optional quality-control record: a data frame, or a list
#'   holding one (for example a gate object with a `units` element). If
#'   `NULL`, the experiment's QC log is used.
#' @param effects Optional data frame of effect sizes — one row per
#'   contrast, typically with estimate and confidence-bound columns.
#' @param sizes Optional data frame of sample-size calculations, one
#'   row per contrast.
#' @param tables Optional named list of supplementary tables (data
#'   frames). A `disposition` table is added automatically when the
#'   list does not already contain one.
#' @param plots Optional named list of ggplot2 objects.
#' @param title Report title.
#' @param author Author name for the report header.
#' @param metadata Optional named list of arbitrary metadata.
#' @param render Whether to render the report to a file. The default
#'   `NULL` renders when `template` or `output_dir` is supplied — that
#'   is, when the caller has said where the document should go — and
#'   otherwise returns the assembled object. Pass `TRUE` or `FALSE` to
#'   be explicit.
#' @param template Path to an R Markdown template. If `NULL`, the
#'   bundled template is used.
#' @param output_dir Output directory for the rendered document.
#' @param format One of `"html"`, `"pdf"` or `"docx"`.
#'
#' @return A `cr_report` object, an S3 list with the slots
#'   \describe{
#'     \item{`experiment`}{The `cr_experiment` the report describes.}
#'     \item{`results`}{Named list of `cr_result` objects.}
#'     \item{`summary`}{One-row-per-contrast overview tibble.}
#'     \item{`qc`}{Quality-control tibble.}
#'     \item{`effects`}{Effect-size tibble, or `NULL`.}
#'     \item{`sizes`}{Sample-size tibble, or `NULL`.}
#'     \item{`tables`}{Named list of supplementary tibbles.}
#'     \item{`plots`}{Named list of ggplot2 objects.}
#'     \item{`metadata`}{User metadata.}
#'     \item{`params`}{Title, author, package version, creation time.}
#'   }
#'   When rendering was requested, the path to the rendered document is
#'   returned invisibly instead, carrying the assembled object in its
#'   `report` attribute.
#' @seealso [cr_render_report()] to render an assembled report,
#'   [cr_tables()] to extract its tables and [cr_macros()] to emit its
#'   numbers.
#' @family reporting
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' rep <- cr_report(exp, title = "Marker 1 overview")
#' rep
#'
#' # supply an effect grid and the sample sizes derived from it
#' eff <- data.frame(
#'   group = c("CompoundA_low", "CompoundA_high"),
#'   estimate = c(0.31, 1.42),
#'   ci_low = c(-0.10, 0.55),
#'   ci_high = c(0.72, 2.29)
#' )
#' rep2 <- cr_report(exp, effects = eff, title = "Marker 1 screen")
#' rep2$summary
cr_report <- function(experiment,
                      results = NULL,
                      qc = NULL,
                      effects = NULL,
                      sizes = NULL,
                      tables = NULL,
                      plots = NULL,
                      title = "cellreportR analysis report",
                      author = "",
                      metadata = list(),
                      render = NULL,
                      template = NULL,
                      output_dir = NULL,
                      format = c("html", "pdf", "docx")) {
  cr_validate_experiment(experiment)
  format <- match.arg(format)
  if (is.null(render)) {
    render <- !is.null(template) || !is.null(output_dir)
  }
  if (!is.logical(render) || length(render) != 1L || is.na(render)) {
    cli::cli_abort("{.arg render} must be {.code TRUE}, {.code FALSE} or {.code NULL}.")
  }

  results <- .cr_as_results(results)
  qc <- if (is.null(qc)) experiment$qc_log else cr_table_qc(qc)
  effects <- .cr_as_table(effects, "effects")
  sizes <- .cr_as_table(sizes, "sizes")
  tables <- .cr_as_named_list(tables, "tables")
  plots <- .cr_as_named_list(plots, "plots")

  if (!"disposition" %in% names(tables)) {
    disp <- tryCatch(cr_table_disposition(experiment), error = function(e) NULL)
    if (!is.null(disp)) tables$disposition <- disp
  }

  params <- list(
    title = title,
    author = author,
    format = format,
    package_version = .cr_pkg_version(),
    created = Sys.time()
  )

  obj <- .cr_new_report(
    experiment = experiment,
    results = results,
    summary = .cr_report_summary(results, effects, sizes),
    plots = plots,
    metadata = as.list(metadata),
    params = params
  )
  # `[` assignment so that an absent effect grid stays a documented
  # slot holding NULL rather than disappearing from the object.
  obj["qc"] <- list(qc)
  obj["effects"] <- list(effects)
  obj["sizes"] <- list(sizes)
  obj["tables"] <- list(tables)

  if (isTRUE(render)) {
    out <- cr_render_report(
      obj,
      output_dir = output_dir %||% tempdir(),
      format = format,
      template = template
    )
    attr(out, "report") <- obj
    return(invisible(out))
  }
  obj
}

#' Render a report to HTML or PDF
#'
#' Renders an assembled report through an R Markdown template. The
#' bundled template covers experimental setup, the QC log, an intensity
#' overview, the comparison summary and a session-info appendix. A
#' custom template receives the report through its `params`; only the
#' parameters a template declares are passed, so templates of different
#' vintages keep working.
#'
#' @param report A `cr_report` from [cr_report()]. A `cr_experiment` is
#'   also accepted and is assembled into a report first.
#' @param output_dir Output directory (default `tempdir()`).
#' @param format One of `"html"`, `"pdf"` or `"docx"`.
#' @param template Path to an R Markdown template. If `NULL`, the
#'   bundled template is used.
#' @param title,author Override the report title and author. `NULL`
#'   keeps the values stored in the report.
#' @param quiet Passed to `rmarkdown::render()`.
#' @return Path to the rendered document (invisibly).
#' @seealso [cr_report()].
#' @family reporting
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' rep <- cr_report(exp)
#' if (requireNamespace("rmarkdown", quietly = TRUE) &&
#'     requireNamespace("knitr", quietly = TRUE) &&
#'     rmarkdown::pandoc_available()) {
#'   out <- cr_render_report(rep, output_dir = tempdir())
#'   basename(out)
#' }
#' }
cr_render_report <- function(report,
                             output_dir = tempdir(),
                             format = c("html", "pdf", "docx"),
                             template = NULL,
                             title = NULL,
                             author = NULL,
                             quiet = TRUE) {
  format <- match.arg(format)
  if (inherits(report, "cr_experiment")) {
    report <- cr_report(report, render = FALSE)
  }
  if (!inherits(report, "cr_report")) {
    cli::cli_abort(c(
      "{.arg report} must be a {.cls cr_report}.",
      "x" = "Got {.cls {class(report)[[1L]]}}.",
      "i" = "Assemble one with {.fn cr_report}."
    ))
  }
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

  params <- list(
    experiment = report$experiment,
    results = report$results,
    report = report,
    title = title %||% report$params$title %||% "cellreportR analysis report",
    author = author %||% report$params$author %||% ""
  )
  params <- params[intersect(names(params), .cr_declared_params(work_rmd))]

  out_file <- rmarkdown::render(
    input = work_rmd,
    output_format = switch(format,
                           html = "html_document",
                           pdf = "pdf_document",
                           docx = "word_document"),
    output_dir = output_dir,
    params = params,
    envir = new.env(parent = globalenv()),
    quiet = quiet
  )
  invisible(out_file)
}

# Internal helpers ----------------------------------------------------------

# Normalize the `results` argument to a (possibly empty) named list of
# cr_result objects, preserving the summary attribute of cr_test_all().
.cr_as_results <- function(results) {
  if (is.null(results)) return(list())
  if (inherits(results, "cr_result")) {
    out <- list(results)
    names(out) <- results$comparison$treatment %||% "result"
    return(out)
  }
  if (is.data.frame(results)) return(results)
  if (is.list(results)) return(results)
  cli::cli_abort(c(
    "{.arg results} must be a {.cls cr_result}, a list of them, or a data frame.",
    "x" = "Got {.cls {class(results)[[1L]]}}."
  ))
}

# Coerce a table-ish argument to a tibble, or NULL.
.cr_as_table <- function(x, arg) {
  if (is.null(x)) return(NULL)
  if (is.data.frame(x)) return(tibble::as_tibble(x))
  if (is.list(x)) {
    dfs <- Filter(is.data.frame, x)
    if (length(dfs) == 1L) return(tibble::as_tibble(dfs[[1L]]))
    if (length(dfs) > 1L) return(dplyr::bind_rows(dfs, .id = "component"))
  }
  cli::cli_abort(c(
    "{.arg {arg}} must be a data frame or a list holding one.",
    "x" = "Got {.cls {class(x)[[1L]]}}."
  ))
}

# Coerce to a named list, naming unnamed elements positionally.
.cr_as_named_list <- function(x, arg) {
  if (is.null(x)) return(list())
  if (!is.list(x) || is.data.frame(x)) {
    cli::cli_abort(c(
      "{.arg {arg}} must be a named list.",
      "x" = "Got {.cls {class(x)[[1L]]}}."
    ))
  }
  nms <- names(x)
  if (is.null(nms)) nms <- rep("", length(x))
  blank <- !nzchar(nms) | is.na(nms)
  nms[blank] <- paste0(arg, "_", seq_along(nms))[blank]
  names(x) <- make.unique(nms)
  x
}

# Build the headline one-row-per-contrast overview.
.cr_report_summary <- function(results, effects = NULL, sizes = NULL) {
  base <- NULL
  if (!is.null(effects) && nrow(effects)) {
    base <- tibble::as_tibble(effects)
  } else if (is.data.frame(results) && nrow(results)) {
    base <- tibble::as_tibble(results)
  } else if (length(results)) {
    s <- attr(results, "summary")
    base <- if (!is.null(s)) tibble::as_tibble(s) else .cr_results_summary(results)
  }
  if (is.null(base) || !nrow(base)) return(tibble::tibble())
  if (!is.null(sizes) && nrow(sizes)) {
    keys <- intersect(names(base), names(sizes))
    keys <- keys[vapply(keys, function(k) {
      is.character(base[[k]]) || is.factor(base[[k]])
    }, logical(1))]
    if (length(keys)) {
      base <- dplyr::left_join(base, sizes, by = keys, suffix = c("", "_size"))
    } else if (nrow(sizes) == nrow(base)) {
      extra <- setdiff(names(sizes), names(base))
      base <- dplyr::bind_cols(base, sizes[, extra, drop = FALSE])
    }
  }
  base
}

# Summarize a list of cr_result objects when no summary attribute exists.
.cr_results_summary <- function(results) {
  rows <- lapply(results, function(res) {
    if (!inherits(res, "cr_result")) return(NULL)
    cmp <- res$comparison
    lvl <- if (nrow(res$rep_level)) res$rep_level else res$cell_level
    d_row <- res$effect_sizes[res$effect_sizes$method == "cohens_d", , drop = FALSE]
    tibble::tibble(
      channel = cmp$channel %||% NA_character_,
      treatment = cmp$treatment %||% NA_character_,
      control = cmp$control %||% NA_character_,
      test = cmp$test %||% NA_character_,
      p_value = if (!is.null(lvl) && nrow(lvl)) lvl$p_value[1] else NA_real_,
      cohens_d = if (nrow(d_row)) d_row$estimate[1] else NA_real_
    )
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) return(tibble::tibble())
  dplyr::bind_rows(rows)
}

# Stack one slot across a list of cr_result objects.
.cr_bind_slot <- function(results, slot) {
  parts <- lapply(results, function(res) {
    if (!inherits(res, "cr_result")) return(NULL)
    tb <- res[[slot]]
    if (!is.data.frame(tb) || !nrow(tb)) return(NULL)
    tb$comparison <- res$comparison$treatment %||% NA_character_
    tb
  })
  parts <- Filter(Negate(is.null), parts)
  if (!length(parts)) return(NULL)
  dplyr::bind_rows(parts)
}

# Parameters an R Markdown template declares, with a conservative
# fallback for templates knitr cannot parse.
.cr_declared_params <- function(rmd) {
  out <- tryCatch(
    names(knitr::knit_params(readLines(rmd, warn = FALSE))),
    error = function(e) NULL
  )
  if (is.null(out) || !length(out)) {
    return(c("experiment", "results", "title", "author"))
  }
  out
}

# Package version without failing when the package is not installed.
.cr_pkg_version <- function() {
  tryCatch(as.character(utils::packageVersion("cellreportR")),
           error = function(e) "unknown")
}

# Version 0.1.0
