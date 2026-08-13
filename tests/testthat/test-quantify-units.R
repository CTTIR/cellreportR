# Aggregation to a merged analysis unit, the additive fold-change
# offset, and the disposition counts.

test_that("cr_summarize_wells aggregates to a unit column of the cells table", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  exp$cells$unit_id <- substr(exp$cells$well, 1, 1)
  out <- cr_summarize_wells(exp, "marker_1", unit = "unit_id")
  expect_equal(nrow(out), length(unique(exp$cells$unit_id)))
  expect_equal(sum(out$n_cells), nrow(exp$cells))
  expect_true("unit_id" %in% names(out))
})

test_that("cr_summarize_wells aggregates to a unit column of the design", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  exp$design$block <- rep(c("b1", "b2"), length.out = nrow(exp$design))
  out <- cr_summarize_wells(exp, "marker_1", unit = "block")
  expect_equal(nrow(out), 2)
  expect_setequal(out$block, c("b1", "b2"))
})

test_that("design values that vary inside a unit are returned as NA", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  exp$cells$unit_id <- "one_unit"
  out <- cr_summarize_wells(exp, "marker_1", unit = "unit_id")
  expect_equal(nrow(out), 1)
  # several treatments were pooled, so treatment is not carried
  expect_true(is.na(out$treatment))
  # dose_unit is constant across the plate, so it is
  expect_equal(out$dose_unit, "uM")
})

test_that("cr_summarize_wells accepts a function without an na.rm argument", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  out <- cr_summarize_wells(exp, "marker_1",
                            fun = function(x) unname(stats::quantile(x, 0.9)))
  expect_equal(nrow(out), length(unique(exp$cells$well)))
  expect_true(all(is.finite(out$value)))
})

test_that("cr_summarize_wells validates channel, fun and unit", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_summarize_wells(exp, "nope"), "not found")
  expect_error(cr_summarize_wells(exp, "marker_1", fun = "median"), "must be a function")
  expect_error(cr_summarize_wells(exp, "marker_1", unit = "zzz"), "Unit column")
  expect_error(cr_summarize_wells(exp, "marker_1", fun = range), "single value")
})

test_that("cr_compute_metrics honours the unit argument", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  exp$cells$unit_id <- substr(exp$cells$well, 1, 1)
  out <- cr_compute_metrics(exp, "marker_1", positive_threshold = 800,
                            unit = "unit_id")
  expect_equal(nrow(out), length(unique(exp$cells$unit_id)))
  expect_true(all(out$pct_positive >= 0 & out$pct_positive <= 100))
  expect_error(cr_compute_metrics(exp, "marker_1", positive_threshold = "hi"),
               "single number")
})

test_that("cr_fold_change offsets additively when eps is set", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  fc0 <- cr_fold_change(exp, "marker_1", "Untreated")
  fc1 <- cr_fold_change(exp, "marker_1", "Untreated", eps = 1)
  expect_equal(nrow(fc0$summary), nrow(fc1$summary))
  # a positive offset shrinks a ratio towards zero
  hi0 <- fc0$summary$median_log2_fc[fc0$summary$treatment == "CompoundA_high"]
  hi1 <- fc1$summary$median_log2_fc[fc1$summary$treatment == "CompoundA_high"]
  expect_lt(hi1, hi0)
  expect_error(cr_fold_change(exp, "marker_1", "Untreated", eps = -1),
               "non-negative")
})

test_that("cr_table_disposition counts units and cells per arm", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  out <- cr_table_disposition(exp)
  expect_true(all(c("treatment", "n_units", "n_cells",
                    "median_cells_per_unit") %in% names(out)))
  total <- out[out$treatment == "(total)", ]
  expect_equal(total$n_cells, nrow(exp$cells))
  expect_equal(total$n_units, length(unique(exp$cells$well)))
  expect_equal(sum(out$n_cells[out$treatment != "(total)"]), nrow(exp$cells))
})

test_that("cr_table_disposition can group by several columns and drop the total", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  out <- cr_table_disposition(exp, by = c("group", "treatment"), total = FALSE)
  expect_false(any(out$treatment == "(total)"))
  expect_equal(nrow(out), length(unique(exp$design$treatment)))
  expect_error(cr_table_disposition(exp, by = "nope"), "not found")
})

test_that("cr_table_disposition with no grouping returns one row", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  out <- cr_table_disposition(exp, by = character())
  expect_equal(nrow(out), 1)
  expect_equal(out$n_cells, nrow(exp$cells))
})
