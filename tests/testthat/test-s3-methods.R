test_that("print.cr_experiment runs without error", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_no_error(print(exp))
})

test_that("summary.cr_experiment returns tibble", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  s <- suppressMessages(summary(exp))
  expect_s3_class(s, "tbl_df")
})

test_that("print.cr_result runs without error", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  expect_no_error(print(res))
})

test_that("print.cr_report runs without error", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  rep <- cellreportR:::.cr_new_report(exp)
  expect_no_error(print(rep))
})
