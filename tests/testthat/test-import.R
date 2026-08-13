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
  rds <- file.path(dir, "cells.rds")
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

# --- additional coverage -------------------------------------------------

test_that("cr_read_cells reads TSV via the tsv branch", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "cells.tsv")
  readr::write_tsv(tibble::tibble(cell_id = "c1", well = "A01", marker_1 = 1), f)
  out <- cr_read_cells(f)
  expect_s3_class(out, "tbl_df")
  expect_equal(out$well, "A01")
})

test_that("cr_read_cells reads RDS via the rds branch", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "cells.rds")
  saveRDS(tibble::tibble(cell_id = "c1", well = "A01", marker_1 = 1), f)
  out <- cr_read_cells(f)
  expect_s3_class(out, "tbl_df")
})

test_that(".cr_read_rds unwraps a cr_experiment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  f <- withr::local_tempfile(fileext = ".rds")
  saveRDS(exp, f)
  out <- cellreportR:::.cr_read_rds(f)
  expect_s3_class(out, "tbl_df")
  expect_true("marker_1" %in% names(out))
})

test_that(".cr_read_rds unwraps a segmantr_result", {
  obj <- list(cells = tibble::tibble(cell_id = "c1", well = "A01", m = 1))
  class(obj) <- "segmantr_result"
  f <- withr::local_tempfile(fileext = ".rds")
  saveRDS(obj, f)
  out <- cellreportR:::.cr_read_rds(f)
  expect_s3_class(out, "tbl_df")
})

test_that(".cr_read_rds errors on unsupported content", {
  f <- withr::local_tempfile(fileext = ".rds")
  saveRDS(list(x = 1), f)
  expect_error(cellreportR:::.cr_read_rds(f), "Unsupported RDS")
})

test_that("cr_read_cells errors with flowCore missing for FCS", {
  testthat::local_mocked_bindings(
    requireNamespace = function(pkg, ...) FALSE,
    .package = "base"
  )
  f <- withr::local_tempfile(fileext = ".fcs")
  file.create(f)
  expect_error(cr_read_cells(f), "flowCore")
})

test_that("cr_read_design reads xlsx and errors on unsupported format", {
  dir <- withr::local_tempdir()
  files <- cr_example_files(dir, seed = 1)
  design_file <- grep("design\\.xlsx$", files, value = TRUE)
  if (length(design_file)) {
    d <- cr_read_design(design_file)
    expect_true("treatment" %in% names(d))
  }
  bad <- file.path(dir, "design.json")
  writeLines("{}", bad)
  expect_error(cr_read_design(bad), "Unsupported design format")
})

test_that("cr_read_design errors on a missing file", {
  expect_error(cr_read_design("nope.csv"), "File not found")
})

test_that("cr_read_cellprofiler falls back to ImageNumber when no well", {
  raw <- tibble::tibble(
    ImageNumber = c(1L, 1L, 2L),
    Location_Center_X = c(1, 2, 3),
    Location_Center_Y = c(4, 5, 6),
    AreaShape_Area = c(100, 110, 120),
    AreaShape_FormFactor = c(0.8, 0.9, 0.7),
    Intensity_MeanIntensity_marker_1 = c(10, 11, 12)
  )
  f <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(raw, f)
  out <- cr_read_cellprofiler(f)
  expect_true(all(grepl("^img_", out$well)))
  expect_true("marker_1" %in% names(out))
})

test_that("cr_read_cellprofiler errors when no well column is detectable", {
  raw <- tibble::tibble(
    Foo = 1:3,
    Intensity_MeanIntensity_marker_1 = c(10, 11, 12)
  )
  f <- withr::local_tempfile(fileext = ".csv")
  readr::write_csv(raw, f)
  expect_error(cr_read_cellprofiler(f), "No well column")
})

test_that("cr_read_qupath uses Object ID and Parent and errors without spatial", {
  raw <- tibble::tibble(
    `Object ID` = c("o1", "o2"),
    Parent = c("A01.ome.tif", "B02.ome.tif"),
    `Centroid X um` = c(1, 2),
    `Centroid Y um` = c(3, 4),
    `Cell: Area um^2` = c(50, 60),
    `Cell: Circularity` = c(0.8, 0.9),
    `Cell: marker_1 mean` = c(5, 6)
  )
  f <- withr::local_tempfile(fileext = ".tsv")
  readr::write_tsv(raw, f)
  out <- cr_read_qupath(f)
  expect_equal(out$well, c("A01", "B02"))
  expect_equal(out$cell_id, c("o1", "o2"))
  expect_true("marker_1" %in% names(out))

  raw2 <- tibble::tibble(Foo = 1:2, `Cell: marker_1 mean` = c(1, 2))
  f2 <- withr::local_tempfile(fileext = ".tsv")
  readr::write_tsv(raw2, f2)
  expect_error(cr_read_qupath(f2), "No spatial unit")
})
