test_that("distinct batches cannot acquire the same public key", {
  x <- data.frame(a = c("A | B", "A"), b = c("C", "B | C"))
  expect_error(cr_batch_key(x, c("a", "b")), "collision")
  expect_error(cr_batch_key(data.frame(a = c(NA, "<NA>")), "a"), "collision")
  expect_identical(cr_batch_key(x, c("a", "b"), sep = " / "), c("A | B / C", "A / B | C"))
  expect_identical(cr_batch_key(data.frame(a = c(NA, NA)), "a"), rep("<NA>", 2))
})

test_that("statistical grouping preserves typed missing values and literal separators", {
  x <- data.frame(a = c(NA, "NA", "A\rB", "A"), b = c("x", "x", "C", "B\rC"))
  groups <- .cr_stat_groups(x, c("a", "b"))
  expect_length(groups, 4)
  expect_identical(lapply(groups, `[[`, "idx"), as.list(1:4))
  expect_true(is.na(groups[[1]]$key$a))
  expect_identical(groups[[2]]$key$a, "NA")
})

test_that("blocked treatment effects require an estimable model with residual degrees of freedom", {
  d <- data.frame(value = c(1:6, 21:26), arm = rep(c("control", "treated"), each = 6),
                  plate = rep(c("p1", "p2"), each = 6))
  bad <- cr_blocked_effect(d, "value", "arm", "control", block_var = "plate")
  expect_equal(nrow(bad), 0)
  expect_equal(nrow(attr(bad, "skipped")), 1)
  d$plate <- rep(c("p1", "p2"), 6)
  good <- cr_blocked_effect(d, "value", "arm", "control", block_var = "plate")
  fit <- stats::lm(value ~ factor(arm) + factor(plate), data = d)
  expect_equal(good$shift_within_block, unname(stats::coef(fit)[2]))
  expect_equal(good$ci_low, unname(stats::confint(fit)[2, 1]))
  shuffled <- cr_blocked_effect(d[rev(seq_len(nrow(d))), ], "value", "arm", "control", block_var = "plate")
  expect_equal(shuffled$shift_within_block, good$shift_within_block)
  saturated <- d[c(1, 2, 7), ]
  expect_equal(nrow(cr_blocked_effect(saturated, "value", "arm", "control", block_var = "plate")), 0)
})

test_that("comparison joins cannot multiply contrasts across numeric strata", {
  u <- data.frame(time = c(1, 2), contrast = "A -> B", level = "unit", cohens_d = c(.5, 1),
                  cohens_d_ci_low = c(.1, .2), cohens_d_ci_high = c(.9, 1.8))
  cells <- u
  cells$level <- "cell"
  expect_error(cr_compare_levels(u, cells), "unique|ambiguous")
  result <- cr_compare_levels(u, cells, by = c("time", "contrast"))
  expect_identical(result$time, c(1, 2))
  expect_equal(result$ratio, c(1, 1))
})

test_that("replicate test effects use the same summaries as their p values", {
  e <- cr_example_experiment(seed = 42, n_cells_per_well = 6)
  wells <- cr_summarize_wells(e, "marker_1")
  expected <- cr_effect_size(wells$value[wells$treatment == "CompoundA_high"],
                             wells$value[wells$treatment == "Untreated"],
                             method = c("cohens_d", "hedges_g", "cliffs_delta", "rank_biserial"))
  result <- cr_test(e, "marker_1", "CompoundA_high", "Untreated", level = "replicate")
  expect_equal(result$effect_sizes, expected)
  both <- cr_test(e, "marker_1", "CompoundA_high", "Untreated", level = "both")
  cell <- cr_test(e, "marker_1", "CompoundA_high", "Untreated", level = "cell")
  expect_equal(both$effect_sizes, expected)
  expect_equal(both$cell_effect_sizes, cell$effect_sizes)
  s <- attr(cr_test_all(e, "marker_1", "Untreated", level = "replicate"), "summary")
  expect_equal(s$cohens_d[s$treatment == "CompoundA_high"], expected$estimate[1])
})

test_that("shared cell and design metadata keeps a usable treatment column", {
  e <- cr_example_experiment(seed = 42, n_cells_per_well = 6)
  original <- cr_test_all(e, "marker_1", "Untreated")
  e$cells$treatment <- e$design$treatment[match(e$cells[[e$spatial_unit]], e$design[[e$spatial_unit]])]
  current <- cr_test_all(e, "marker_1", "Untreated")
  expect_equal(attr(current, "summary"), attr(original, "summary"))
  expect_equal(sum(cr_n_cells(e, "treatment")$n_cells), nrow(e$cells))
})

test_that("paired tests require identified matching instead of silently truncating arms", {
  e <- cr_example_experiment(seed = 42, n_cells_per_well = 6)
  expect_error(cr_test(e, "marker_1", "CompoundA_high", "Untreated", test = "wilcoxon_signed"),
               "matched|pair")
  expect_error(.cr_do_test(1:6, 2:5, "wilcoxon_signed", "replicate"), "matched|pair")
})

test_that("a missing conservative target never certifies sample-size sufficiency", {
  effects <- data.frame(cohens_d = c(.8, -.8, .8), cohens_d_ci_low = c(-.2, -1.2, .5),
                        cohens_d_ci_high = c(1.2, -.5, 1.2), n_ref = 100, n_cmp = 100)
  out <- cr_power_grid(effects)
  expect_identical(out$sufficient, c(FALSE, TRUE, TRUE))
  expect_true(is.na(out$n_conservative[1]))
  expect_equal(out$n_conservative[2:3], rep(ceiling(stats::power.t.test(delta = .5, power = .8)$n), 2))
  expect_error(cr_conservative_effect(2, 1), "lower|order")
  expect_error(cr_power(.8, ci_low = .2), "both")
  expect_error(cr_power(c(.5, .6, .7), ci_low = c(.1, .2), ci_high = c(.9, 1)), "length")
  expect_error(cr_power_grid(effects, available = c(10, 20)), "length")
  expect_equal(nrow(cr_power_grid(effects[FALSE, ])), 0)
})
