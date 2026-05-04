test_that("cr_well_to_rowcol splits standard IDs", {
  rc <- cr_well_to_rowcol(c("A01", "B05", "H12"))
  expect_equal(rc$row, c(1, 2, 8))
  expect_equal(rc$col, c(1, 5, 12))
})

test_that("cr_rowcol_to_well pads columns", {
  expect_equal(cr_rowcol_to_well(c(1, 8), c(1, 12)), c("A01", "H12"))
})

test_that("cr_rowcol_to_well handles 384 rows", {
  expect_equal(cr_rowcol_to_well(16, 24), "P24")
})

test_that("cr_channels lists channel names", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  chs <- cr_channels(exp)
  expect_true(all(c("DAPI", "marker_1") %in% chs))
})

test_that("cr_n_cells counts total and grouped", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_equal(cr_n_cells(exp), nrow(exp$cells))
  grp <- cr_n_cells(exp, by = "treatment")
  expect_s3_class(grp, "tbl_df")
})

test_that("cr_filter_cells logs the filter", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_filter_cells(exp, area > 10)
  expect_equal(nrow(exp2$qc_log), 1)
  expect_true(nrow(exp2$cells) <= nrow(exp$cells))
})

test_that("cr_merge_experiments rejects duplicated wells", {
  e1 <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  e2 <- cr_example_experiment(seed = 2, n_cells_per_well = 10)
  expect_error(cr_merge_experiments(e1, e2), "Duplicated")
})

test_that("cr_merge_experiments merges with unique wells", {
  e1 <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  e2 <- cr_example_experiment(seed = 2, n_cells_per_well = 10)
  e2$cells$well <- paste0("p2_", e2$cells$well)
  e2$design$well <- paste0("p2_", e2$design$well)
  merged <- cr_merge_experiments(e1, e2)
  expect_s3_class(merged, "cr_experiment")
  expect_gt(nrow(merged$cells), nrow(e1$cells))
})
