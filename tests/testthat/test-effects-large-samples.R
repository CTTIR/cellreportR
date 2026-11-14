test_that("large cell samples retain finite effect estimates and analytic intervals", {
  n <- 50000
  x <- seq_len(n)
  expect_warning(cs <- .cr_cliff_stats(x, x), NA)
  expect_equal(cs$delta, 0)
  # Closed form for two identical ordered samples with one tie per row.
  expected_variance <- (2 * n - 1) / (3 * n * (n - 1))
  expect_equal(cs$sigma^2, expected_variance, tolerance = 1e-12)
  expect_warning(out <- cr_effect_size(x, x,
    method = c("cohens_d", "hedges_g", "glass_delta")), NA)
  half <- stats::qt(.975, 2 * n - 2) * sqrt(2 / n)
  correction <- 1 - 3 / (4 * (2 * n - 2) - 1)
  expect_equal(out$estimate, rep(0, 3))
  expect_equal(out$ci_low, -half * c(1, correction, 1))
  expect_equal(out$ci_high, half * c(1, correction, 1))
  expect_warning(rank <- cr_effect_size(x, x,
    method = c("cliffs_delta", "rank_biserial")), NA)
  z <- stats::qnorm(.975)
  rank_half <- z * sqrt(expected_variance) / sqrt(1 + z^2 * expected_variance)
  expect_equal(rank$estimate, c(0, 0))
  expect_equal(rank$ci_low, rep(-rank_half, 2))
  expect_equal(rank$ci_high, rep(rank_half, 2))
})

test_that("rank effects still match direct pairwise signs with ties", {
  x <- c(-2, 0, 0, 3)
  y <- c(0, 1, 3, 3, 4)
  expected <- mean(sign(outer(x, y, "-")))
  expect_equal(.cr_effsize(x, y, "cliffs_delta"), expected)
  expect_equal(.cr_effsize(x, y, "rank_biserial"), expected)
})
