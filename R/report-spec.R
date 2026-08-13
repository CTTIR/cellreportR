# Generic laboratory report specification, classification and QC helpers.

.cr_report_sections <- c("report", "laboratory", "subject", "specimen",
  "examination", "result", "interpretation", "authorization")
.cr_report_statuses <- c("DRAFT", "REVIEWED", "FINAL", "AMENDED", "CANCELLED")

#' Construct a configurable laboratory report specification
#'
#' Creates a domain-neutral, versioned description of values that may appear
#' in a laboratory-style report. No analytical calculation or interpretation
#' is performed. All scientific content is supplied by the caller.
#'
#' @param report,laboratory,subject,specimen,examination,result,interpretation,authorization Named lists for the corresponding report sections.
#' @param limitations Character vector of user-supplied limitations.
#' @param custom_fields Named list of additional label/value pairs.
#' @param custom_sections List of sections, each with `title` and named `fields`.
#' @param required_fields Character vector of dotted field paths required by the caller.
#' @param field_labels Named character vector of optional display-label overrides.
#' @param schema_version Report-data schema version, independent of the package version.
#' @return An object of class `cr_report_spec`.
#' @family laboratory reporting
#' @export
cr_report_spec <- function(
    report = list(), laboratory = list(), subject = list(), specimen = list(),
    examination = list(), result = list(), interpretation = list(),
    limitations = character(), authorization = list(), custom_fields = list(),
    custom_sections = list(), required_fields = character(),
    field_labels = character(), schema_version = "1.0") {
  sections <- list(report = report, laboratory = laboratory, subject = subject,
    specimen = specimen, examination = examination, result = result,
    interpretation = interpretation, authorization = authorization)
  bad <- !vapply(sections, is.list, logical(1))
  if (any(bad)) cli::cli_abort("Report sections must be lists: {.field {names(sections)[bad]}}.")
  sections$report <- utils::modifyList(list(
    title = "Laboratory Report", report_id = NULL, version = "1.0",
    status = "DRAFT", created_at = Sys.time(), analysis_completed_at = NULL,
    released_at = NULL, supersedes_report_id = NULL, amendment_reason = NULL
  ), sections$report)
  obj <- c(list(schema_name = "cellreportR-report-spec",
                schema_version = schema_version), sections,
    list(limitations = limitations, custom_fields = custom_fields,
         custom_sections = custom_sections, required_fields = required_fields,
         field_labels = field_labels,
         events = .cr_report_event("report_spec_created", "INFO", "specification")))
  class(obj) <- c("cr_report_spec", "list")
  issues <- .cr_report_spec_issues(obj, strict = FALSE)
  if (any(issues$severity == "ERROR")) cli::cli_abort(c("Invalid report specification.", "x" = issues$message[issues$severity == "ERROR"]))
  obj
}

.cr_report_event <- function(event, status = "INFO", component = "report") {
  data.frame(event = event, timestamp = format(Sys.time(), "%Y-%m-%dT%H:%M:%S%z"),
    status = status, component = component, stringsAsFactors = FALSE)
}

#' Validate a laboratory report specification
#'
#' @param spec A `cr_report_spec`.
#' @param strict In strict mode structural minima and caller-defined required fields are errors.
#' @param return_issues Return a severity-coded issue table instead of throwing errors.
#' @return `TRUE` invisibly, or a data frame when `return_issues = TRUE`.
#' @family laboratory reporting
#' @export
cr_validate_report_spec <- function(spec, strict = TRUE, return_issues = FALSE) {
  issues <- .cr_report_spec_issues(spec, strict)
  if (return_issues) return(issues)
  errors <- issues$message[issues$severity == "ERROR"]
  if (length(errors)) cli::cli_abort(c("Invalid report specification.", "x" = errors))
  warnings <- issues$message[issues$severity == "WARNING"]
  if (length(warnings)) cli::cli_warn(c("Report specification warnings.", "!" = warnings))
  invisible(TRUE)
}

