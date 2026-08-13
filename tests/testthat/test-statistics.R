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

# ---- effect size engine ----

test_that("cr_effect_size accepts glass_delta and brackets the truth", {
  set.seed(11)
  x <- stats::rnorm(200, 1)
  y <- stats::rnorm(200, 0)
  out <- cr_effect_size(x, y, method = c("cohens_d", "glass_delta"))
  expect_equal(nrow(out), 2)
  expect_true(all(out$ci_low < out$estimate))
  expect_true(all(out$ci_high > out$estimate))
  expect_true(all(out$ci_low < 1 & out$ci_high > 1))
})

test_that("rank-biserial equals Cliff's delta and matches the naive form", {
  set.seed(3)
  x <- stats::rnorm(40, 0.7)
  y <- stats::rnorm(40, 0)
  out <- cr_effect_size(x, y, method = c("cliffs_delta", "rank_biserial"),
                        ci = NULL)
  expect_equal(out$estimate[1], out$estimate[2])
  naive <- mean(outer(x, y, ">")) - mean(outer(x, y, "<"))
  expect_equal(out$estimate[1], naive)
})

test_that("Cliff's delta handles ties", {
  x <- c(1, 1, 2, 3, 3, 4)
  y <- c(1, 2, 2, 3, 5)
  naive <- mean(outer(x, y, ">")) - mean(outer(x, y, "<"))
  expect_equal(cellreportR:::.cr_cliff_stats(x, y)$delta, naive)
})

test_that("the bootstrap interval is seeded and does not leak the RNG", {
  set.seed(4)
  x <- stats::rnorm(40, 1)
  y <- stats::rnorm(40, 0)
  a <- cr_effect_size(x, y, method = "cohens_d", ci_method = "bootstrap",
                      n_boot = 25, seed = 99)
  b <- cr_effect_size(x, y, method = "cohens_d", ci_method = "bootstrap",
                      n_boot = 25, seed = 99)
  expect_equal(a$ci_low, b$ci_low)
  set.seed(5); before <- stats::runif(1)
  invisible(cr_effect_size(x, y, method = "cohens_d",
                           ci_method = "bootstrap", n_boot = 10, seed = 7))
  set.seed(5); after <- stats::runif(1)
  expect_identical(before, after)
})

test_that("cr_effect_size rejects an impossible confidence level", {
  expect_error(cr_effect_size(1:10, 1:10, ci = 2), "between 0 and 1")
})

# ---- the effect grid ----

.stat_units <- function(seed = 1) {
  set.seed(seed)
  n <- 6
  do.call(rbind, lapply(c("CompoundA", "CompoundB"), function(cp) {
    shift <- if (identical(cp, "CompoundA")) -1.5 else -0.05
    data.frame(
      compound = cp,
      arm = rep(c("reference", "interval_short"), each = n),
      plate = rep(rep(c("P1", "P2"), each = n / 2), 2),
      unit_id = paste0(cp, "_u", seq_len(2 * n)),
      log2_fc = c(stats::rnorm(n, 0, 0.3), stats::rnorm(n, shift, 0.3))
    )
  }))
}

.stat_cells <- function(seed = 1, n_cells = 25) {
  u <- .stat_units(seed)
  u[rep(seq_len(nrow(u)), each = n_cells), ] |>
    transform(log2_fc = log2_fc + stats::rnorm(nrow(u) * n_cells, 0, 0.5))
}

