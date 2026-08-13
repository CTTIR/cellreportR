# Laboratory-report presentation settings and reusable profiles.

#' Configure the appearance of laboratory reports
#'
#' Creates a presentation-only object shared by programmatic rendering and the
#' Shiny report workflow. It does not alter report values or analytical data.
#'
#' @param paper Paper size. Version 2 currently supports `"A4"`.
#' @param mode `"colour"` or intentionally monochrome `"grayscale"`.
#' @param density `"standard"` or `"compact"`.
#' @param locale Display-label locale, currently `"en"` or `"de"`.
#' @param logo Optional local PNG, JPEG, or PDF logo path.
#' @param primary_colour,secondary_colour Six-digit hex colours. In grayscale
#'   mode neutral values are used regardless of these settings.
#' @param date_format,date_time_format Optional `format()` patterns. Defaults
#'   are human-readable and locale-specific.
#' @param labels Named display-label overrides.
#' @param footer_text Optional laboratory-controlled document-footer statement.
#' @param include_audit_appendix Include the technical appendix by default.
#' @param show_signature_lines Add printable reviewer/authorizer lines.
#' @param draft_watermark Add a light watermark only when status is `DRAFT`.
#' @return A `cr_report_style` object.
#' @family laboratory reporting
#' @export
cr_report_style <- function(
    paper = "A4", mode = c("colour", "grayscale"),
    density = c("standard", "compact"), locale = c("en", "de"),
    logo = NULL, primary_colour = "#315A70",
    secondary_colour = "#65747C", date_format = NULL,
    date_time_format = NULL, labels = character(), footer_text = NULL,
    include_audit_appendix = FALSE, show_signature_lines = FALSE,
    draft_watermark = FALSE) {
  mode <- match.arg(mode)
  density <- match.arg(density)
  locale <- match.arg(locale)
  if (!identical(toupper(paper), "A4")) {
    cli::cli_abort("Version 2 laboratory reports currently support {.val A4} paper.")
  }
  .cr_check_report_colour(primary_colour, "primary_colour")
  .cr_check_report_colour(secondary_colour, "secondary_colour")
  if (!is.null(logo)) .cr_validate_report_logo(logo)
  if (!is.character(labels) || (length(labels) && is.null(names(labels)))) {
    cli::cli_abort("{.arg labels} must be a named character vector.")
  }
  flags <- list(include_audit_appendix = include_audit_appendix,
                show_signature_lines = show_signature_lines,
                draft_watermark = draft_watermark)
  if (any(!vapply(flags, .cr_scalar_logical, logical(1)))) {
    cli::cli_abort("Report-style switches must each be one non-missing logical value.")
  }
  structure(list(
    paper = "A4", mode = mode, density = density, locale = locale,
    logo = logo, primary_colour = primary_colour,
    secondary_colour = secondary_colour,
    date_format = date_format, date_time_format = date_time_format,
    labels = labels, footer_text = footer_text,
    include_audit_appendix = include_audit_appendix,
    show_signature_lines = show_signature_lines,
    draft_watermark = draft_watermark
  ), class = c("cr_report_style", "list"))
}

.cr_scalar_logical <- function(x) is.logical(x) && length(x) == 1L && !is.na(x)
.cr_check_report_colour <- function(x, arg) {
  if (!is.character(x) || length(x) != 1L || is.na(x) ||
      !grepl("^#[0-9A-Fa-f]{6}$", x)) {
    cli::cli_abort("{.arg {arg}} must be a six-digit hex colour such as {.val #315A70}.")
  }
  invisible(x)
}

.cr_validate_report_logo <- function(path) {
  if (!is.character(path) || length(path) != 1L || is.na(path) || !nzchar(path)) {
    cli::cli_abort("A report logo must be one non-empty local path.")
  }
  if (!file.exists(path)) cli::cli_abort("Report logo not found: {.path {path}}")
  ext <- tolower(tools::file_ext(path))
  if (!ext %in% c("png", "jpg", "jpeg", "pdf")) {
    cli::cli_abort("Report logos must be PNG, JPEG, or PDF files.")
  }
  invisible(path)
}

