#' Bind report claims and figures to portable source-file evidence
#'
#' This neutral provenance layer does not calculate effects, infer units, verify
#' scientific validity, or prove that a figure was generated from its declared
#' tables. Figure links are explicit declarations whose file identities are
#' checked. Source files remain external to the report.
#'
#' @param root Existing directory containing all source files. Paths stored in
#'   the evidence are relative to this root, so the complete tree can be moved.
#' @param tables Named list of descriptors with `path`, `format` (`"csv"` or
#'   `"tsv"`), and `key` (one or more unique-key column names). Fields are read as
#'   UTF-8 character strings without automatic missing-value conversion.
#' @param claims Named list of descriptors with `table`, `key` (a named character
#'   vector giving every key value), `column`, and optional `format` (`"text"`
#'   or `"number"`, default `"text"`) and `digits` (default 3). Numeric claims
#'   must be finite decimal numbers; formatting uses [cr_format_number()].
#'   No scaling, unit conversion, missing-value substitution or inference occurs.
#' @param figures Named list of descriptors with `path` and `tables` (nonempty
#'   character vector of declared source-table identifiers).
#' @return `cr_report_evidence` returns a versioned list with file SHA-256 hashes,
#'   keyed raw values, formatted displays and a manifest SHA-256. Its hash uses
#'   UTF-8 JSON bytes, not R serialization. Identifiers use radix ordering and
#'   numeric displays use a period decimal mark regardless of locale/options.
#'   Row order and
#'   other source-byte changes deliberately invalidate the source hash.
#' @export
#' @examples
#' root <- tempfile(); dir.create(root)
#' writeLines(c("group,value", "control,1.25"), file.path(root, "result.csv"))
#' evidence <- cr_report_evidence(root,
#'   tables = list(result = list(path = "result.csv", format = "csv", key = "group")),
#'   claims = list(mean = list(table = "result", key = c(group = "control"),
#'                             column = "value", format = "number", digits = 2)))
#' cr_validate_report_evidence(evidence, root)
#' unlink(root, recursive = TRUE)
cr_report_evidence <- function(root, tables, claims = list(), figures = list()) {
  previous_options <- options(OutDec = ".")
  on.exit(options(previous_options), add = TRUE)
  root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  if (!dir.exists(root)) cli::cli_abort("{.arg root} must be a directory.")
  tables <- .cr_evidence_named(tables, "tables", empty = FALSE)
  claims <- .cr_evidence_named(claims, "claims")
  figures <- .cr_evidence_named(figures, "figures")
  data <- records <- list()
  for (id in names(tables)) {
    d <- tables[[id]]
    .cr_evidence_fields(d, c("path", "format", "key"), character())
    path <- .cr_evidence_path(root, d$path)
    before <- digest::digest(file = path, algo = "sha256")
    if (!identical(d$format, "csv") && !identical(d$format, "tsv")) {
      cli::cli_abort("Table format must be csv or tsv.")
    }
    x <- readr::read_delim(path, delim = if (d$format == "csv") "," else "\t",
      col_types = readr::cols(.default = readr::col_character()), na = character(),
      trim_ws = FALSE, name_repair = "minimal", show_col_types = FALSE,
      progress = FALSE, num_threads = 1L)
    if (nrow(readr::problems(x))) cli::cli_abort("Malformed source table: {id}.")
    if (!identical(before, digest::digest(file = path, algo = "sha256"))) {
      cli::cli_abort("Source table changed while being read: {id}.")
    }
    .cr_evidence_names(names(x), "table columns")
    .cr_evidence_names(d$key, "key columns")
    if (!all(d$key %in% names(x))) cli::cli_abort("Unknown key columns in table {id}.")
    keys <- as.data.frame(x[d$key], stringsAsFactors = FALSE)
    if (anyNA(keys) || any(vapply(keys, function(z) any(!nzchar(z)), logical(1))) ||
        anyDuplicated(keys)) cli::cli_abort("Table keys must be nonmissing, nonempty and unique: {id}.")
    data[[id]] <- x
    records[[id]] <- list(path = d$path, format = d$format, key = d$key,
      sha256 = before,
      rows = as.character(nrow(x)), columns = names(x))
  }
  quoted <- list()
  for (id in names(claims)) {
    d <- claims[[id]]
    .cr_evidence_fields(d, c("table", "key", "column"), c("format", "digits"))
    .cr_evidence_scalar(d$table, "claim table")
    if (!d$table %in% names(data)) cli::cli_abort("Unknown claim table: {d$table}.")
    x <- data[[d$table]]
    .cr_evidence_names(names(d$key), "claim key names")
    if (!is.character(d$key) || anyNA(d$key) ||
        !setequal(names(d$key), records[[d$table]]$key)) {
      cli::cli_abort("Claim key must supply every table key as character values.")
    }
    d$key <- d$key[records[[d$table]]$key]
    hit <- rep(TRUE, nrow(x))
    for (k in names(d$key)) hit <- hit & x[[k]] == d$key[[k]]
    if (sum(hit) != 1L) cli::cli_abort("Claim key must select exactly one row: {id}.")
    .cr_evidence_scalar(d$column, "claim column")
    if (!d$column %in% names(x)) cli::cli_abort("Unknown claim column: {d$column}.")
    value <- x[[d$column]][hit]
    if (is.na(value) || !nzchar(value)) cli::cli_abort("Claim values cannot be missing or empty.")
    format <- d$format %||% "text"
    if (!identical(format, "text") && !identical(format, "number")) {
      cli::cli_abort("Claim format must be text or number.")
    }
    digits <- d$digits %||% 3L
    if (!is.numeric(digits) || length(digits) != 1L || !is.finite(digits) ||
        digits < 0 || digits > 15 || digits != as.integer(digits)) {
      cli::cli_abort("Claim digits must be an integer from 0 to 15.")
    }
    display <- value
    if (format == "number") {
      display <- cr_format_number(.cr_evidence_number(value), digits = digits)
    }
    quoted[[id]] <- list(table = d$table, key = as.list(d$key), column = d$column,
      format = format, digits = as.character(digits), value = value,
      display = display, table_sha256 = records[[d$table]]$sha256)
  }
  graphics <- list()
  for (id in names(figures)) {
    d <- figures[[id]]
    .cr_evidence_fields(d, c("path", "tables"), character())
    path <- .cr_evidence_path(root, d$path)
    .cr_evidence_names(d$tables, "figure source tables")
    if (!all(d$tables %in% names(records))) cli::cli_abort("Unknown figure source table.")
    graphics[[id]] <- list(path = d$path,
      sha256 = digest::digest(file = path, algo = "sha256"),
      tables = sort(d$tables, method = "radix"),
      table_sha256 = lapply(records[sort(d$tables, method = "radix")],
        function(x) x$sha256))
  }
  out <- list(schema = "cellreportR-report-evidence", schema_version = "1.0",
    tables = records, claims = quoted, figures = graphics)
  out$sha256 <- .cr_evidence_hash(out)
  structure(out, class = c("cr_report_evidence", "list"))
}