test_that("cr_effect_grid returns one row per stratum and contrast", {
  eff <- cr_effect_grid(.stat_units(), value = "log2_fc",
                        group_var = "arm", reference_level = "reference",
                        by = "compound")
  expect_s3_class(eff, "tbl_df")
  expect_equal(nrow(eff), 2)
  expect_true(all(c("compound", "contrast", "level", "n_ref", "n_cmp",
                    "mean_shift", "cohens_d", "cohens_d_ci_low",
                    "cohens_d_ci_high", "cohens_d_magnitude", "hedges_g",
                    "cliffs_delta", "p_value", "p_bonferroni", "p_BH",
                    "ci_excludes_zero") %in% names(eff)))
  expect_identical(eff$level, rep("cell", 2))
  expect_identical(
    cr_effect_grid(.stat_units(), "log2_fc", "arm", "reference",
                   by = "compound", level = "unit")$level,
    rep("unit", 2)
  )
  a <- eff[eff$compound == "CompoundA", ]
  expect_lt(a$cohens_d, 0)
  expect_true(a$ci_excludes_zero)
  expect_false(eff$ci_excludes_zero[eff$compound == "CompoundB"])
  expect_true(all(eff$p_bonferroni >= eff$p_value))
})

test_that("cr_effect_grid aggregates cells to units when unit is given", {
  cells <- .stat_cells()
  u <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
                      by = "compound", unit = "unit_id")
  expect_identical(u$n_ref, rep(6L, 2))
  expect_identical(u$level, rep("unit", 2))
  k <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
                      by = "compound", min_n = 10)
  expect_identical(k$level, rep("cell", 2))
  expect_gt(k$n_ref[1], u$n_ref[1])
})

test_that("cr_effect_grid skips arms below min_n and records them", {
  units <- .stat_units()
  eff <- cr_effect_grid(units, "log2_fc", "arm", "reference",
                        by = "compound", min_n = 20)
  expect_equal(nrow(eff), 0)
  expect_true(all(c("compound", "cohens_d", "p_BH") %in% names(eff)))
  expect_type(eff$cohens_d, "double")
  expect_equal(nrow(attr(eff, "skipped")), 2)
})

test_that("cr_effect_grid validates its inputs", {
  units <- .stat_units()
  expect_error(cr_effect_grid(units, "nope", "arm", "reference"),
               "missing the column")
  expect_error(cr_effect_grid(units, "log2_fc", "arm", "absent"),
               "not present")
  expect_error(cr_effect_grid(units, "arm", "arm", "reference"),
               "must be numeric")
  expect_error(cr_effect_grid(list(1), "log2_fc", "arm", "reference"),
               "data frame")
})

test_that("cr_effect_grid accepts a cr_experiment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  eff <- cr_effect_grid(exp, value = "marker_1", group_var = "treatment",
                        reference_level = "Untreated", unit = "well")
  expect_gt(nrow(eff), 0)
  expect_true(all(eff$n_ref > 0))
})

test_that("cr_compare_levels shows cell-level intervals to be narrower", {
  cells <- .stat_cells()
  u <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
                      by = "compound", unit = "unit_id")
  k <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
                      by = "compound", min_n = 10)
  cmp <- cr_compare_levels(u, k)
  expect_equal(nrow(cmp), 2)
  expect_true(all(c("width_unit", "width_cell", "ratio") %in% names(cmp)))
  expect_true(all(cmp$ratio > 1))
  expect_equal(attr(cmp, "median_ratio"), stats::median(cmp$ratio))
})

# ---- blocked sensitivity and variability ----

test_that("cr_blocked_effect recovers a planted shift within blocks", {
  units <- .stat_units()
  units$log2_fc <- units$log2_fc + ifelse(units$plate == "P2", 0.8, 0)
  bl <- cr_blocked_effect(units, "log2_fc", "arm", "reference",
                          block_var = "plate", by = "compound")
  expect_equal(nrow(bl), 2)
  a <- bl[bl$compound == "CompoundA", ]
  expect_equal(a$n_blocks, 2L)
  expect_lt(a$shift_within_block, 0)
  expect_lt(a$ci_high, 0)
  expect_true(is.finite(a$resid_sd) && a$resid_sd > 0)
  expect_equal(a$d_within_block, a$shift_within_block / a$resid_sd)
})

