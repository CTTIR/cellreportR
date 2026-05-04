test_that("cr_qc_filter removes cells outside area range and logs", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  before <- nrow(exp$cells)
  exp2 <- cr_qc_filter(exp, min_area = 50, max_area = 2000)
  expect_lte(nrow(exp2$cells), before)
  expect_equal(nrow(exp2$qc_log), 1)
  expect_true(grepl("min_area", exp2$qc_log$parameters[1]))
})

test_that("cr_qc_filter with no thresholds does nothing", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_qc_filter(exp)
  expect_equal(nrow(exp2$cells), nrow(exp$cells))
})

test_that("cr_qc_doublets removes very large cells", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  before <- nrow(exp$cells)
  exp2 <- cr_qc_doublets(exp, k = 1.2)
  expect_lt(nrow(exp2$cells), before)
})

test_that("cr_qc_intensity gates on a channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  before <- nrow(exp$cells)
  exp2 <- cr_qc_intensity(exp, "DAPI", min_intensity = 100)
  expect_lte(nrow(exp2$cells), before)
  expect_error(cr_qc_intensity(exp, "nonsense"), "not found")
})

test_that("cr_qc_manual removes a well", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  w <- "A01"
  before <- nrow(exp$cells)
  exp2 <- cr_qc_manual(exp, well = w)
  expect_false(any(exp2$cells$well == w))
  expect_lt(nrow(exp2$cells), before)
})

test_that("cr_qc_summary returns the QC log", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp <- cr_qc_filter(exp, min_area = 30)
  tbl <- cr_qc_summary(exp)
  expect_s3_class(tbl, "tbl_df")
  expect_equal(nrow(tbl), 1)
  expect_true("cells_before" %in% names(tbl))
})
