test_that("report specifications provide empty defaults and complete values", {
  empty <- cr_report_spec()
  expect_s3_class(empty,"cr_report_spec")
  expect_equal(empty$schema_name,"cellreportR-report-spec")
  expect_equal(empty$report$status,"DRAFT")
  complete <- cr_report_spec(report=list(report_id="EXAMPLE-001",version="1.2",status="FINAL",released_at=Sys.time()),result=list(value=1.42,classification="HIGH"),authorization=list(authorized_by="Example Reviewer"),custom_fields=list("Project"="EXAMPLE"),custom_sections=list(list(title="Additional information",fields=list("Field A"="Value A"))))
  expect_invisible(cr_validate_report_spec(complete))
})

test_that("report specification rejects malformed content", {
  expect_error(cr_report_spec(result="bad"),"sections must be lists")
  expect_error(cr_report_spec(report=list(status="UNKNOWN")),"Status")
  expect_error(cr_report_spec(report=list(version="draft")),"Version")
  expect_error(cr_report_spec(custom_fields=structure(list("a","b"),names=c("x","x"))),"unique")
  expect_error(cr_report_spec(custom_sections=list(list(title="x"))),"named fields")
})

test_that("strict validation is configurable and severity coded", {
  s <- cr_report_spec(required_fields="specimen.specimen_id")
  issues <- cr_validate_report_spec(s,strict=FALSE,return_issues=TRUE)
  expect_true(any(issues$severity=="WARNING"))
  expect_error(cr_validate_report_spec(s,strict=TRUE),"Report ID")
  amended <- cr_report_spec(report=list(report_id="X",status="AMENDED"),result=list(classification="HIGH"))
  expect_error(cr_validate_report_spec(amended,strict=TRUE),"superseded")
})

test_that("classification boundaries and finalization are explicit", {
  expect_equal(cr_classify_result(c(-Inf,NA,0,1,1.5,2,Inf),1,2),c(NA,NA,"NEGATIVE","NEGATIVE","INDETERMINATE","POSITIVE",NA))
  expect_equal(cr_classify_result(c(1,2),1,2,c(negative="LOW",indeterminate="MID",positive="HIGH")),c("LOW","HIGH"))
  expect_error(cr_classify_result(1,2,1),"satisfy")
  expect_equal(cr_finalize_result(c("HIGH","LOW"),c("FAIL","PASS")),c("INVALID","LOW"))
  expect_equal(cr_finalize_result("HIGH","FAIL",invalidate=FALSE),"HIGH")
})

test_that("interpretation lookup never invents text", {
  d <- c(LOW="The measured value is within the configured lower category.",HIGH="The measured value is within the configured upper category.")
  expect_equal(cr_interpretation_lookup(c("LOW","OTHER",NA),d),c(d[[1]],NA,NA))
  expect_error(cr_interpretation_lookup("LOW",c("text")),"names")
})

test_that("report QC tables are generic and validated", {
  q <- cr_report_qc(c("Criterion A","Criterion B"),c("10","20"),c("configured range","configured range"),c("PASS","PASS"))
  expect_invisible(cr_validate_report_qc(q))
  expect_error(cr_validate_report_qc(data.frame(x=1)),"missing")
  exp <- cr_example_experiment(seed=1,n_cells_per_well=2)
  expect_s3_class(cr_report_qc_from_log(exp),"tbl_df")
})

test_that("report print omits sensitive field contents", {
  s <- cr_report_spec(report=list(report_id="EXAMPLE-001"),subject=list(name="Confidential Name"),result=list(classification="HIGH"))
  out <- capture.output(print(s))
  expect_false(any(grepl("Confidential",out)))
  expect_true(any(grepl("EXAMPLE-001",out)))
})
