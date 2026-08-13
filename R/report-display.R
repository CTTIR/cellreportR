# Human-facing report display model. Stored data remain unchanged.

.cr_report_labels <- function(locale = c("en", "de")) {
  locale <- match.arg(locale)
  en <- c(
    document_type = "LABORATORY REPORT", laboratory = "Laboratory",
    subject_specimen = "Subject / Case and Specimen", subject_case = "Subject / Case",
    specimen = "Specimen", examination = "Examination", result = "Result",
    interpretation = "Interpretation", recommendation = "Recommendation",
    quality_control = "Quality Control", traceability = "Method and Traceability",
    limitations = "Limitations", additional_information = "Additional Information",
    authorization = "Authorization and Release", amendment = "Amendment",
    audit_appendix = "Appendix A", audit_title = "Technical Provenance and Audit Information",
    report_id = "Report ID", version = "Version", status = "Status",
    created_at = "Created", released_at = "Released",
    supersedes_report_id = "Supersedes", amendment_reason = "Amendment Reason",
    name = "Name", department = "Department", address = "Address",
    telephone = "Telephone", email = "Email", website = "Website",
    accreditation_text = "Accreditation", accreditation_identifier = "Accreditation ID",
    subject_id = "Subject ID", date_of_birth = "Date of Birth", sex = "Sex / Category",
    case_id = "Case ID", order_id = "Order ID", specimen_id = "Specimen ID",
    specimen_type = "Type", collection_datetime = "Collected",
    received_datetime = "Received", condition = "Condition", comment = "Comment",
    short_name = "Short Name", method = "Method", intended_use = "Intended Use / Purpose",
    assay_version = "Assay Version", analysis_pipeline_version = "Analysis Pipeline Version",
    qc_ruleset_version = "QC Ruleset Version",
    interpretation_ruleset_version = "Interpretation Ruleset Version",
    instrument_id = "Instrument ID", instrument_name = "Instrument Name",
    instrument_software = "Instrument Software", classification = "Classification",
    measured_value = "Measured Value", reference = "Reference",
    decision_limit = "Decision Limit", qc_status = "QC Status",
    reviewed_by = "Reviewed by", reviewer_role = "Reviewer Role",
    authorized_by = "Authorized by", authorizer_role = "Authorizer Role",
    electronic_release = "Electronic Report Release", signature_text = "Signature Text",
    criterion = "Criterion", observed = "Observed", acceptance = "Acceptance",
    schema = "Report Data Schema", template = "Template",
    package_version = "cellreportR Version", r_version = "R Version",
    report_data_hash = "Report Data Hash", design_hash = "Design Hash",
    provenance_hash = "Source Provenance Hash", page = "Page", of = "of"
  )
  if (locale == "en") return(en)
  de <- c(
    document_type = "LABORBERICHT", laboratory = "Labor",
    subject_specimen = "Subjekt / Fall und Probe", subject_case = "Subjekt / Fall",
    specimen = "Probe", examination = "Untersuchung", result = "Ergebnis",
    interpretation = "Interpretation", recommendation = "Empfehlung",
    quality_control = "Qualit\u00e4tskontrolle", traceability = "Methode und R\u00fcckverfolgbarkeit",
    limitations = "Einschr\u00e4nkungen", additional_information = "Zus\u00e4tzliche Informationen",
    authorization = "Freigabe", amendment = "\u00c4nderung", audit_appendix = "Anhang A",
    audit_title = "Technische Provenienz und Auditinformationen",
    report_id = "Berichts-ID", version = "Version", status = "Status",
    created_at = "Erstellt", released_at = "Freigegeben",
    supersedes_report_id = "Ersetzt", amendment_reason = "\u00c4nderungsgrund",
    name = "Name", department = "Abteilung", address = "Adresse",
    telephone = "Telefon", email = "E-Mail", website = "Website",
    subject_id = "Subjekt-ID", date_of_birth = "Geburtsdatum", sex = "Geschlecht / Kategorie",
    case_id = "Fall-ID", order_id = "Auftrags-ID", specimen_id = "Proben-ID",
    specimen_type = "Typ", collection_datetime = "Entnommen",
    received_datetime = "Eingegangen", condition = "Zustand", comment = "Kommentar",
    short_name = "Kurzbezeichnung", method = "Methode", intended_use = "Zweck",
    assay_version = "Assay-Version", analysis_pipeline_version = "Analyse-Pipeline-Version",
    qc_ruleset_version = "QC-Regelwerk-Version",
    interpretation_ruleset_version = "Interpretationsregelwerk-Version",
    instrument_id = "Ger\u00e4te-ID", instrument_name = "Ger\u00e4tename",
    instrument_software = "Ger\u00e4tesoftware", classification = "Klassifikation",
    measured_value = "Messwert", reference = "Referenz",
    decision_limit = "Entscheidungsgrenze", qc_status = "QC-Status",
    reviewed_by = "Gepr\u00fcft durch", reviewer_role = "Pr\u00fcferrolle",
    authorized_by = "Freigegeben durch", authorizer_role = "Freigaberolle",
    electronic_release = "Elektronische Freigabe", signature_text = "Signaturtext",
    criterion = "Kriterium", observed = "Beobachtet", acceptance = "Akzeptanz",
    schema = "Berichtsschema", template = "Vorlage",
    package_version = "cellreportR-Version", r_version = "R-Version",
    report_data_hash = "Berichtsdaten-Hash", design_hash = "Design-Hash",
    provenance_hash = "Quelldaten-Hash", page = "Seite", of = "von"
  )
  utils::modifyList(as.list(en), as.list(de)) |> unlist(use.names = TRUE)
}

