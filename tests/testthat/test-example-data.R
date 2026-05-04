test_that("cr_example_experiment produces a valid experiment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  expect_s3_class(exp, "cr_experiment")
  expect_gt(nrow(exp$cells), 100)
  expect_equal(length(unique(exp$design$treatment)), 6)
  expect_true(all(c("DAPI", "marker_1") %in% cr_channels(exp)))
})

test_that("cr_example_design generates 96-well layout", {
  d <- cr_example_design(96)
  expect_equal(nrow(d), 96)
  expect_true(all(c("well", "treatment", "dose") %in% names(d)))
})

test_that("cr_example_design supports 384-well layout", {
  d <- cr_example_design(384, n_wells_per_replicate = 8)
  expect_equal(nrow(d), 6 * 4 * 8)
  expect_true(all(c("well", "treatment", "dose") %in% names(d)))
})

test_that("cr_example_design rejects unsupported formats", {
  expect_error(cr_example_design(42), "96 and 384")
})

test_that("cr_example_files writes expected files", {
  dir <- withr::local_tempdir()
  files <- cr_example_files(dir, seed = 1)
  expect_gte(length(files), 3)
  expect_true(all(file.exists(files)))
  expect_true(any(grepl("cellprofiler", files)))
  expect_true(any(grepl("qupath", files)))
})
