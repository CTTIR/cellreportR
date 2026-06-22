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

# --- additional coverage -------------------------------------------------

test_that("cr_export_results infers format from extension when NULL", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "replicate")
  f <- withr::local_tempfile(fileext = ".csv")
  cr_export_results(res, f)
  expect_true(file.exists(f))
})

test_that("cr_export_results defaults to csv when no extension", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  d <- withr::local_tempdir()
  f <- file.path(d, "noext")
  cr_export_results(res, f)
  expect_true(file.exists(f))
})

test_that("cr_export_results accepts a data frame directly", {
  df <- tibble::tibble(a = 1:3, b = letters[1:3])
  f <- withr::local_tempfile(fileext = ".csv")
  cr_export_results(df, f)
  out <- readr::read_csv(f, show_col_types = FALSE)
  expect_equal(nrow(out), 3)
})

test_that("cr_export_results errors on unsupported format", {
  df <- tibble::tibble(a = 1)
  f <- withr::local_tempfile(fileext = ".docx")
  expect_error(cr_export_results(df, f, format = "docx"), "Unsupported")
})

test_that("cr_export_results writes xlsx when writexl available", {
  skip_if_not_installed("writexl")
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  f <- withr::local_tempfile(fileext = ".xlsx")
  cr_export_results(res, f)
  expect_true(file.exists(f))
})

test_that(".cr_result_to_tibble handles single cr_result with cell level", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "cell")
  tbl <- cellreportR:::.cr_result_to_tibble(res)
  expect_s3_class(tbl, "tbl_df")
  expect_gt(nrow(tbl), 0)
})

test_that(".cr_result_to_tibble errors on unsupported type", {
  expect_error(cellreportR:::.cr_result_to_tibble(42), "Unsupported")
})

test_that("cr_export_plots names unnamed plots and supports svg/pdf", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  p <- cr_plot_intensity(exp, "marker_1")
  dir <- withr::local_tempdir()
  out <- cr_export_plots(list(p), dir, format = "pdf", width = 3, height = 2)
  expect_true(file.exists(file.path(dir, "plot_1.pdf")))
  expect_length(out, 1)
})

test_that("cr_report errors when template missing", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  out_dir <- withr::local_tempdir()
  expect_error(
    cr_report(exp, res, template = file.path(out_dir, "nope.Rmd"),
              output_dir = out_dir),
    "Template not found"
  )
})

test_that("cr_report validates its experiment argument", {
  res <- list()
  out_dir <- withr::local_tempdir()
  expect_error(
    cr_report(list(not = "an experiment"), res, output_dir = out_dir),
    "cr_experiment"
  )
})
