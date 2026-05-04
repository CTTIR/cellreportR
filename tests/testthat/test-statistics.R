test_that("cr_test returns a cr_result with cell-level p-value", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  expect_s3_class(res, "cr_result")
  expect_true(nrow(res$cell_level) > 0)
  expect_true(res$cell_level$p_value[1] < 0.01)
})

test_that("cr_test replicate-level is permutation-free", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "t_test", level = "replicate")
  expect_true(res$rep_level$p_value[1] < 0.05)
})

test_that("cr_test_all adjusts p-values", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  all_res <- cr_test_all(exp, "marker_1", "Untreated",
                         level = "replicate")
  s <- attr(all_res, "summary")
  expect_s3_class(s, "tbl_df")
  expect_true("p_adj" %in% names(s))
  expect_true(all(!is.na(s$p_adj)))
})

test_that("cr_effect_size returns all four methods", {
  set.seed(1)
  x <- stats::rnorm(100, 1); y <- stats::rnorm(100, 0)
  out <- cr_effect_size(x, y, method = c("cohens_d", "hedges_g",
                                          "cliffs_delta", "rank_biserial"))
  expect_equal(nrow(out), 4)
  expect_true(all(c("estimate", "ci_low", "ci_high", "magnitude") %in% names(out)))
})

test_that("cr_effect_size cohen's d is close to expected value", {
  set.seed(1)
  x <- stats::rnorm(500, 1); y <- stats::rnorm(500, 0)
  d <- cr_effect_size(x, y, method = "cohens_d", ci = NULL)
  expect_equal(d$estimate, 1, tolerance = 0.15)
})

test_that("cr_power_analysis produces reasonable power values", {
  pw <- cr_power_analysis(effect_size = 1.5,
                          n_replicates = 4,
                          n_cells_per_rep = 50,
                          n_sim = 100)
  expect_s3_class(pw, "tbl_df")
  expect_gt(pw$power, 0.5)
})