.cr_display_label <- function(key, labels) {
  val <- labels[[key]]
  if (is.null(val) || !nzchar(val)) key else unname(val)
}

.cr_human_datetime <- function(x, style, include_time = TRUE) {
  if (!.cr_present(x)) return(NULL)
  if (!inherits(x, c("Date", "POSIXt"))) return(as.character(x)[1L])
  pattern <- if (include_time && inherits(x, "POSIXt")) {
    style$date_time_format %||% if (style$locale == "de") "%d.%m.%Y, %H:%M" else "%d %b %Y, %H:%M"
  } else {
    style$date_format %||% if (style$locale == "de") "%d.%m.%Y" else "%d %b %Y"
  }
  format(x, pattern, tz = attr(x, "tzone") %||% "")
}

.cr_display_rows <- function(x, keys, labels, style, date_keys = character()) {
  rows <- lapply(keys, function(key) {
    value <- x[[key]]
    if (!.cr_present(value)) return(NULL)
    if (key %in% date_keys) value <- .cr_human_datetime(value, style,
      include_time = !identical(key, "date_of_birth"))
    data.frame(key = key, label = .cr_display_label(key, labels),
               value = paste(as.character(value), collapse = ", "),
               stringsAsFactors = FALSE)
  })
  rows <- Filter(Negate(is.null), rows)
  if (!length(rows)) {
    return(data.frame(key=character(),label=character(),value=character(),
                      stringsAsFactors=FALSE))
  }
  dplyr::bind_rows(rows)
}

