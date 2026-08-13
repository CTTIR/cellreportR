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

  colour_report <- cr_lab_report(
    spec=cr_test_lab_spec(),qc=cr_test_lab_qc(),result_graphic=TRUE,
    style=cr_report_style(primary_colour="#315A70"))
  expect_equal(colour_report$result_graphic$layers[[3L]]$aes_params$fill,
               "#315A70")
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
  expect_match(body,"\\\\begin\\{crresult\\}")
  expect_match(body,"\\\\crSignatureLines")
  expect_match(body,"Instrument ID")
  expect_match(body,"Reviewed by")
  expect_match(body,"Authorized by")
  expect_lt(regexpr("\\\\vfill",body)[1],
            regexpr("Authorization and Release",body)[1])
  expect_match(body,"\\\\begin\\{minipage\\}\\[t\\]\\{0.485\\\\linewidth\\}")
})

test_that("document-control status and traceability have one display model", {
  spec <- cr_test_lab_spec()
  spec$report$status <- "FINAL"
  spec$authorization$released_at <- as.POSIXct(
    "2026-08-13 15:32:00", tz="Europe/Berlin")
  final <- cr_lab_report(spec=spec,qc=cr_test_lab_qc())
  final_display <- cr_report_display_data(final)
  expect_equal(final_display$report$control_date_key,"released_at")
  expect_equal(final_display$report$control_date,"13 Aug 2026, 15:32")
  expect_equal(final_display$traceability$value[
    final_display$traceability$key=="instrument_name"],"Example instrument")
  expect_equal(final_display$traceability$value[
    final_display$traceability$key=="instrument_id"],"INSTRUMENT-001")
  expect_equal(final_display$traceability$label[
    final_display$traceability$key=="analysis_pipeline_version"],
    "Pipeline Version")

  amended_spec <- spec
  amended_spec$report$status <- "AMENDED"
  amended_spec$report$version <- "1.1"
  amended_spec$report$supersedes_report_id <- "EXAMPLE-001 v1.0"
  amended_spec$report$amendment_reason <- "Synthetic correction record."
  amended <- cr_lab_report(spec=amended_spec,qc=cr_test_lab_qc())
  amended_display <- cr_report_display_data(amended)
  header <- cellreportR:::.cr_report_latex_header(amended_display)
  expect_true(any(header=="\\cramendedtrue"))
  expect_true(any(grepl("Synthetic correction record",header,fixed=TRUE)))
  expect_equal(amended_display$tokens$status,"#7A332E")

  cancelled_spec <- spec
  cancelled_spec$report$status <- "CANCELLED"
  cancelled <- cr_lab_report(
    spec=cancelled_spec,qc=cr_test_lab_qc(),strict=TRUE)
  expect_equal(cr_report_display_data(cancelled)$tokens$status,"#7A332E")
})

test_that("optional report sections collapse without empty headings", {
  spec <- cr_test_lab_spec()
  spec$interpretation$recommendation <- NULL
  spec$limitations <- character()
  spec$custom_fields <- list()
  spec$authorization <- list()
  report <- suppressWarnings(cr_lab_report(
    spec=spec,qc=cr_test_lab_qc(),strict=TRUE))
  body <- cellreportR:::.cr_report_latex_body(
    cr_report_display_data(report))
  expect_false(grepl("Recommendation",body,fixed=TRUE))
  expect_false(grepl("\\crSection{Limitations}",body,fixed=TRUE))
  expect_false(grepl("Additional Information",body,fixed=TRUE))
  expect_false(grepl("Authorization and Release",body,fixed=TRUE))

  spec <- cr_test_lab_spec()
  spec$authorization$authorized_by <- NULL
  spec$authorization$authorizer_role <- NULL
  one_party <- cellreportR:::.cr_report_latex_body(cr_report_display_data(
    suppressWarnings(cr_lab_report(
      spec=spec,qc=cr_test_lab_qc(),strict=TRUE))))
  expect_match(one_party,"Reviewed by")
  expect_false(grepl("Example Authorizer",one_party,fixed=TRUE))
})

