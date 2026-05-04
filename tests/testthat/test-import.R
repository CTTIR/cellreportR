test_that("cr_read_cells reads CSV files", {
  dir <- withr::local_tempdir()
  cr_example_files(dir, seed = 1)
  cells <- cr_read_cells(file.path(dir, "cells.csv"))
  expect_s3_class(cells, "tbl_df")
  expect_true("marker_1" %in% names(cells))
  expect_gt(nrow(cells), 100)
})

test_that("cr_read_cells errors on missing file", {
  expect_error(cr_read_cells("nonexistent.csv"), "File not found")
})

test_that("cr_read_design reads CSV files", {
  dir <- withr::local_tempdir()
  files <- cr_example_files(dir, seed = 1)
  design_file <- grep("design\\.(csv|xlsx)$", files, value = TRUE)[1]
  d <- cr_read_design(design_file)
  expect_s3_class(d, "tbl_df")
  expect_true("treatment" %in% names(d))
})

test_that("cr_read_cellprofiler normalises column names", {
  dir <- withr::local_tempdir()
  cr_example_files(dir, seed = 1)
  cp <- cr_read_cellprofiler(file.path(dir, "cells_cellprofiler.csv"))
  expect_true(all(c("well", "area", "marker_1") %in% names(cp)))
})

test_that("cr_read_qupath normalises column names", {
  dir <- withr::local_tempdir()
  cr_example_files(dir, seed = 1)
  qp <- cr_read_qupath(file.path(dir, "cells_qupath.tsv"))
  expect_true(all(c("well", "marker_1") %in% names(qp)))
})

test_that("cr_read_segmantr reads RDS", {
  dir <- withr::local_tempdir()
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 5)
  rds <- file.path(dir, "sm.rds")
  saveRDS(exp$cells, rds)
  cells <- cr_read_segmantr(rds)
  expect_s3_class(cells, "tbl_df")
})

test_that("cr_read_cells rejects unknown format", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "x.unknown")
  writeLines("a,b", f)
  expect_error(cr_read_cells(f), "format")
})
