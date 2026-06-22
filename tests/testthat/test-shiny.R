test_that("cr_run_app errors when optional packages are missing", {
  testthat::local_mocked_bindings(
    requireNamespace = function(...) FALSE,
    .package = "base"
  )
  expect_error(cr_run_app(), "additional packages")
})

test_that("cr_run_app launches with synthetic data when experiment is NULL", {
  launched <- new.env()
  testthat::local_mocked_bindings(
    requireNamespace = function(...) TRUE,
    .package = "base"
  )
  testthat::local_mocked_bindings(
    runApp = function(appDir, ...) {
      launched$dir <- appDir
      invisible(NULL)
    },
    .package = "shiny"
  )
  cr_run_app(launch_browser = FALSE)
  expect_true(nzchar(launched$dir))
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
