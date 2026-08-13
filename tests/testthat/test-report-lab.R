.example_lab_spec <- function() cr_report_spec(
  report=list(report_id="EXAMPLE-001",version="1.0",status="DRAFT"),
  laboratory=list(name="Example Laboratory"),subject=list(subject_id="SUBJECT-001"),
  specimen=list(specimen_id="SPECIMEN-001",specimen_type="Example specimen"),
  examination=list(name="Example fluorescence assay",assay_version="1.0"),
  result=list(value=1.42,unit="a.u.",classification="HIGH",qc_status="PASS",source="manual"),
  interpretation=list(summary="The result falls within the configured upper category.",text="Interpretation text supplied by the user."),
  limitations="Example limitation supplied by the user.",authorization=list(reviewed_by="Example Reviewer",authorized_by="Example Authorizer")
)

test_that("laboratory report data is inspectable and assembly is side-effect safe", {
  exp<-cr_example_experiment(seed=42,n_cells_per_well=2); before<-serialize(exp,NULL)
  r<-cr_lab_report(exp,.example_lab_spec(),cr_report_qc("Run acceptance","met","configured criteria","PASS"))
  expect_s3_class(r,"cr_lab_report"); expect_identical(serialize(exp,NULL),before)
  dat<-cr_report_data(r); expect_equal(dat$template_version,"2.0"); expect_equal(dat$spec$result$value,1.42)
})

test_that("structured report hashes are stable and sensitive to data", {
  s1<-.example_lab_spec(); s2<-s1
  expect_identical(cr_report_hash(s1),cr_report_hash(s2))
  s2$result$value<-1.43; expect_false(identical(cr_report_hash(s1),cr_report_hash(s2)))
})

test_that("provenance is concise and versioned", {
  exp<-cr_example_experiment(seed=42,n_cells_per_well=2); r<-cr_lab_report(exp,.example_lab_spec())
  p<-cr_report_provenance(exp,r)
  expect_equal(p$schema_version,"1.0"); expect_equal(p$software$package,"cellreportR")
  expect_equal(p$report$template_version,"2.0"); expect_equal(p$experiment$n_cells,nrow(exp$cells))
  expect_null(p$experiment$cells)
})

test_that("JSON specification and audit round trip", {
  s<-.example_lab_spec(); f<-withr::local_tempfile(fileext=".json")
  cr_export_report_spec(s,f); z<-suppressWarnings(cr_import_report_spec(f)); expect_s3_class(z,"cr_report_spec"); expect_equal(z$report$report_id,"EXAMPLE-001")
  r<-cr_lab_report(NULL,s); a<-withr::local_tempfile(fileext=".json"); cr_export_report_audit(r,a)
  x<-jsonlite::read_json(a,simplifyVector=TRUE); expect_equal(x$schema,"cellreportR-report-audit"); expect_equal(x$report$report_id,"EXAMPLE-001")
})

test_that("result-position plot requires explicit thresholds", {
  p<-cr_plot_result_position(1.42,c(1,2),c("LOW","INTERMEDIATE","HIGH")); expect_s3_class(p,"ggplot")
  expect_error(cr_plot_result_position(1,c(2,1)),"increasing")
  expect_error(cr_plot_result_position(1,c(1,2),"one"),"one label")
})

test_that("special characters and Unicode remain structured safely", {
  s<-.example_lab_spec(); s$interpretation$text<-"A & B: 100% _ # $ { } \\\\ < > — äöü"
  r<-cr_lab_report(NULL,s); expect_equal(cr_report_data(r)$spec$interpretation$text,s$interpretation$text)
  escaped<-cellreportR:::.cr_markdown_escape(s$interpretation$text); expect_match(escaped,"\\\\&")
})

test_that("laboratory HTML rendering consumes finalized objects", {
  skip_on_cran(); skip_if_not_installed("rmarkdown"); skip_if_not_installed("knitr"); skip_if_not(rmarkdown::pandoc_available())
  r<-cr_lab_report(NULL,.example_lab_spec()); f<-withr::local_tempfile(fileext=".html")
  expect_silent(cr_render_lab_report(r,f)); expect_true(file.exists(f))
})