test_that("standard laboratory fixture renders as two clean A4 pages", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available())
  for (command in c("xelatex","pdfinfo","pdftotext","pdffonts")) {
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
  expect_true(any(grepl("Title:.*Laboratory Report.*EXAMPLE-001",info)))
  expect_true(any(grepl("Author:.*Example Laboratory",info)))
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
  for (page in list(page1,page2)) {
    expect_true(any(grepl("EXAMPLE-001",page,fixed=TRUE)))
    expect_true(any(grepl("1.0",page,fixed=TRUE)))
    expect_true(any(grepl("DRAFT",page,fixed=TRUE)))
  }
  expect_equal(sum(grepl("LABORATORY REPORT",toupper(page1),fixed=TRUE)),1L)

  tex <- sub("\\.pdf$",".tex",pdf)
  expect_true(file.exists(tex))
  expect_true(file.exists(sub("\\.pdf$","_result-position.pdf",pdf)))
  old <- setwd(out); on.exit(setwd(old),add=TRUE)
  status <- system2("xelatex",c("-interaction=batchmode","-halt-on-error",basename(tex)),
                    stdout=FALSE,stderr=FALSE)
  expect_equal(status,0)
  log <- readLines(sub("\\.tex$",".log",tex),warn=FALSE)
  expect_false(any(grepl("Overfull \\hbox|Overfull \\vbox",log)))
  fonts <- system2("pdffonts",pdf,stdout=TRUE,stderr=TRUE)
  font_rows <- fonts[grepl(" yes ",fonts,fixed=TRUE)]
  expect_gt(length(font_rows),0L)
  expect_true(all(grepl("yes\\s+(yes|no)\\s+(yes|no)\\s+[0-9]+\\s+[0-9]+$",
                        font_rows)))

  audit_data <- jsonlite::read_json(audit,simplifyVector=TRUE)
  expect_equal(audit_data$report$report_id,"EXAMPLE-001")
  expect_equal(audit_data$report$template_version,"2.0")
  expect_equal(audit_data$report$output_file_name,basename(pdf))
  expect_true(nzchar(audit_data$output_file_hash))

  gray_pdf <- file.path(out,"EXAMPLE-001_v1.0_grayscale.pdf")
  gray_report <- cr_lab_report(
    spec=cr_test_lab_spec(),qc=cr_test_lab_qc(),result_graphic=TRUE,
    style=cr_report_style(mode="grayscale"))
  expect_silent(cr_render_lab_report(gray_report,gray_pdf,overwrite=TRUE))
  gray_info <- system2("pdfinfo",gray_pdf,stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("Pages:\\s+2$",gray_info)))
  gray_text <- system2("pdftotext",c("-layout",gray_pdf,"-"),
                       stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("INTERMEDIATE",gray_text,fixed=TRUE)))
  expect_true(any(grepl("PASS",gray_text,fixed=TRUE)))

  final_spec <- cr_test_lab_spec()
  final_spec$report$status <- "FINAL"
  final_spec$authorization$released_at <- as.POSIXct(
    "2026-08-13 15:32:00",tz="Europe/Berlin")
  final_pdf <- file.path(out,"EXAMPLE-001_v1.0_FINAL.pdf")
  expect_silent(cr_render_lab_report(
    cr_lab_report(spec=final_spec,qc=cr_test_lab_qc()),final_pdf,
    overwrite=TRUE))
  final_text <- system2("pdftotext",c("-layout",final_pdf,"-"),
                        stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("FINAL",final_text,fixed=TRUE)))
  expect_false(any(grepl("DRAFT",final_text,fixed=TRUE)))
  expect_true(any(grepl("Released",final_text,fixed=TRUE)))

  amended_spec <- final_spec
  amended_spec$report$status <- "AMENDED"
  amended_spec$report$version <- "1.1"
  amended_spec$report$supersedes_report_id <- "EXAMPLE-001 v1.0"
  amended_spec$report$amendment_reason <- "Synthetic correction record."
  amended_pdf <- file.path(out,"EXAMPLE-001_v1.1_AMENDED.pdf")
  expect_silent(cr_render_lab_report(
    cr_lab_report(spec=amended_spec,qc=cr_test_lab_qc()),amended_pdf,
    overwrite=TRUE))
  amended_info <- system2("pdfinfo",amended_pdf,stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("Pages:\\s+2$",amended_info)))
  amended_page1 <- system2(
    "pdftotext",c("-f","1","-l","1","-layout",amended_pdf,"-"),
    stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("AMENDED",amended_page1,fixed=TRUE)))
  expect_true(any(grepl("EXAMPLE-001 v1.0",amended_page1,fixed=TRUE)))
  expect_true(any(grepl("Synthetic correction record",amended_page1,fixed=TRUE)))
})

test_that("long optional content flows without clipped TeX boxes", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available())
  for (command in c("xelatex","pdfinfo","pdftotext")) {
    skip_if(!nzchar(Sys.which(command)),paste(command,"is unavailable"))
  }
  spec <- cr_test_lab_spec()
  spec$interpretation$text <- paste(rep(
    "Synthetic user-supplied narrative for document-flow testing.",24L),
    collapse=" ")
  spec$limitations <- paste(
    "Synthetic user-supplied limitation",seq_len(8L),
    "for pagination testing.")
  spec$custom_fields <- stats::setNames(
    as.list(paste("Synthetic value",seq_len(10L))),
    paste("Additional field",seq_len(10L)))
  qc <- cr_report_qc(
    criterion=paste("Criterion",seq_len(12L)),
    observed=paste("Observed",seq_len(12L)),
    acceptance=rep("User-configured acceptance text",12L),
    status=rep(c("PASS","WARN"),6L))
  out <- withr::local_tempdir()
  pdf <- file.path(out,"stress-report.pdf")
  expect_silent(cr_render_lab_report(
    cr_lab_report(spec=spec,qc=qc,strict=TRUE),pdf,
    keep_tex=TRUE,overwrite=TRUE))
  info <- system2("pdfinfo",pdf,stdout=TRUE,stderr=TRUE)
  pages <- as.integer(sub("Pages:\\s+","",grep("^Pages:",info,value=TRUE)))
  expect_gte(pages,2L)
  last_page <- system2(
    "pdftotext",c("-f",pages,"-l",pages,"-layout",pdf,"-"),
    stdout=TRUE,stderr=TRUE)
  expect_true(any(grepl("Authorization and Release",last_page,fixed=TRUE)))
  tex <- sub("\\.pdf$",".tex",pdf)
  old <- setwd(out); on.exit(setwd(old),add=TRUE)
  status <- system2("xelatex",c("-interaction=batchmode","-halt-on-error",
                                basename(tex)),stdout=FALSE,stderr=FALSE)
  expect_equal(status,0)
  log <- readLines(sub("\\.tex$",".log",tex),warn=FALSE)
  expect_false(any(grepl("Overfull \\hbox|Overfull \\vbox",log)))
})
