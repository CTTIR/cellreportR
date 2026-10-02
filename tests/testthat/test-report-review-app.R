.review_fixture <- function(claim_count = 2L, figures = TRUE) {
  root <- withr::local_tempdir(.local_envir = parent.frame())
  writeLines(c("id,value", "a,1.25", "b,<unsafe>"), file.path(root, "results.csv"))
  writeBin(charToRaw("%PDF-1.4\nanonymous signature fixture"), file.path(root, "figure.pdf"))
  claims <- stats::setNames(lapply(seq_len(claim_count), function(i) {
    list(table = "results", key = c(id = if (i %% 2) "a" else "b"), column = "value")
  }), if (claim_count) paste0("claim_", seq_len(claim_count)) else character())
  evidence <- cr_report_evidence(root,
    tables = list(results = list(path = "results.csv", format = "csv", key = "id")),
    claims = claims,
    figures = if (figures) list(panel = list(path = "figure.pdf", tables = "results")) else list()
  )
  spec <- cr_report_spec(
    report = list(report_id = "example", title = "Example report"),
    result = list(display_value = "Quoted source values"),
    authorization = list(authorized_by = "Example authority"),
    limitations = "Source identity is not scientific validation."
  )
  list(root = root, report = cr_lab_report_from_evidence(evidence, root, spec))
}

test_that("review capture is detached and rejects unsupported mutable payloads", {
  skip_if_not_installed("bslib")
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  f$report$spec$custom_fields$claim_1 <- "changed"
  expect_identical(.cr_review_preview(ctx)$claims$display, c("1.25", "<unsafe>"))
  z <- ctx
  z$report$include_audit_appendix <- !z$report$include_audit_appendix
  expect_error(.cr_review_validate(z))
  for (field in c("experiment", "result_graphic")) {
    z <- ctx$report
    z[[field]] <- list(value = 1)
    expect_error(.cr_review_capture(z), "no experiment")
  }
  z <- ctx$report
  z$style$logo <- "outside.png"
  expect_error(.cr_review_capture(z), "logos")
  z <- ctx$report
  z$extra <- new.env()
  expect_error(.cr_review_capture(z), "mutable")
  z <- ctx$report
  con <- file(tempfile(), "w")
  on.exit(close(con), add = TRUE)
  z$extra <- con
  expect_error(.cr_review_capture(z), "mutable")
  z <- ctx$report
  z$evidence <- NULL
  expect_error(.cr_review_capture(z))
  z <- ctx$report
  z$spec$custom_fields$claim_1 <- "mismatch"
  expect_error(.cr_review_capture(z))
  expect_s3_class(cr_report_review_app(ctx$report), "shiny.appobj")
})

test_that("staged exports refuse changed sources and remove incomplete output", {
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  dest <- tempfile()
  # A local function clone isolates the mock renderer without namespace mutation.
  stage <- .cr_review_stage
  environment(stage) <- list2env(list(.cr_review_render = function(report, format, path) {
    writeLines(format, path)
  }), parent = environment(stage))
  for (format in c("html", "pdf", "audit", "spec")) {
    stage(ctx, format, dest)
    expect_true(file.exists(dest))
    unlink(dest)
  }
  stage(ctx, "figure", dest, "panel")
  expect_identical(readBin(dest, "raw", 5), charToRaw("%PDF-"))
  unlink(dest)
  expect_error(stage(ctx, "figure", dest, "../secret"), "no download")
  expect_false(file.exists(dest))
  writeLines("changed", file.path(f$root, "results.csv"))
  expect_error(.cr_review_preview(ctx))
  for (format in c("html", "pdf", "audit", "spec", "figure")) {
    expect_error(stage(ctx, format, dest, "panel"), "no download")
    expect_false(file.exists(dest))
  }
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  before <- list.files(tempdir(), pattern = "^cr_review_", full.names = TRUE)
  environment(stage)$.cr_review_render <- function(report, format, path) {
    writeLines("incomplete", path)
    writeLines("changed", file.path(f$root, "results.csv"))
  }
  expect_error(stage(ctx, "html", dest), "no download")
  expect_false(file.exists(dest))
  expect_identical(list.files(tempdir(), pattern = "^cr_review_", full.names = TRUE), before)
})

test_that("figures bind declared extension and stay inside a relocated source root", {
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  other <- withr::local_tempdir()
  file.copy(list.files(f$root, full.names = TRUE), other)
  expect_identical(.cr_review_capture(f$report, other)$report$evidence$sha256, f$report$evidence$sha256)
  writeLines("<html>wrong", file.path(f$root, "figure.pdf"))
  expect_error(.cr_review_figure(ctx, "panel"), "signature")
  skip_on_os("windows")
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  target <- file.path(f$root, "actual.png")
  writeBin(as.raw(c(137, 80, 78, 71, 13, 10, 26, 10)), target)
  unlink(file.path(f$root, "figure.pdf"))
  expect_true(file.symlink(target, file.path(f$root, "figure.pdf")))
  expect_error(.cr_review_figure(ctx, "panel"), "signature")
  unlink(file.path(f$root, "figure.pdf"))
  outside <- tempfile()
  writeBin(charToRaw("%PDF-1.4"), outside)
  withr::defer(unlink(outside))
  expect_true(file.symlink(outside, file.path(f$root, "figure.pdf")))
  expect_error(.cr_review_capture(f$report), "within root")
})