.cr_report_spec_issues <- function(spec, strict) {
  add <- function(severity, field, message) data.frame(severity, field, message,
    stringsAsFactors = FALSE)
  out <- list()
  if (!inherits(spec, "cr_report_spec")) return(add("ERROR", "spec", "Object is not a cr_report_spec."))
  missing <- setdiff(c("schema_name", "schema_version", .cr_report_sections,
                       "limitations", "custom_fields", "custom_sections"), names(spec))
  if (length(missing)) out[[length(out) + 1L]] <- add("ERROR", "spec", paste("Missing sections:", paste(missing, collapse = ", ")))
  for (nm in intersect(.cr_report_sections, names(spec))) if (!is.list(spec[[nm]]))
    out[[length(out) + 1L]] <- add("ERROR", nm, "Section must be a list.")
  scalar_paths <- c("report.title","report.report_id","report.version","report.status","report.supersedes_report_id","report.amendment_reason","laboratory.name","subject.subject_id","subject.name","specimen.specimen_id","specimen.specimen_type","examination.name","result.display_value","result.unit","result.classification","result.qc_status","interpretation.summary","interpretation.text","interpretation.recommendation","authorization.reviewed_by","authorization.authorized_by")
  for(path in scalar_paths) { val<-.cr_get_path(spec,path); if(!is.null(val)&&length(val)!=1L) out[[length(out)+1L]]<-add("ERROR",path,"Field must be a scalar value.") }
  status <- spec$report$status %||% ""
  if (!is.character(status) || length(status) != 1L || !status %in% .cr_report_statuses)
    out[[length(out) + 1L]] <- add("ERROR", "report.status", "Status must be DRAFT, REVIEWED, FINAL, AMENDED or CANCELLED.")
  version <- spec$report$version %||% ""
  if (!is.character(version) || length(version) != 1L || !grepl("^[0-9]+(?:\\.[0-9]+)*$", version))
    out[[length(out) + 1L]] <- add("ERROR", "report.version", "Version must contain dot-separated non-negative integers.")
  dates <- c("created_at", "analysis_completed_at", "released_at")
  for (nm in dates) { val <- spec$report[[nm]]; if (!is.null(val) && !inherits(val, c("Date", "POSIXt")))
    out[[length(out) + 1L]] <- add("ERROR", paste0("report.", nm), "Must be a Date, date-time, or NULL.") }
  for(path in c("subject.date_of_birth","specimen.collection_datetime","specimen.received_datetime","authorization.released_at")) { val<-.cr_get_path(spec,path); if(!is.null(val)&&!inherits(val,c("Date","POSIXt"))) out[[length(out)+1L]]<-add("ERROR",path,"Must be a Date, date-time, or NULL.") }
  if(!is.null(spec$result$value)&&(!is.numeric(spec$result$value)||length(spec$result$value)!=1L||!is.finite(spec$result$value))) out[[length(out)+1L]]<-add("ERROR","result.value","Result value must be one finite numeric value or NULL.")
  if (isTRUE(strict) && !.cr_present(spec$report$report_id)) out[[length(out) + 1L]] <- add("ERROR", "report.report_id", "Report ID is required in strict mode.")
  if (isTRUE(strict) && !.cr_present(spec$result$classification) && !.cr_present(spec$result$value) && !.cr_present(spec$result$display_value)) out[[length(out) + 1L]] <- add("ERROR", "result", "A result value, display value, or classification is required in strict mode.")
  if (identical(status, "AMENDED")) {
    if (!.cr_present(spec$report$supersedes_report_id)) out[[length(out) + 1L]] <- add(if (strict) "ERROR" else "WARNING", "report.supersedes_report_id", "An amended report should identify the superseded report.")
    if (!.cr_present(spec$report$amendment_reason)) out[[length(out) + 1L]] <- add(if (strict) "ERROR" else "WARNING", "report.amendment_reason", "An amended report should state an amendment reason.")
  }
  if (identical(status, "FINAL") && !.cr_present(spec$report$released_at) && !.cr_present(spec$authorization$released_at)) out[[length(out) + 1L]] <- add(if (strict) "ERROR" else "WARNING", "report.released_at", "A final report should include release metadata.")
  if (!.cr_present(spec$authorization$authorized_by)) out[[length(out) + 1L]] <- add("WARNING", "authorization.authorized_by", "No authorization information supplied.")
  if (!is.character(spec$limitations)) out[[length(out) + 1L]] <- add("ERROR", "limitations", "Limitations must be a character vector.")
  if (!is.list(spec$custom_fields) || is.null(names(spec$custom_fields)) && length(spec$custom_fields)) out[[length(out) + 1L]] <- add("ERROR", "custom_fields", "Custom fields must be a named list.")
  if (length(spec$custom_fields) && (any(!nzchar(names(spec$custom_fields))) || anyDuplicated(names(spec$custom_fields)))) out[[length(out) + 1L]] <- add("ERROR", "custom_fields", "Custom-field labels must be non-empty and unique.")
  for (i in seq_along(spec$custom_sections)) { s <- spec$custom_sections[[i]]; if (!is.list(s) || !.cr_present(s$title) || !is.list(s$fields) || is.null(names(s$fields))) out[[length(out) + 1L]] <- add("ERROR", paste0("custom_sections.", i), "Each custom section needs a title and named fields.") }
  for (path in spec$required_fields %||% character()) if (!.cr_present(.cr_get_path(spec, path))) out[[length(out) + 1L]] <- add(if (strict) "ERROR" else "WARNING", path, "User-defined required field is missing.")
  if (!length(out)) return(data.frame(severity=character(),field=character(),message=character()))
  do.call(rbind, out)
}

