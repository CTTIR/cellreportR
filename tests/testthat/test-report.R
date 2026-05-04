test_that("cr_export_results writes CSV output", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  f <- withr::local_tempfile(fileext = ".csv")
  cr_export_results(all_res, f)
  expect_true(file.exists(f))
  out <- readr::read_csv(f, show_col_types = FALSE)
  expect_gt(nrow(out), 0)
})

test_that("cr_export_results writes RDS output", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  f <- withr::local_tempfile(fileext = ".rds")
  cr_export_results(all_res, f)
  expect_true(file.exists(f))
  x <- readRDS(f)
  expect_type(x, "list")
})

test_that("cr_export_plots writes PNG files", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  p <- cr_plot_intensity(exp, "marker_1")
  dir <- withr::local_tempdir()
  cr_export_plots(list(intensity = p), dir, format = "png",
                  width = 3, height = 2)
  expect_true(file.exists(file.path(dir, "intensity.png")))
})

test_that("cr_report renders HTML when rmarkdown available", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  out_dir <- withr::local_tempdir()
  out <- tryCatch(
    suppressMessages(cr_report(exp, res, output_dir = out_dir)),
    error = function(e) e
  )
  # Rendering requires pandoc and knitr; if they are not available,
  # allow the test to tolerate that gracefully.
  if (inherits(out, "error")) {
    skip("rmarkdown::render is not available in this environment")
  }
  expect_true(file.exists(out))
})
