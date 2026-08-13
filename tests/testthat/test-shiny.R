test_that("cr_run_app errors when optional packages are missing", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  expect_error(cr_run_app(), "is required to run")
})

test_that("cr_run_app hands runApp an app object and lifts the upload limit", {
  skip_if_not_installed("bslib")
  skip_if_not_installed("DT")
  launched <- new.env()
  before <- getOption("shiny.maxRequestSize")
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      launched$app <- appDir
      launched$limit <- getOption("shiny.maxRequestSize")
      invisible(NULL)
    },
    .package = "shiny"
  )
  cr_run_app(launch_browser = FALSE, max_upload_mb = 8)
  expect_s3_class(launched$app, "shiny.appobj")
  expect_equal(launched$limit, 8 * 1024^2)
  # The option is restored once the app stops.
  expect_identical(getOption("shiny.maxRequestSize"), before)
})

test_that("cr_run_app rejects an invalid upload limit", {
  expect_error(cr_run_app(max_upload_mb = -1), "positive number")
  expect_error(cr_run_app(max_upload_mb = c(1, 2)), "positive number")
})

test_that("cr_run_app rejects an invalid experiment before launching", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) TRUE,
    .package = "base"
  )
  testthat::local_mocked_bindings(
    runApp = function(...) stop("should not be reached"),
    .package = "shiny"
  )
  expect_error(cr_run_app(list(bad = TRUE), launch_browser = FALSE),
               "cr_experiment")
})