.cr_present <- function(x) !is.null(x) && length(x) > 0L && !all(is.na(x)) && any(nzchar(trimws(as.character(x))))
.cr_get_path <- function(x, path) { for (part in strsplit(path, ".", fixed = TRUE)[[1L]]) { if (!is.list(x) || is.null(x[[part]])) return(NULL); x <- x[[part]] }; x }

#' Print a laboratory report specification
#' @param x A `cr_report_spec`.
#' @param ... Unused.
#' @return `x`, invisibly.
#' @export
cr_print_report_spec <- function(x, ...) { print(x); invisible(x) }

#' @export
print.cr_report_spec <- function(x, ...) {
  cat("<cr_report_spec>", x$schema_version, "\n")
  cat("  Report:", x$report$report_id %||% "(unset)", "version", x$report$version %||% "(unset)", "[", x$report$status %||% "(unset)", "]\n")
  cat("  Result:", x$result$classification %||% x$result$display_value %||% x$result$value %||% "(unset)", "\n")
  invisible(x)
}

#' Deterministically classify numeric results using explicit boundaries
#' @param value Numeric vector.
#' @param negative_upper,positive_lower Explicit finite boundaries. Values at `negative_upper` are negative; values at `positive_lower` are positive; values between are indeterminate.
#' @param labels Named character vector containing `negative`, `indeterminate`, and `positive`.
#' @return Character vector with missing/non-finite inputs returned as `NA`.
#' @export
cr_classify_result <- function(value, negative_upper, positive_lower,
                               labels = c(negative="NEGATIVE", indeterminate="INDETERMINATE", positive="POSITIVE")) {
  if (!is.numeric(value)) cli::cli_abort("{.arg value} must be numeric.")
  if (!is.numeric(negative_upper) || length(negative_upper)!=1L || !is.finite(negative_upper) || !is.numeric(positive_lower) || length(positive_lower)!=1L || !is.finite(positive_lower) || negative_upper > positive_lower) cli::cli_abort("Explicit finite boundaries must satisfy {.arg negative_upper} <= {.arg positive_lower}.")
  if (!all(c("negative","indeterminate","positive") %in% names(labels))) cli::cli_abort("{.arg labels} must name negative, indeterminate and positive values.")
  out <- rep(NA_character_, length(value)); ok <- is.finite(value)
  out[ok & value <= negative_upper] <- labels[["negative"]]
  out[ok & value > negative_upper & value < positive_lower] <- labels[["indeterminate"]]
  out[ok & value >= positive_lower] <- labels[["positive"]]; out
}