test_that("cr_blocked_effect skips a contrast with a single block", {
  units <- .stat_units()
  units$plate <- "P1"
  bl <- cr_blocked_effect(units, "log2_fc", "arm", "reference",
                          block_var = "plate", by = "compound")
  expect_equal(nrow(bl), 0)
  expect_equal(nrow(attr(bl, "skipped")), 2)
})

test_that("cr_unit_variability reports the fold range and its summary", {
  units <- .stat_units()
  v <- cr_unit_variability(units, "log2_fc",
                           by = c("compound", "arm", "plate"))
  expect_true(all(v$n_units >= 2))
  expect_equal(v$fold_range, 2^v$spread)
  s <- attr(v, "summary")
  expect_equal(s$n_groups, nrow(v))
  expect_equal(s$max_fold_range, max(v$fold_range))
  expect_equal(nrow(cr_unit_variability(units, "log2_fc",
                                        by = "unit_id")), 0)
})

# ---- sizing ----

test_that("cr_conservative_effect takes the bound nearer the null", {
  expect_equal(cr_conservative_effect(c(-1.8, 0.4), c(-0.6, 1.9)),
               c(-0.6, 0.4))
  expect_true(is.na(cr_conservative_effect(-0.4, 0.9)))
  expect_true(is.na(cr_conservative_effect(NA, 0.9)))
})

test_that("cr_power sizes on both the estimate and the nearer bound", {
  pw <- cr_power(effect_size = c(-1.31, -0.28),
                 ci_low = c(-2.35, -1.20),
                 ci_high = c(-0.27, 0.64))
  expect_equal(nrow(pw), 2)
  expect_gt(pw$n_conservative[1], pw$n_observed[1])
  expect_true(is.na(pw$n_conservative[2]))
  expect_match(pw$basis[1], "nearer the null")
  expect_match(pw$basis[2], "spans the null")
  expect_true(all(pw$n_observed == ceiling(pw$n_observed)))
  expect_error(cr_power(), "ci_low")
})

test_that("cr_power agrees with the two-sample t solution", {
  pw <- cr_power(effect_size = 0.8)
  expected <- ceiling(stats::power.t.test(delta = 0.8, sd = 1, power = 0.8,
                                          sig.level = 0.05,
                                          type = "two.sample")$n)
  expect_equal(pw$n_observed, expected)
  expect_true(is.na(pw$n_conservative))
})

test_that("cr_power_grid appends sizing columns to an effect grid", {
  eff <- cr_effect_grid(.stat_units(), "log2_fc", "arm", "reference",
                        by = "compound")
  sz <- cr_power_grid(eff)
  expect_true(all(c("d_conservative", "n_observed", "n_conservative",
                    "basis", "n_available", "sufficient") %in% names(sz)))
  expect_equal(nrow(sz), nrow(eff))
  expect_equal(sz$n_available, pmin(eff$n_ref, eff$n_cmp))
  expect_type(sz$sufficient, "logical")
  expect_error(cr_power_grid(eff, estimate = "nope"), "missing the column")
})

test_that("cr_power_analysis is reproducible and does not leak the RNG", {
  a <- cr_power_analysis(1.2, 4, 20, n_sim = 50, seed = 11)
  b <- cr_power_analysis(1.2, 4, 20, n_sim = 50, seed = 11)
  expect_equal(a$power, b$power)
  set.seed(6); before <- stats::runif(1)
  invisible(cr_power_analysis(1.2, 3, 10, n_sim = 20, seed = 3))
  set.seed(6); after <- stats::runif(1)
  expect_identical(before, after)
  expect_error(cr_power_analysis(1, 3, 10, test = "anova"), "t_test")
})

test_that("cr_test_all reports both multiplicity adjustments", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  s <- attr(cr_test_all(exp, "marker_1", "Untreated", level = "replicate"),
            "summary")
  expect_true(all(c("p_adj", "p_bonferroni", "p_BH") %in% names(s)))
  expect_true(all(s$p_bonferroni >= s$p_value))
  expect_true(all(s$p_BH >= s$p_value - 1e-12))
})