#' Revalidate report evidence against its current source tree
#' @param evidence A [cr_report_evidence()] object.
#' @param root Current root of the source tree, including after relocation.
#' @return Invisibly `TRUE`; invalid schemas, changed bytes or altered claims error.
#' @export
cr_validate_report_evidence <- function(evidence, root) {
  if (!inherits(evidence, "cr_report_evidence") ||
      !identical(evidence$schema, "cellreportR-report-evidence") ||
      !identical(evidence$schema_version, "1.0")) {
    cli::cli_abort("Unsupported report evidence schema.")
  }
  payload <- unclass(evidence)
  expected <- payload$sha256
  payload$sha256 <- NULL
  if (!identical(expected, .cr_evidence_hash(payload))) cli::cli_abort("Evidence manifest hash mismatch.")
  tables <- lapply(evidence$tables, function(x) x[c("path", "format", "key")])
  claims <- lapply(evidence$claims, function(x) {
    x <- x[c("table", "key", "column", "format", "digits")]
    x$key <- unlist(x$key, use.names = TRUE)
    x$digits <- as.integer(x$digits)
    x
  })
  figures <- lapply(evidence$figures, function(x) x[c("path", "tables")])
  actual <- cr_report_evidence(root, tables, claims, figures)
  if (!identical(unclass(actual), unclass(evidence))) {
    cli::cli_abort("Evidence sources or resolved claims have changed.")
  }
  invisible(TRUE)
}

