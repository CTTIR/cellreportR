# Read-only review of an already-bound report.
.cr_review_plain <- function(x) {
  supported_classes <- c(
    "cr_lab_report", "cr_report_evidence", "cr_report_spec", "cr_report_qc",
    "cr_report_style", "cr_report_profile", "list", "data.frame", "tbl_df", "tbl", "Date", "POSIXct",
    "POSIXlt", "POSIXt", "factor", "ordered"
  )
  classes <- attr(x, "class", exact = TRUE)
  if (!is.null(classes) && !all(classes %in% supported_classes)) {
    return(FALSE)
  }
  if (is.environment(x) || is.function(x) || isS4(x) || inherits(x, "connection") ||
    typeof(x) %in% c("externalptr", "weakref", "language", "symbol", "pairlist")) {
    return(FALSE)
  }
  if (is.list(x) && !all(vapply(unclass(x), .cr_review_plain, logical(1)))) {
    return(FALSE)
  }
  a <- attributes(x)
  is.null(a) || all(vapply(a, .cr_review_plain, logical(1)))
}
.cr_review_hash <- function(x) digest::digest(serialize(x, NULL, version = 3), algo = "sha256", serialize = FALSE)
.cr_review_capture <- function(report, root = NULL) {
  stopifnot(inherits(report, "cr_lab_report"), inherits(report$evidence, "cr_report_evidence"))
  if (!is.null(report$experiment) || !is.null(report$result_graphic)) stop("This reviewer accepts no experiment or live plot payload.", call. = FALSE)
  for (logo in list(report$style$logo, report$spec$laboratory$logo)) if (!is.null(logo) && length(logo) && any(nzchar(logo))) stop("This reviewer accepts no external logos.", call. = FALSE)
  if (!.cr_review_plain(report)) stop("Unsupported mutable or classed report payload.", call. = FALSE)
  if (is.null(root)) root <- report$evidence_root
  if (!is.character(root) || length(root) != 1L || is.na(root) || !nzchar(root)) stop("A source root is required.", call. = FALSE)
  report$evidence_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  report <- unserialize(serialize(report, NULL, version = 3))
  ctx <- list(report = report, hash = .cr_review_hash(report))
  .cr_review_validate(ctx)
  for (id in names(report$evidence$figures)) .cr_review_figure(ctx, id)
  ctx
}
.cr_review_validate <- function(ctx) {
  stopifnot(identical(.cr_review_hash(ctx$report), ctx$hash), inherits(ctx$report$evidence, "cr_report_evidence"))
  cr_validate_report_spec(ctx$report$spec, strict = TRUE)
  cr_validate_report_qc(ctx$report$qc)
  .cr_validate_bound_evidence(ctx$report)
  invisible(TRUE)
}
.cr_review_figure <- function(ctx, id) {
  if (!is.character(id) || length(id) != 1L || is.na(id) || !id %in% names(ctx$report$evidence$figures)) stop("Unknown declared figure.", call. = FALSE)
  f <- ctx$report$evidence$figures[[id]]
  path <- .cr_evidence_path(ctx$report$evidence_root, f$path)
  ext <- tolower(tools::file_ext(f$path))
  bytes <- readBin(path, "raw", n = 8L)
  png <- identical(bytes, as.raw(c(137, 80, 78, 71, 13, 10, 26, 10)))
  pdf <- length(bytes) >= 5L && identical(bytes[1:5], charToRaw("%PDF-"))
  if (!((ext == "png" && png) || (ext == "pdf" && pdf))) stop("Declared figure must have matching PNG or PDF signature and extension.", call. = FALSE)
  list(path = path, extension = ext, mime = if (ext == "png") "image/png" else "application/pdf", sha256 = f$sha256)
}
.cr_review_preview <- function(ctx) {
  .cr_review_validate(ctx)
  r <- ctx$report
  e <- r$evidence
  rows <- lapply(names(e$claims), function(id) {
    x <- e$claims[[id]]
    data.frame(claim = id, display = x$display, raw = x$value, table = x$table, key = paste(names(x$key), unlist(x$key), sep = "=", collapse = "; "), column = x$column, source_sha256 = x$table_sha256, stringsAsFactors = FALSE)
  })
  claims <- if (length(rows)) do.call(rbind, rows) else data.frame(claim = character(), display = character(), raw = character(), table = character(), key = character(), column = character(), source_sha256 = character())
  out <- list(
    title = r$spec$report$title, status = r$spec$report$status, limitations = r$spec$limitations,
    display = cr_report_display_data(r), claims = claims, tables = e$tables, figures = e$figures,
    evidence_sha256 = e$sha256, report_data_hash = cr_report_hash(r), snapshot_hash = ctx$hash, checked_at = format(Sys.time(), tz = "UTC", usetz = TRUE)
  )
  .cr_review_validate(ctx)
  out
}
.cr_review_render <- function(report, format, path) {
  if (format %in% c("html", "pdf")) {
    cr_render_lab_report(report, path)
  } else if (format == "audit") {
    cr_export_report_audit(report, path)
  } else if (format == "spec") {
    cr_export_report_spec(report$spec, path)
  } else {
    stop("Unsupported export.", call. = FALSE)
  }
}
.cr_review_stage <- function(ctx, format, destination, figure_id = NULL) {
  stage <- NULL
  success <- FALSE
  on.exit(
    {
      if (!is.null(stage)) unlink(stage, recursive = TRUE)
      if (!success && file.exists(destination)) unlink(destination)
    },
    add = TRUE
  )
  tryCatch(
    {
      .cr_review_validate(ctx)
      stage <- tempfile("cr_review_")
      dir.create(stage)
      if (format == "figure") {
        f <- .cr_review_figure(ctx, figure_id)
        file <- file.path(stage, paste0("figure.", f$extension))
        stopifnot(file.copy(f$path, file), identical(digest::digest(file = file, algo = "sha256"), f$sha256))
      } else {
        stopifnot(format %in% c("html", "pdf", "audit", "spec"))
        ext <- if (format %in% c("audit", "spec")) "json" else format
        file <- file.path(stage, paste0("report.", ext))
        .cr_review_render(unserialize(serialize(ctx$report, NULL, version = 3)), format, file)
      }
      .cr_review_validate(ctx)
      stopifnot(file.exists(file))
      expected <- digest::digest(file = file, algo = "sha256")
      stopifnot(file.copy(file, destination, overwrite = TRUE))
      .cr_review_validate(ctx)
      stopifnot(identical(digest::digest(file = destination, algo = "sha256"), expected))
      success <- TRUE
      invisible(destination)
    },
    error = function(e) stop("Report validation or export failed; no download was released.", call. = FALSE)
  )
}
.cr_review_ui <- function(ctx) {
  shiny::fluidPage(
    shiny::tags$head(shiny::tags$style("body{overflow-wrap:anywhere}.cr-claim{border:1px solid #ccc;border-radius:6px;padding:14px;margin:12px 0}.cr-claim h4{margin:0 0 8px}.cr-claim-value{font-size:18px;line-height:1.5}.cr-claim dt{margin-top:8px}.cr-claim dd{margin-left:0}.cr-claim summary{cursor:pointer;padding:8px 0}")),
    shiny::h2("Bound report review"), shiny::p("Read-only. Source identity does not establish scientific validity."),
    shiny::actionButton("refresh", "Revalidate and refresh"), shiny::uiOutput("preview"),
    shiny::h3("Source-bound claims"), shiny::uiOutput("claims"), shiny::h3("Source metadata"), shiny::uiOutput("sources"),
    shiny::h3("Declared figures"), shiny::uiOutput("figures"),
    shiny::downloadButton("report_html", "Report HTML"), shiny::downloadButton("report_pdf", "Report PDF"),
    shiny::downloadButton("report_audit", "Audit JSON"), shiny::downloadButton("report_spec", "Specification JSON")
  )
}
.cr_review_server <- function(input, output, session, context) {
  view <- shiny::reactive({
    input$refresh
    tryCatch(.cr_review_preview(context), error = function(e) NULL)
  })
  output$preview <- shiny::renderUI({
    x <- view()
    if (is.null(x)) {
      return(shiny::div(role = "alert", "Source validation failed. Preview unavailable."))
    }
    shiny::tagList(
      shiny::h3(x$title), shiny::p("Status: ", x$status),
      .cr_report_preview_ui(x$display, show_pagination = FALSE), shiny::h4("Limitations"), shiny::tags$ul(lapply(x$limitations, shiny::tags$li)),
      shiny::p("Evidence SHA-256: ", x$evidence_sha256), shiny::p("Captured state SHA-256: ", x$snapshot_hash), shiny::p("Last validation: ", x$checked_at)
    )
  })
  output$claims <- shiny::renderUI({
    x <- view()
    if (is.null(x)) {
      return(NULL)
    }
    if (!nrow(x$claims)) {
      return(shiny::p("No source-bound claims are declared."))
    }
    shiny::tagList(lapply(seq_len(nrow(x$claims)), function(i) {
      z <- x$claims[i, ]
      shiny::tags$article(
        class = "cr-claim", shiny::h4(z$claim), shiny::div(class = "cr-claim-value", z$display),
        shiny::tags$details(shiny::tags$summary("Source and raw value details"), shiny::tags$dl(
          shiny::tags$dt("Raw value"), shiny::tags$dd(z$raw), shiny::tags$dt("Table"), shiny::tags$dd(z$table),
          shiny::tags$dt("Key"), shiny::tags$dd(z$key), shiny::tags$dt("Column"), shiny::tags$dd(z$column),
          shiny::tags$dt("Source SHA-256"), shiny::tags$dd(z$source_sha256)
        ))
      )
    }))
  })
  output$sources <- shiny::renderUI({
    x <- view()
    if (is.null(x)) {
      return(NULL)
    }
    if (!length(x$tables)) {
      return(shiny::p("No source tables are declared."))
    }
    shiny::tags$ul(lapply(names(x$tables), function(id) {
      z <- x$tables[[id]]
      shiny::tags$li(id, ": ", z$path, "; rows ", z$rows, "; keys ", paste(z$key, collapse = ", "), "; SHA-256 ", z$sha256)
    }))
  })
  ids <- names(context$report$evidence$figures)
  output$figures <- shiny::renderUI({
    x <- view()
    if (is.null(x)) {
      return(NULL)
    }
    if (!length(ids)) {
      return(shiny::p("No declared figures."))
    }
    shiny::tags$ul(lapply(seq_along(ids), function(i) {
      z <- x$figures[[ids[i]]]
      shiny::tags$li(ids[i], ": ", z$path, "; declared tables ", paste(z$tables, collapse = ", "), "; SHA-256 ", z$sha256, shiny::downloadButton(paste0("figure_", i), "Download declared figure"))
    }))
  })
  for (format in c("html", "pdf", "audit", "spec")) {
    local({
      f <- format
      output[[paste0("report_", f)]] <- shiny::downloadHandler(
        filename = function() paste0("report-", f, ".", if (f %in% c("audit", "spec")) "json" else f),
        content = function(file) .cr_review_stage(context, f, file), contentType = if (f == "html") "text/html" else if (f == "pdf") "application/pdf" else "application/json"
      )
    })
  }
  for (i in seq_along(ids)) {
    local({
      id <- ids[i]
      key <- paste0("figure_", i)
      ext <- tolower(tools::file_ext(context$report$evidence$figures[[id]]$path))
      meta <- list(extension = ext, mime = if (ext == "png") "image/png" else "application/pdf")
      output[[key]] <- shiny::downloadHandler(filename = function() paste0(key, ".", meta$extension), content = function(file) .cr_review_stage(context, "figure", file, id), contentType = meta$mime)
    })
  }
  invisible(list(snapshot_hash = context$hash))
}
#' Review an immutable source-bound report in a Shiny application
#'
#' Creates an application object without starting a listener. The report is
#' detached from the caller by serialization; previews and downloads validate
#' its captured state and bound source files before and after each operation.
#' Claim values, source metadata, limitations and report status are visible.
#' Source details expand using keyboard-accessible disclosures on narrow screens.
#'
#' @param report An already-bound `cr_lab_report` with `cr_report_evidence`.
#'   Experiment payloads, live result graphics, external logos and mutable
#'   objects such as environments, functions or connections are not supported.
#'   Trusted HTML, tags and other unsupported S3 classes are rejected, including
#'   in attributes. Supported classes are the package's report, evidence, spec,
#'   QC, style and profile classes, lists, data frames and tibbles, Date, POSIXt
#'   and factors.
#'   Unclassed atomic vectors and lists are also supported.
#' @param root Optional existing source root for identical relocated evidence.
#'   Defaults to the report's bound evidence root.
#' @return A `shiny.appobj`, suitable for `shiny::runApp()`.
#' @details
#' The optional package `bslib` is required. HTML/PDF downloads additionally
#' require the render dependencies of [cr_render_lab_report()], including
#' `rmarkdown`, Pandoc and a suitable LaTeX installation for PDF.
#'
#' Only declared PNG/PDF figures are downloadable. Filename extensions and
#' byte signatures must agree; this is not full decoding or content sanitization.
#' Source tables are shown as metadata and are never registered as a static
#' directory. Staged downloads are removed after failure or completion.
#'
#' This application is not a sandbox, authentication service or authorization
#' system. Source identity does not establish scientific validity or release
#' authorization. Pre/post checks do not provide filesystem snapshot isolation.
#' The function starts no server and changes no global listener configuration.
#' For local review, explicitly use `shiny::runApp(app, host = "127.0.0.1")`.
#' Claims and figures may be empty; bound evidence requires source tables.
#' @seealso [cr_report_evidence()], [cr_lab_report_from_evidence()]
#' @examples
#' if (interactive() && requireNamespace("bslib", quietly = TRUE)) {
#'   root <- tempfile("report-sources-")
#'   dir.create(root)
#'   writeLines(c("group,value", "treated,1.25"), file.path(root, "results.csv"))
#'   evidence <- cr_report_evidence(root,
#'     tables = list(results = list(
#'       path = "results.csv", format = "csv",
#'       key = "group"
#'     )),
#'     claims = list(estimate = list(
#'       table = "results",
#'       key = c(group = "treated"), column = "value"
#'     ))
#'   )
#'   spec <- cr_report_spec(
#'     report = list(report_id = "example"),
#'     result = list(display_value = "Source-bound example")
#'   )
#'   report <- cr_lab_report_from_evidence(evidence, root, spec)
#'   app <- cr_report_review_app(report)
#'   # shiny::runApp(app, host = "127.0.0.1")
#' }
#' @md
#' @export
cr_report_review_app <- function(report, root = NULL) {
  if (!requireNamespace("shiny", quietly = TRUE) || !requireNamespace("bslib", quietly = TRUE)) stop("shiny and bslib are required.", call. = FALSE)
  context <- .cr_review_capture(report, root)
  shiny::shinyApp(.cr_review_ui(context), function(input, output, session) .cr_review_server(input, output, session, context))
}
