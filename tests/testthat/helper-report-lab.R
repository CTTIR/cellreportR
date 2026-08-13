cr_test_lab_spec <- function(stress=FALSE) {
  long <- paste(rep("Synthetic user-supplied text for deterministic layout testing.",
                    if(stress) 14 else 1),collapse=" ")
  cr_report_spec(
    report=list(title="Laboratory Report",report_id=if(stress) paste0("EXAMPLE-",paste(rep("LONG",12),collapse="-")) else "EXAMPLE-001",version="1.0",status="DRAFT",created_at=as.POSIXct("2026-08-13 14:00:00",tz="Europe/Berlin")),
    laboratory=list(name=if(stress) "Example Laboratory with an Intentionally Long Synthetic Organization Name" else "Example Laboratory",department="Analytical Services",address="Example Street 1, 00000 Example City"),
    subject=list(subject_id="SUBJECT-ÄÖÜ-001",case_id="CASE-001",order_id="ORDER-001"),
    specimen=list(specimen_id="SPECIMEN-µ-001",specimen_type="Example specimen",collection_datetime=as.POSIXct("2026-08-12 09:15:00",tz="Europe/Berlin"),received_datetime=as.POSIXct("2026-08-12 10:05:00",tz="Europe/Berlin")),
    examination=list(name="Example fluorescence assay",method=long,assay_version="1.0",analysis_pipeline_version="1.0",qc_ruleset_version="1.0",interpretation_ruleset_version="1.0",instrument_id="INSTRUMENT-001",instrument_name="Example instrument"),
    result=list(value=1.42,unit="a.u.",classification="INTERMEDIATE",qc_status="PASS",thresholds=c(1,2),threshold_labels=c("LOW","INTERMEDIATE","HIGH")),
    interpretation=list(summary="The measured value is within the configured intermediate category.",text=long,recommendation="Review according to the user-defined workflow."),
    limitations=if(stress) paste("Synthetic limitation",seq_len(8),long) else c("Synthetic limitation one.","Synthetic limitation two."),
    authorization=list(reviewed_by="Example Reviewer",reviewer_role="Reviewer",authorized_by="Example Authorizer",authorizer_role="Authorizer",electronic_release="Synthetic electronic release statement."),
    custom_fields=if(stress) stats::setNames(as.list(paste("Value",seq_len(10),long)),paste("Field",seq_len(10))) else list("Requesting unit"="Example department","Project number"="PROJECT-001")
  )
}

cr_test_lab_qc <- function(n=4L) cr_report_qc(
  paste("Criterion",seq_len(n)),paste("Observed",seq_len(n)),
  rep("Configured acceptance",n),rep(c("PASS","WARN"),length.out=n),
  "synthetic fixture")
