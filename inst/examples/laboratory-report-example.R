# Manual release-QA fixture for laboratory-report template 2.0.
# Set CELLREPORTR_EXAMPLE_DIR to choose an output directory.
out_dir <- Sys.getenv("CELLREPORTR_EXAMPLE_DIR", unset = tempdir())
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

spec <- cellreportR::cr_report_spec(
  report = list(
    title = "Laboratory Report", report_id = "EXAMPLE-001",
    version = "1.0", status = "DRAFT",
    created_at = as.POSIXct("2026-08-13 14:00:00", tz = "Europe/Berlin")
  ),
  laboratory = list(
    name = "Example Laboratory", department = "Analytical Services",
    address = "Example Street 1, 00000 Example City",
    telephone = "+00 000 000000", email = "laboratory@example.invalid"
  ),
  subject = list(subject_id = "SUBJECT-001", case_id = "CASE-001",
                 order_id = "ORDER-001"),
  specimen = list(
    specimen_id = "SPECIMEN-001", specimen_type = "Example specimen",
    collection_datetime = as.POSIXct("2026-08-12 09:15:00", tz = "Europe/Berlin"),
    received_datetime = as.POSIXct("2026-08-12 10:05:00", tz = "Europe/Berlin"),
    condition = "Accepted according to user-supplied criteria"
  ),
  examination = list(
    name = "Example fluorescence assay", short_name = "Example assay",
    method = "User-configured fluorescence measurement workflow",
    intended_use = "Synthetic demonstration of the reporting infrastructure",
    assay_version = "1.0", analysis_pipeline_version = "1.0",
    qc_ruleset_version = "1.0", interpretation_ruleset_version = "1.0",
    instrument_id = "INSTRUMENT-001", instrument_name = "Example instrument",
    instrument_software = "1.0"
  ),
  result = list(
    value = 1.42, display_value = "1.42", unit = "a.u.",
    reference = "Configured lower category: <= 1.00",
    decision_limit = "Configured upper category: >= 2.00",
    classification = "INTERMEDIATE", qc_status = "PASS",
    comment = "Synthetic result for demonstration only.",
    thresholds = c(1, 2),
    threshold_labels = c("LOW", "INTERMEDIATE", "HIGH"),
    source = "manual", classification_source = "manual"
  ),
  interpretation = list(
    summary = "The measured value is within the configured intermediate category.",
    text = "This interpretation text was supplied explicitly for the synthetic example report.",
    recommendation = "Review the result according to the user-defined reporting workflow."
  ),
  limitations = c(
    "This is a fully synthetic example and does not describe a real subject or specimen.",
    "Decision limits and interpretation were supplied solely to demonstrate configurable report rendering."
  ),
  authorization = list(
    reviewed_by = "Example Reviewer", reviewer_role = "Reviewer",
    authorized_by = "Example Authorizer", authorizer_role = "Authorizer",
    electronic_release = "Electronic report release recorded for this synthetic example."
  ),
  custom_fields = list(
    "Requesting unit" = "Example department",
    "Project number" = "PROJECT-001",
    "Additional identifier" = "ADDITIONAL-001"
  )
)
qc <- cellreportR::cr_report_qc(
  criterion = c("Control criterion A", "Control criterion B",
                "Object count", "Run acceptance"),
  observed = c("Within configured range", "Within configured range",
               "250", "Accepted"),
  acceptance = c("User-configured criterion", "User-configured criterion",
                 ">= 100", "All selected criteria pass"),
  status = rep("PASS", 4), source = "synthetic example"
)
style <- cellreportR::cr_report_style(
  mode = "colour", density = "standard",
  footer_text = "Electronic release statement supplied for this synthetic example."
)
report <- cellreportR::cr_lab_report(
  spec = spec, qc = qc, result_graphic = TRUE, style = style
)
pdf_file <- file.path(out_dir, "EXAMPLE-001_v1.0_laboratory-report.pdf")
audit_file <- file.path(out_dir, "EXAMPLE-001_v1.0_audit.json")
cellreportR::cr_render_lab_report(
  report, pdf_file, audit_file = audit_file, overwrite = TRUE
)
invisible(c(pdf = pdf_file, audit = audit_file))