#' Assemble a laboratory report with validated, source-bound quoted values
#'
#' Claim identifiers become custom-field names and their displays become field
#' values. Existing custom fields with the same names are rejected. The existing
#' report renderer and audit exporter revalidate source files and bound fields.
#' Other report fields and free text are not verified by this contract.
#' @param evidence A [cr_report_evidence()] object.
#' @param root Current source-tree root. Retained for local validation, but
#'   excluded from report data and portable evidence hashes.
#' @param spec A [cr_report_spec()].
#' @param ... Other arguments to [cr_lab_report()].
#' @return A `cr_lab_report` with additional evidence and local root fields.
#' @export
cr_lab_report_from_evidence <- function(evidence, root, spec = cr_report_spec(), ...) {
  cr_validate_report_evidence(evidence, root)
  if (!inherits(spec, "cr_report_spec")) cli::cli_abort("{.arg spec} must be a cr_report_spec.")
  if (any(names(evidence$claims) %in% names(spec$custom_fields))) {
    cli::cli_abort("Evidence claim names collide with existing custom fields.")
  }
  spec$custom_fields <- c(spec$custom_fields,
    lapply(evidence$claims, function(x) x$display))
  report <- cr_lab_report(spec = spec, ...)
  report$evidence <- evidence
  report$evidence_root <- normalizePath(root, winslash = "/", mustWork = TRUE)
  report
}

.cr_validate_bound_evidence <- function(report, root = NULL) {
  if (is.null(report$evidence)) return(invisible(TRUE))
  cr_validate_report_evidence(report$evidence, root %||% report$evidence_root)
  expected <- lapply(report$evidence$claims, function(x) x$display)
  if (!identical(report$spec$custom_fields[names(expected)], expected)) {
    cli::cli_abort("Source-bound report fields have changed.")
  }
  invisible(TRUE)
}

.cr_evidence_hash <- function(x) {
  named_vectors <- function(x) {
    if (is.list(x)) return(lapply(x, named_vectors))
    if (!is.null(names(x))) return(as.list(x))
    x
  }
  json <- jsonlite::toJSON(named_vectors(x), auto_unbox = FALSE, null = "null", digits = NA,
    force = TRUE, pretty = FALSE)
  digest::digest(enc2utf8(as.character(json)), algo = "sha256", serialize = FALSE)
}

.cr_evidence_names <- function(x, what) {
  if (!is.character(x) || !length(x) || anyNA(x) || any(!nzchar(x)) || anyDuplicated(x)) {
    cli::cli_abort("{what} must be nonempty, unique character identifiers.")
  }
}

.cr_evidence_named <- function(x, what, empty = TRUE) {
  if (!is.list(x)) cli::cli_abort("{what} must be a named list.")
  if (!length(x) && empty) return(list())
  .cr_evidence_names(names(x), what)
  x[sort(names(x), method = "radix")]
}

.cr_evidence_number <- function(value) {
  decimal <- "^[+-]?([0-9]+(\\.[0-9]*)?|\\.[0-9]+)([eE][+-]?[0-9]+)?$"
  if (!grepl(decimal, value)) {
    cli::cli_abort("Numeric claims require a finite decimal source value.")
  }
  # Normalize the accepted decimal grammar to JSON without numeric conversion.
  token <- sub("^\\+", "", value)
  token <- sub("^\\.", "0.", token)
  token <- sub("^-\\.", "-0.", token)
  token <- sub("^(-?)0+([0-9])", "\\1\\2", token)
  token <- sub("\\.([eE]|$)", ".0\\1", token)
  if (!grepl("[.eE]", token)) token <- paste0(token, "e0")
  number <- jsonlite::fromJSON(paste0("[", token, "]"))
  if (!is.finite(number)) {
    cli::cli_abort("Numeric claims require a finite decimal source value.")
  }
  number
}

.cr_evidence_fields <- function(x, required, optional) {
  if (!is.list(x) || is.null(names(x)) || anyDuplicated(names(x)) ||
      !all(required %in% names(x)) || !all(names(x) %in% c(required, optional))) {
    cli::cli_abort("Invalid evidence descriptor fields.")
  }
}

.cr_evidence_scalar <- function(x, what) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    cli::cli_abort("{what} must be a nonempty character scalar.")
  }
}

.cr_evidence_path <- function(root, path) {
  .cr_evidence_scalar(path, "Evidence path")
  if (grepl("^(/|[A-Za-z]:)|\\\\", path) ||
      any(strsplit(path, "/", fixed = TRUE)[[1L]] %in% c("..", ".", ""))) {
    cli::cli_abort("Evidence paths must be portable relative paths without traversal.")
  }
  full <- normalizePath(file.path(root, path), winslash = "/", mustWork = TRUE)
  if (!startsWith(full, paste0(sub("/$", "", root), "/")) || dir.exists(full)) {
    cli::cli_abort("Evidence file must remain within root, including symlink targets.")
  }
  full
}