.cr_as_report_style <- function(style) {
  if (is.null(style)) return(cr_report_style())
  if (inherits(style, "cr_report_style")) return(style)
  if (inherits(style, "cr_plot_style")) {
    return(cr_report_style(mode = style$mode %||% "colour",
                           density = if (identical(style$variant, "report")) "compact" else "standard"))
  }
  cli::cli_abort("{.arg style} must be a {.cls cr_report_style}.")
}

#' Create a reusable laboratory report profile
#'
#' A profile stores organization-wide branding and display policy separately
#' from examination-specific scientific configuration.
#'
#' @param laboratory Default laboratory metadata.
#' @param style A [cr_report_style()].
#' @param labels Named display-label overrides.
#' @param footer_statement Optional laboratory-controlled release statement.
#' @param default_title Optional default report title.
#' @param required_fields Optional dotted required-field paths.
#' @return A `cr_report_profile` object.
#' @family laboratory reporting
#' @export
cr_report_profile <- function(laboratory = list(), style = cr_report_style(),
                              labels = character(), footer_statement = NULL,
                              default_title = NULL,
                              required_fields = character()) {
  if (!is.list(laboratory)) cli::cli_abort("{.arg laboratory} must be a list.")
  style <- .cr_as_report_style(style)
  if (!is.character(labels) || (length(labels) && is.null(names(labels)))) {
    cli::cli_abort("{.arg labels} must be a named character vector.")
  }
  if (!is.character(required_fields)) {
    cli::cli_abort("{.arg required_fields} must be a character vector.")
  }
  if (.cr_present(footer_statement)) style$footer_text <- as.character(footer_statement)[1L]
  structure(list(laboratory = laboratory, style = style, labels = labels,
                 default_title = default_title,
                 required_fields = required_fields),
            class = c("cr_report_profile", "list"))
}

.cr_apply_report_profile <- function(spec, profile) {
  if (is.null(profile)) return(spec)
  if (!inherits(profile, "cr_report_profile")) {
    cli::cli_abort("{.arg profile} must be a {.cls cr_report_profile}.")
  }
  out <- spec
  supplied <- Filter(function(x) !is.null(x), out$laboratory)
  out$laboratory <- utils::modifyList(profile$laboratory, supplied)
  out$field_labels <- c(profile$labels, out$field_labels)
  out$field_labels <- out$field_labels[!duplicated(names(out$field_labels), fromLast = TRUE)]
  out$required_fields <- unique(c(profile$required_fields, out$required_fields))
  if (.cr_present(profile$default_title) &&
      (!.cr_present(out$report$title) ||
       identical(out$report$title,"Laboratory Report"))) {
    out$report$title <- profile$default_title
  }
  out
}

#' @export
print.cr_report_style <- function(x, ...) {
  cat("<cr_report_style>\n")
  cat("  Paper:", x$paper, "|", x$mode, "|", x$density, "\n")
  cat("  Locale:", x$locale, "\n")
  invisible(x)
}

# Central visual tokens shared by the LaTeX document and embedded report plots.
.cr_report_tokens <- function(style, status="DRAFT") {
  style <- .cr_as_report_style(style)
  grayscale <- identical(style$mode,"grayscale")
  status_colour <- switch(toupper(status),
    AMENDED="#7A332E", CANCELLED="#7A332E", REVIEWED="#515E65",
    FINAL=style$primary_colour, DRAFT=style$primary_colour,
    style$secondary_colour)
  list(
    primary=if(grayscale) "#3E3E3E" else style$primary_colour,
    secondary=if(grayscale) "#666666" else style$secondary_colour,
    text="#24292D", muted="#5D666C", rule="#AEB7BC",
    panel="#F4F6F7", pass=if(grayscale) "#333333" else "#2F6663",
    warn=if(grayscale) "#333333" else "#805A10",
    fail=if(grayscale) "#222222" else "#7A332E",
    status=if(grayscale) "#222222" else status_colour,
    body_size=if(identical(style$density,"compact")) 9.4 else 10,
    body_leading=if(identical(style$density,"compact")) 11.1 else 11.8,
    metadata_stretch=if(identical(style$density,"compact")) 0.98 else 1.04,
    table_stretch=if(identical(style$density,"compact")) 1.04 else 1.10,
    section_space=if(identical(style$density,"compact")) 1.5 else 2.0
  )
}