test_that("review UI escapes claims and validates direct downloads independently", {
  skip_if_not_installed("bslib")
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  shiny::testServer(function(input, output, session) .cr_review_server(input, output, session, ctx), {
    session$setInputs(refresh = 1)
    expect_match(output$claims$html, "claim_1")
    expect_match(output$claims$html, "&lt;unsafe&gt;")
    expect_match(output$claims$html, "<details>")
    expect_match(output$claims$html, "Source SHA-256")
    expect_match(output$preview$html, "Source identity is not scientific validation")
    expect_false(grepl("Page X of Y", output$preview$html, fixed = TRUE))
    expect_false(grepl(f$root, output$sources$html, fixed = TRUE))
    payload <- jsonlite::read_json(output$report_spec)
    expect_identical(payload$custom_fields, ctx$report$spec$custom_fields)
    session$setInputs(evidence_root = "/ignored", lab_value = 999)
    expect_match(output$claims$html, "1.25", fixed = TRUE)
    writeLines("changed", file.path(f$root, "results.csv"))
    session$setInputs(refresh = 2)
    expect_match(output$preview$html, "validation failed")
    expect_error(output$report_pdf, "no download")
    expect_error(output$figure_1, "no download")
  })
  expect_false(any(vapply(shiny::resourcePaths(), function(path) startsWith(path, f$root), logical(1))))
})

test_that("empty claims and figures are explicit and default editable pagination is preserved", {
  skip_if_not_installed("bslib")
  f <- .review_fixture(0, FALSE)
  ctx <- .cr_review_capture(f$report)
  d <- cr_report_display_data(f$report)
  expect_identical(as.character(.cr_report_preview_ui(d)), as.character(.cr_report_preview_ui(d, TRUE)))
  expect_match(as.character(.cr_report_preview_ui(d)), "Page X of Y", fixed = TRUE)
  expect_false(grepl("Page X of Y", as.character(.cr_report_preview_ui(d, FALSE)), fixed = TRUE))
  shiny::testServer(function(input, output, session) .cr_review_server(input, output, session, ctx), {
    session$setInputs(refresh = 1)
    expect_match(output$claims$html, "No source-bound claims")
    expect_match(output$figures$html, "No declared figures")
  })
  expect_error(cr_report_evidence(f$root, tables = list()))
})

test_that("real reviewer HTML and PDF exports preserve an anonymous report", {
  # Required explicitly by the release qualification job; ordinary checks may
  # omit a system TeX installation. This is a real renderer, not a mock.
  if (!identical(Sys.getenv("CELLREPORTR_REQUIRE_REVIEWER_RENDER"), "true")) {
    skip("Set CELLREPORTR_REQUIRE_REVIEWER_RENDER=true for the required render gate")
  }
  expect_true(requireNamespace("rmarkdown", quietly = TRUE))
  withr::local_options(list(tinytex.install_packages = FALSE))
  f <- .review_fixture()
  ctx <- .cr_review_capture(f$report)
  directory <- withr::local_tempdir()
  html <- file.path(directory, "report.html")
  pdf <- file.path(directory, "report.pdf")
  .cr_review_stage(ctx, "html", html)
  .cr_review_stage(ctx, "pdf", pdf)
  expect_match(paste(readLines(html, warn = FALSE), collapse = "\n"), "Example report")
  expect_identical(readBin(pdf, "raw", 5), charToRaw("%PDF-"))
  expect_gt(file.info(pdf)$size, 1000)
})

test_that("trusted markup and unsupported classes cannot bypass literal review", {
  f <- .review_fixture()
  markup <- shiny::HTML('<img src="invalid" onerror="window.reviewInjection=1">')
  for (field in c("title", "limitations")) {
    report <- f$report
    if (field == "title") report$spec$report$title <- markup else report$spec$limitations <- markup
    expect_error(.cr_review_capture(report), "Unsupported mutable")
  }
  report <- f$report
  report$extra <- list(nested = shiny::tags$script("window.reviewInjection=1"))
  expect_error(.cr_review_capture(report), "Unsupported mutable")
  report <- f$report
  attr(report$spec$report$title, "extra") <- markup
  expect_error(.cr_review_capture(report), "Unsupported mutable")
  report <- f$report
  report$spec$report$title <- structure("literal", class = "custom_markup")
  expect_error(.cr_review_capture(report), "Unsupported mutable")
  report <- f$report
  report$extra <- list(
    date = as.Date("2026-01-02"),
    instant = as.POSIXct("2026-01-02", tz = "UTC"),
    local_time = as.POSIXlt("2026-01-02", tz = "UTC"),
    category = factor(c("a", "b")), rank = ordered(c("low", "high"))
  )
  expect_true(.cr_review_plain(report))
  expect_silent(.cr_review_capture(report))
})
