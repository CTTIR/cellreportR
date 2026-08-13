test_that("cr_plot_plate returns ggplot", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_s3_class(cr_plot_plate(exp, "marker_1"), "ggplot")
})

test_that("cr_plot_intensity supports each geom option", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  for (g in c("violin", "boxplot", "both")) {
    expect_s3_class(cr_plot_intensity(exp, "marker_1", geom = g), "ggplot")
  }
})

test_that("cr_plot_scatter produces a ggplot", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_s3_class(cr_plot_scatter(exp, "DAPI", "marker_1"), "ggplot")
})

test_that("cr_plot_histogram supports facet", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_s3_class(cr_plot_histogram(exp, "marker_1", facet_by = "treatment"),
                  "ggplot")
})

test_that("cr_plot_foldchange works on cr_result list", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  expect_s3_class(cr_plot_foldchange(all_res), "ggplot")
})

test_that("cr_plot_effect_sizes works on cr_result list", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  expect_s3_class(cr_plot_effect_sizes(all_res), "ggplot")
})

test_that("cr_plot_roc works on a single result", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  logit <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  expect_s3_class(cr_plot_roc(logit), "ggplot")
})

test_that("cr_plot_qc returns ggplot", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_s3_class(cr_plot_qc(exp), "ggplot")
})

test_that("cr_plot_spatial works for a single well", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_s3_class(cr_plot_spatial(exp, "marker_1"), "ggplot")
})

test_that("cr_plot_comparison combines stats and data", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "replicate")
  expect_s3_class(cr_plot_comparison(res, exp), "ggplot")
})

test_that("cr_plot_heatmap returns a ggplot", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_s3_class(cr_plot_heatmap(exp, c("DAPI", "marker_1")), "ggplot")
})

test_that("cr_plot_timeline returns a ggplot", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  exp$design$timepoint <- rep(c(0, 6, 12, 24),
                              length.out = nrow(exp$design))
  expect_s3_class(
    cr_plot_timeline(exp, "timepoint", "marker_1"),
    "ggplot"
  )
})

test_that("cr_plot_dose_response returns a ggplot", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  exp$design$dose <- dplyr::case_when(
    exp$design$treatment == "Untreated"      ~ 0.1,
    exp$design$treatment == "CompoundA_low"  ~ 50,
    exp$design$treatment == "CompoundA_high" ~ 500,
    TRUE ~ 10
  )
  fit <- cr_dose_response(exp, "marker_1", model = "4pl")
  expect_s3_class(cr_plot_dose_response(fit), "ggplot")
})

# --- additional coverage -------------------------------------------------

test_that("cr_plot_roc draws several results on one pair of axes", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  results <- list(
    high = cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated"),
    low = cr_logistic(exp, "marker_1", "CompoundA_low", "Untreated")
  )
  p <- cr_plot_roc(results)
  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$name), c("CompoundA_high", "CompoundA_low"))
})

test_that("cr_plot_roc skips list entries carrying no curve", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  results <- list(
    high = cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated"),
    plain = cr_test(exp, "marker_1", "CompoundA_low", "Untreated",
                    level = "cell")
  )
  df <- cellreportR:::.cr_roc_df(results)
  expect_equal(unique(df$name), "CompoundA_high")
})

test_that("cr_plot_roc rejects input that is neither result nor list", {
  expect_error(cellreportR:::.cr_roc_df(42), "Unsupported input")
})

test_that("cr_plot_heatmap scales by row and by column", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  channels <- c("DAPI", "marker_1", "marker_2")
  for (scale in c("none", "row", "column")) {
    p <- cr_plot_heatmap(exp, channels, scale = scale)
    expect_s3_class(p, "ggplot")
    expect_equal(nrow(p$data),
                 length(channels) * dplyr::n_distinct(exp$design$treatment))
  }
})

test_that("cr_plot_heatmap can group by any design column", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  p <- cr_plot_heatmap(exp, c("DAPI", "marker_1"), group_by = "plate")
  expect_s3_class(p, "ggplot")
  expect_true("plate" %in% names(p$data))
})

test_that("cr_plot_heatmap names what it could not find", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_error(cr_plot_heatmap(exp, "marker_1", group_by = "nope"),
               "not found")
  expect_error(cr_plot_heatmap(exp, c("marker_1", "nope")),
               "Channels not found")
})

test_that("cr_plot_comparison falls back to the cell-level p value", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  expect_equal(nrow(res$rep_level), 0L)
  p <- cr_plot_comparison(res, exp)
  expect_s3_class(p, "ggplot")
  expect_setequal(unique(p$data$treatment),
                  c("CompoundA_high", "Untreated"))
})

test_that("cr_plot_comparison validates both of its arguments", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  expect_error(cr_plot_comparison(42, exp), "must be a")
  expect_error(cr_plot_comparison(res, list(nope = TRUE)), "cr_experiment")
})