#' Apply a caller-selected QC finalization rule
#' @param classification Character vector.
#' @param qc_status Character vector, recycled against `classification`.
#' @param failed_statuses QC labels treated as failed.
#' @param invalid_label Label used for failed QC.
#' @param invalidate Whether failed QC replaces the supplied classification.
#' @export
cr_finalize_result <- function(classification, qc_status, failed_statuses="FAIL", invalid_label="INVALID", invalidate=TRUE) {
  n <- max(length(classification), length(qc_status)); classification <- rep_len(as.character(classification), n); qc_status <- rep_len(as.character(qc_status), n)
  if (isTRUE(invalidate)) classification[!is.na(qc_status) & qc_status %in% failed_statuses] <- invalid_label
  classification
}

#' Look up explicit interpretation text
#' @param classification Character vector.
#' @param dictionary Named character vector or named list.
#' @param default Value used for unknown or missing classifications.
#' @export
cr_interpretation_lookup <- function(classification, dictionary, default=NA_character_) {
  if (is.null(names(dictionary)) || any(!nzchar(names(dictionary)))) cli::cli_abort("{.arg dictionary} must have non-empty names.")
  out <- unname(as.character(dictionary[match(as.character(classification), names(dictionary))])); out[is.na(out)] <- default; out
}

#' Construct a concise report QC table
#' @param criterion,observed,acceptance,status Vectors defining reportable QC rows.
#' @param source Optional source identifiers.
#' @export
cr_report_qc <- function(criterion=character(), observed=character(), acceptance=character(), status=character(), source=character()) {
  n <- max(length(criterion),length(observed),length(acceptance),length(status),length(source),0L)
  if (!n) return(tibble::tibble(criterion=character(),observed=character(),acceptance=character(),status=character(),source=character()))
  args <- list(criterion,observed,acceptance,status); if (any(vapply(args, length, integer(1)) %in% setdiff(seq_len(n), c(1L,n)))) cli::cli_abort("QC columns must have length one or a common length.")
  tibble::tibble(criterion=rep_len(as.character(criterion),n), observed=rep_len(as.character(observed),n), acceptance=rep_len(as.character(acceptance),n), status=rep_len(as.character(status),n), source=if(length(source)) rep_len(as.character(source),n) else rep(NA_character_,n))
}

#' Validate a concise report QC table
#' @param qc A data frame with criterion, observed, acceptance and status columns.
#' @export
cr_validate_report_qc <- function(qc) { if (!is.data.frame(qc)) cli::cli_abort("{.arg qc} must be a data frame."); missing <- setdiff(c("criterion","observed","acceptance","status"),names(qc)); if(length(missing)) cli::cli_abort("QC table is missing: {.field {missing}}."); if(any(!nzchar(trimws(as.character(qc$criterion))))) cli::cli_abort("QC criteria must not be empty."); invisible(TRUE) }

#' Convert an existing experiment QC log to report-compatible rows
#' @param x A `cr_experiment` or QC-log data frame.
#' @export
cr_report_qc_from_log <- function(x) { log <- if(inherits(x,"cr_experiment")) x$qc_log else x; if(!is.data.frame(log)) cli::cli_abort("{.arg x} must contain a QC log."); if(!nrow(log)) return(cr_report_qc()); cr_report_qc(criterion=as.character(log$step), observed=if("cells_after"%in%names(log)) as.character(log$cells_after) else "", acceptance="Recorded analytical QC step", status="RECORDED", source="qc_log") }
