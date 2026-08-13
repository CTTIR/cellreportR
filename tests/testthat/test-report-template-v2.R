test_that("report styles and profiles remain presentation-only", {
  style <- cr_report_style(
    mode="grayscale",density="compact",locale="de",
    primary_colour="#315A70",labels=c(result="Befund"),
    show_signature_lines=TRUE)
  expect_s3_class(style,"cr_report_style")
  expect_error(cr_report_style(paper="Letter"),"A4")
  expect_error(cr_report_style(primary_colour="blue"),"six-digit")

  spec <- cr_test_lab_spec()
  original_value <- spec$result$value
  profile <- cr_report_profile(
    laboratory=list(name="Configured Example Laboratory"),style=style,
    labels=c(specimen_id="Sample ID"),default_title="Configured Report")
  spec$report$title <- "Laboratory Report"
  report <- cr_lab_report(spec=spec,qc=cr_test_lab_qc(),profile=profile)
  display <- cr_report_display_data(report)

  expect_equal(report$spec$result$value,original_value)
  expect_equal(report$spec$laboratory$name,"Example Laboratory")
  expect_equal(report$spec$report$title,"Configured Report")
  expect_equal(display$style$mode,"grayscale")
  expect_equal(display$labels[["result"]],"Befund")
  expect_equal(display$labels[["specimen_id"]],"Sample ID")
  expect_equal(display$report$created,"13.08.2026, 14:00")
  expect_equal(report$template_version,"2.0")
  expect_equal(report$spec$schema_version,"1.0")
})

test_that("display labels and LaTeX escaping are deliberate", {
  report <- cr_lab_report(spec=cr_test_lab_spec(),qc=cr_test_lab_qc())
  display <- cr_report_display_data(report)
  expect_equal(display$labels[["subject_id"]],"Subject ID")
  expect_equal(display$labels[["qc_ruleset_version"]],"QC Ruleset Version")
  expect_equal(display$labels[["instrument_id"]],"Instrument ID")
  expect_false(any(display$subject$value %in% c("NA","NULL","character(0)")))

  plain <- "A & B: 100% _ # $ { } \\ < > — äöü µ α"
  escaped <- cellreportR:::.cr_latex_escape(plain)
  expect_match(escaped,"\\\\&")
  expect_match(escaped,"\\\\%")
  expect_match(escaped,"textbackslash",fixed=TRUE)
  expect_match(escaped,"äöü µ α",fixed=TRUE)
})

test_that("template body has controlled report hierarchy", {
  report <- cr_lab_report(
    spec=cr_test_lab_spec(),qc=cr_test_lab_qc(),result_graphic=TRUE,
    style=cr_report_style(show_signature_lines=TRUE))
  display <- cr_report_display_data(report)
  body <- cellreportR:::.cr_report_latex_body(display)
  expect_lt(regexpr("\\\\crSection\\{Result\\}",body)[1],
            regexpr("\\\\crBeginSecondPage",body)[1])
  expect_gt(regexpr("Quality Control",body)[1],regexpr("\\\\crBeginSecondPage",body)[1])
  expect_gt(regexpr("Authorization and Release",body)[1],regexpr("Quality Control",body)[1])
  expect_match(body,"\\\\Needspace\\{11\\\\baselineskip\\}")
  expect_match(body,"\\\\crSignatureLines")
})

test_that("standard laboratory fixture renders as two clean A4 pages", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available())
  for (command in c("xelatex","pdfinfo","pdftotext")) {
    skip_if(!nzchar(Sys.which(command)),paste(command,"is unavailable"))
  }
  out <- withr::local_tempdir()
  pdf <- file.path(out,"EXAMPLE-001_v1.0_laboratory-report.pdf")
  audit <- file.path(out,"EXAMPLE-001_v1.0_audit.json")
  report <- cr_lab_report(
    spec=cr_test_lab_spec(),qc=cr_test_lab_qc(),result_graphic=TRUE,
    style=cr_report_style(mode="colour"))

  expect_silent(cr_render_lab_report(
    report,pdf,audit_file=audit,keep_tex=TRUE,overwrite=TRUE))
  info <- system2("pdfinfo",pdf,stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("Pages:\\s+2$",info)))
  expect_true(any(grepl("Page size:.*A4",info)))
  page1 <- system2("pdftotext",c("-f","1","-l","1","-layout",pdf,"-"),
                   stdout=TRUE,stderr=TRUE)
  page2 <- system2("pdftotext",c("-f","2","-l","2","-layout",pdf,"-"),
                   stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("INTERMEDIATE",page1,fixed=TRUE)))
  expect_true(any(grepl("Interpretation",page1,fixed=TRUE)))
  expect_true(any(grepl("Quality Control",page2,fixed=TRUE)))
  expect_true(any(grepl("Authorization and Release",page2,fixed=TRUE)))
  expect_true(any(grepl("Page 1 of 2",page1,fixed=TRUE)))
  expect_true(any(grepl("Page 2 of 2",page2,fixed=TRUE)))

  tex <- sub("\\.pdf$",".tex",pdf)
  expect_true(file.exists(tex))
  expect_true(file.exists(sub("\\.pdf$","_result-position.pdf",pdf)))
  old <- setwd(out); on.exit(setwd(old),add=TRUE)
  status <- system2("xelatex",c("-interaction=batchmode","-halt-on-error",basename(tex)),
                    stdout=FALSE,stderr=FALSE)
  expect_equal(status,0)
  log <- readLines(sub("\\.tex$",".log",tex),warn=FALSE)
  expect_false(any(grepl("Overfull \\hbox|Overfull \\vbox",log)))

  audit_data <- jsonlite::read_json(audit,simplifyVector=TRUE)
  expect_equal(audit_data$report$report_id,"EXAMPLE-001")
  expect_equal(audit_data$report$template_version,"2.0")
  expect_equal(audit_data$report$output_file_name,basename(pdf))
  expect_true(nzchar(audit_data$output_file_hash))
})
