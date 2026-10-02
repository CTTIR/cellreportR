test_that("only the default laboratory HTML selects offline embedded output", {
  skip_if_not_installed("rmarkdown")
  report <- cr_lab_report(spec = cr_test_lab_spec())
  seen <- list()
  local_mocked_bindings(
    html_document = function(...) {
      seen$options <<- list(...)
      structure(list(), class = "offline-format-probe")
    },
    render = function(input, output_format, output_file, output_dir, ...) {
      seen$format <<- output_format
      out <- file.path(output_dir, output_file)
      writeLines("probe", out)
      out
    }, .package = "rmarkdown"
  )
  dir <- withr::local_tempdir()
  cr_render_lab_report(report, file.path(dir, "default.html"))
  expect_true("mathjax" %in% names(seen$options))
  expect_null(seen$options$mathjax)
  expect_identical(seen$options$self_contained, TRUE)
  expect_true(file.exists(seen$options$css))
  expect_s3_class(seen$format, "offline-format-probe")
  css <- paste(readLines(seen$options$css), collapse = "\n")
  expect_match(css, "overflow-wrap: anywhere", fixed = TRUE)
  expect_match(css, "word-break: normal", fixed = TRUE)
  expect_match(css, "td:first-child:nth-last-child(2)", fixed = TRUE)
  expect_match(css, "min-width: 7em", fixed = TRUE)

  custom <- file.path(dir, "custom.Rmd")
  writeLines(c("---", "output: html_document", "---", "Custom"), custom)
  seen$options <- NULL
  cr_render_lab_report(report, file.path(dir, "custom.html"), template = custom)
  expect_identical(seen$format, "html_document")
  expect_null(seen$options)
  cr_render_lab_report(report, file.path(dir, "custom.pdf"), template = custom)
  expect_identical(seen$format, "pdf_document")
  expect_null(seen$options)
})

test_that("default PDF retains its controlled renderer", {
  report <- cr_lab_report(spec = cr_test_lab_spec())
  called <- FALSE
  local_mocked_bindings(.cr_render_lab_pdf = function(...) {
    called <<- TRUE
  }, .package = "cellreportR")
  cr_render_lab_report(report, withr::local_tempfile(fileext = ".pdf"))
  expect_true(called)
})

test_that("default HTML embeds wrapping CSS without a dynamic math dependency", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available())
  report <- cr_lab_report(spec = cr_test_lab_spec())
  out <- withr::local_tempfile(fileext = ".html")
  cr_render_lab_report(report, out)
  text <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_false(grepl("mathjax.rstudio.com|MathJax.js", text))
  expect_match(text, "overflow-wrap: anywhere", fixed = TRUE)
  expect_match(text, "word-break: normal", fixed = TRUE)
})
