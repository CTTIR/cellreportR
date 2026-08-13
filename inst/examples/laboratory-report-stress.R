# Manual pagination/Unicode stress fixture for laboratory-report template 2.0.
out_dir <- Sys.getenv("CELLREPORTR_EXAMPLE_DIR", unset = tempdir())
dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)

long_text <- paste(rep(
  "Synthetic user-supplied text checks wrapping, spacing, and controlled page flow without adding scientific meaning.",
  8), collapse = " ")
spec <- cellreportR::cr_report_spec(
  report = list(
    title = "Laboratory Report with Extended Synthetic Content",
    report_id = paste0("EXAMPLE-LONG-", paste(rep("IDENTIFIER", 6), collapse = "-")),
    version = "2.0", status = "DRAFT"
  ),
  laboratory = list(
    name = "Example Laboratory with an Intentionally Long Organization Name",
    department = "Analytical Services and Controlled Documentation",
    address = "Example Street 123, 00000 Example City, Example Region"
  ),
  subject = list(subject_id = "SUBJECT-UNICODE-ÄÖÜ-001", case_id = "CASE-001"),
  specimen = list(specimen_id = "SPECIMEN-µ-001", specimen_type = "Example specimen"),
  examination = list(
    name = "Example assay with a deliberately long descriptive examination name",
    method = long_text, analysis_pipeline_version = "PIPELINE-1.0",
    qc_ruleset_version = "QC-1.0", interpretation_ruleset_version = "INT-1.0",
    instrument_id = paste(rep("INSTRUMENT", 5), collapse = "-")
  ),
  result = list(value = 2.5, unit = "a.u.", classification = "CATEGORY Ä",
                qc_status = "WARN", thresholds = c(1, 2),
                threshold_labels = c("LOW", "INTERMEDIATE", "UPPER")),
  interpretation = list(summary = "Synthetic Unicode summary: ä ö ü Ä Ö Ü ß µ α β γ.",
                        text = long_text, recommendation = long_text),
  limitations = paste("Synthetic limitation", seq_len(8), "—", long_text),
  authorization = list(reviewed_by = "Example Reviewer Ä",
                       authorized_by = "Example Authorizer Ö",
                       electronic_release = long_text),
  custom_fields = stats::setNames(as.list(paste("Extended synthetic value", seq_len(12), long_text)),
                                  paste("Additional field", seq_len(12)))
)
qc <- cellreportR::cr_report_qc(
  paste("Criterion",seq_len(10)),paste("Observed",seq_len(10)),
  rep("User-configured acceptance statement",10),
  rep(c("PASS","WARN"),5),"synthetic stress fixture"
)
report <- cellreportR::cr_lab_report(
  spec=spec,qc=qc,result_graphic=TRUE,
  style=cellreportR::cr_report_style(mode="grayscale",density="compact")
)
cellreportR::cr_render_lab_report(
  report,file.path(out_dir,"EXAMPLE-STRESS_laboratory-report.pdf"),overwrite=TRUE
)
