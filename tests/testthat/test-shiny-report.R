test_that("laboratory report state initializes blank or pre-populated", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), { expect_s3_class(state$report_spec,"cr_report_spec") })
  s<-cr_report_spec(report=list(report_id="EXAMPLE-001"),result=list(classification="HIGH"))
  shiny::testServer(cr_test_app(report_spec=s), { expect_equal(state$report_spec$report$report_id,"EXAMPLE-001") })
})

test_that("Shiny input mapping uses the programmatic constructor", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    session$setInputs(lab_title="Laboratory Report",lab_id="EXAMPLE-002",lab_version="1.0",lab_status="DRAFT",lab_created=as.Date("2026-01-01"),lab_result_source="manual",lab_value=1.42,lab_classification="HIGH",lab_qc_status="PASS",lab_custom_fields="Project | EXAMPLE\nAdditional identifier | VALUE",lab_limitations="First limitation\nSecond limitation",btn_lab_validate=1)
    expect_equal(state$report_spec$report$report_id,"EXAMPLE-002")
    expect_equal(state$report_spec$result$value,1.42)
    expect_equal(state$report_spec$custom_fields$Project,"EXAMPLE")
    expect_length(state$report_spec$limitations,2)
    expect_true(any(grepl("Report validated",state$log)))
    expect_false(any(grepl("EXAMPLE-002|First limitation",state$log)))
  })
})

test_that("existing analysis result source remains distinguishable", {
  skip_if_no_app();exp<-cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    state$effects<-data.frame(estimate=c(2.5,3.0));session$flushReact()
    session$setInputs(lab_title="Laboratory Report",lab_id="EXAMPLE-003",lab_version="1.0",lab_status="DRAFT",lab_created=as.Date("2026-01-01"),lab_result_source="analysis",lab_analysis_value="estimate",lab_classification="HIGH",btn_lab_validate=1)
    expect_equal(state$report_spec$result$value,2.5)
    expect_equal(state$report_spec$result$source,"analysis")
  })
})

test_that("custom and QC text editors reject malformed rows", {
  expect_error(cellreportR:::.cr_key_values("A | 1\nA | 2"),"unique")
  expect_error(cellreportR:::.cr_qc_text("criterion | observed | status"),"four")
})
