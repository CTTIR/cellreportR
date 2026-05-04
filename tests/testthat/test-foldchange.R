test_that("cr_summarize_wells returns one row per well", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  w <- cr_summarize_wells(exp, "marker_1")
  expect_equal(nrow(w), length(unique(exp$cells$well)))
  expect_true("value" %in% names(w))
})

test_that("cr_compute_metrics returns rich summaries", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  m <- cr_compute_metrics(exp, "marker_1")
  expect_true(all(c("median", "mean", "sd", "cv") %in% names(m)))
})

test_that("cr_fold_change returns correct structure", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  fc <- cr_fold_change(exp, "marker_1", "Untreated")
  expect_true(all(c("cell", "well", "summary") %in% names(fc)))
  expect_true(all(c("treatment", "median_log2_fc") %in% names(fc$summary)))
  # The high dose should have a positive median log2 fc
  hi <- fc$summary$median_log2_fc[fc$summary$treatment == "CompoundA_high"]
  expect_gt(hi, 0.5)
})

test_that("cr_fold_change errors on missing control group", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_fold_change(exp, "marker_1", "nonexistent"),
               "not found in design")
})