#' Prepare human-facing values for report rendering
#'
#' Produces already formatted labels, dates, values, section visibility flags,
#' and audit rows. It does not change the report specification.
#'
#' @param report A `cr_lab_report`.
#' @return A plain nested list suitable for inspection, serialization, and
#'   deterministic rendering.
#' @family laboratory reporting
#' @export
cr_report_display_data <- function(report) {
  if (!inherits(report, "cr_lab_report")) {
    cli::cli_abort("{.arg report} must be a {.cls cr_lab_report}.")
  }
  s <- report$spec
  style <- .cr_as_report_style(report$style)
  labels <- c(.cr_report_labels(style$locale), style$labels, s$field_labels)
  labels <- labels[!duplicated(names(labels), fromLast = TRUE)]
  result_value <- s$result$display_value %||%
    if (.cr_present(s$result$value)) format(s$result$value, trim = TRUE) else NULL
  if (.cr_present(result_value) && .cr_present(s$result$unit)) {
    result_value <- paste(result_value, s$result$unit)
  }
  lab <- .cr_display_rows(s$laboratory,
    c("name", "department", "address", "telephone", "email", "website",
      "accreditation_text", "accreditation_identifier"), labels, style)
  subject <- .cr_display_rows(s$subject,
    c("subject_id", "case_id", "order_id", "name", "date_of_birth", "sex"),
    labels, style, "date_of_birth")
  specimen <- .cr_display_rows(s$specimen,
    c("specimen_id", "specimen_type", "collection_datetime", "received_datetime",
      "condition", "comment"), labels, style,
    c("collection_datetime", "received_datetime"))
  examination <- .cr_display_rows(s$examination,
    c("name", "short_name", "intended_use"), labels, style)
  result <- .cr_display_rows(list(
    classification = s$result$classification,
    measured_value = result_value, reference = s$result$reference,
    decision_limit = s$result$decision_limit, qc_status = s$result$qc_status,
    comment = s$result$comment),
    c("classification", "measured_value", "reference", "decision_limit",
      "qc_status", "comment"), labels, style)
  instrument <- paste(Filter(.cr_present,
    c(s$examination$instrument_name,
      if (.cr_present(s$examination$instrument_id)) paste0("(", s$examination$instrument_id, ")") else NULL)),
    collapse = " ")
  traceability <- .cr_display_rows(list(
    method = s$examination$method,
    assay_version = s$examination$assay_version,
    analysis_pipeline_version = s$examination$analysis_pipeline_version,
    qc_ruleset_version = s$examination$qc_ruleset_version,
    interpretation_ruleset_version = s$examination$interpretation_ruleset_version,
    instrument_name = if (nzchar(instrument)) instrument else NULL,
    instrument_software = s$examination$instrument_software),
    c("method", "assay_version", "analysis_pipeline_version",
      "qc_ruleset_version", "interpretation_ruleset_version",
      "instrument_name", "instrument_software"), labels, style)
  identity <- .cr_display_rows(list(
    report_id = s$report$report_id, version = s$report$version,
    status = s$report$status,
    created_at = .cr_human_datetime(s$report$created_at, style),
    released_at = .cr_human_datetime(s$report$released_at, style)),
    c("report_id", "version", "status", "created_at", "released_at"), labels, style)
  custom <- if (length(s$custom_fields)) {
    data.frame(key = names(s$custom_fields), label = names(s$custom_fields),
               value = vapply(s$custom_fields, .cr_display, character(1)),
               stringsAsFactors = FALSE)
  } else data.frame(key=character(), label=character(), value=character())
  custom_sections <- lapply(s$custom_sections, function(x) list(
    title = x$title,
    rows = if (length(x$fields)) data.frame(
      key=names(x$fields), label=names(x$fields),
      value=vapply(x$fields, .cr_display, character(1)),
      stringsAsFactors=FALSE) else data.frame(key=character(),label=character(),value=character())))
  auth <- .cr_display_rows(s$authorization,
    c("reviewed_by", "reviewer_role", "authorized_by", "authorizer_role",
      "released_at", "electronic_release", "signature_text"), labels, style,
    "released_at")
  amendment <- .cr_display_rows(s$report,
    c("supersedes_report_id", "amendment_reason"), labels, style)
  audit <- cr_report_provenance(report$experiment, report)
  audit_rows <- .cr_display_rows(list(
    report_id = s$report$report_id, version = s$report$version,
    status = s$report$status,
    schema = paste(s$schema_name, s$schema_version),
    template = paste(report$template_name, report$template_version),
    package_version = audit$software$package_version,
    r_version = audit$software$r_version,
    analysis_pipeline_version = audit$versions$analysis_pipeline,
    qc_ruleset_version = audit$versions$qc_ruleset,
    interpretation_ruleset_version = audit$versions$interpretation_ruleset,
    report_data_hash = audit$report$report_data_hash,
    design_hash = audit$experiment$design_hash %||% NULL,
    provenance_hash = audit$experiment$provenance_hash %||% NULL),
    c("report_id", "version", "status", "schema", "template",
      "package_version", "r_version", "analysis_pipeline_version",
      "qc_ruleset_version", "interpretation_ruleset_version",
      "report_data_hash", "design_hash", "provenance_hash"), labels, style)
  list(
    labels = labels, style = unclass(style),
    report = list(title = s$report$title, id = s$report$report_id,
      version = s$report$version, status = s$report$status,
      created = .cr_human_datetime(s$report$created_at, style),
      laboratory_name = s$laboratory$name %||% "",
      department = s$laboratory$department %||% "",
      logo = style$logo %||% s$laboratory$logo %||% NULL),
    identity = identity, laboratory = lab, subject = subject,
    specimen = specimen, examination = examination, result = result,
    interpretation = s$interpretation, qc = as.data.frame(report$qc),
    traceability = traceability, limitations = s$limitations,
    custom_fields = custom, custom_sections = custom_sections,
    authorization = auth, amendment = amendment, audit = audit_rows,
    include = list(
      result_graphic = !is.null(report$result_graphic),
      audit_appendix = isTRUE(report$include_audit_appendix),
      signature_lines = isTRUE(style$show_signature_lines),
      watermark = isTRUE(style$draft_watermark) && identical(s$report$status, "DRAFT"))
  )
}
