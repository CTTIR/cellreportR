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
