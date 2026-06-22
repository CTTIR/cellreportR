test_that("robust z-score normalization has median ~0", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp2 <- cr_normalize(exp, channel = "marker_1", method = "robust_zscore")
  expect_lt(abs(stats::median(exp2$cells$marker_1, na.rm = TRUE)), 0.1)
})

test_that("z-score normalization has mean ~0 and sd ~1", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp2 <- cr_normalize(exp, channel = "marker_1", method = "zscore")
  expect_lt(abs(mean(exp2$cells$marker_1, na.rm = TRUE)), 0.01)
  expect_lt(abs(stats::sd(exp2$cells$marker_1, na.rm = TRUE) - 1), 0.01)
})

test_that("control normalization requires control_group", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  expect_error(cr_normalize(exp, "marker_1", method = "control"),
               "control_group")
})

test_that("control normalization yields log2-centred values", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp2 <- cr_normalize(exp, "marker_1", method = "control",
                       control_group = "Untreated")
  med <- stats::median(exp2$cells$marker_1, na.rm = TRUE)
  expect_lt(abs(med), 4)
})

test_that("background subtraction clips at zero", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_background_subtract(exp, channel = "marker_1")
  expect_true(all(exp2$cells$marker_1 >= 0, na.rm = TRUE))
})

test_that("batch correction with median_center is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp$design$batch <- rep(c("b1", "b2"),
                          length.out = nrow(exp$design))
  exp2 <- cr_correct_batch(exp, batch_var = "batch", channel = "marker_1")
  expect_equal(nrow(exp2$cells), nrow(exp$cells))
})

test_that("normalize errors on missing channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_normalize(exp, "not_a_channel"), "not found")
})

# --- additional coverage -------------------------------------------------

test_that("normalize defaults to background method and modifies channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_normalize(exp, "marker_1")
  expect_s3_class(exp2, "cr_experiment")
  expect_true(all(exp2$cells$marker_1 >= 0, na.rm = TRUE))
})

test_that("quantile normalization preserves length and records metadata", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 25)
  exp2 <- cr_normalize(exp, "marker_1", method = "quantile")
  expect_equal(length(exp2$cells$marker_1), length(exp$cells$marker_1))
  expect_equal(exp2$metadata$normalization$method, "quantile")
  expect_equal(exp2$metadata$normalization$channel, "marker_1")
  # Output values are drawn from the global pool of originals.
  vals <- exp2$cells$marker_1[!is.na(exp2$cells$marker_1)]
  expect_true(all(vals >= min(exp$cells$marker_1, na.rm = TRUE) - 1e-6))
})

test_that("quantile normalization returns input when channel all NA", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  exp$cells$marker_2 <- NA_real_
  exp2 <- cr_normalize(exp, "marker_2", method = "quantile")
  expect_true(all(is.na(exp2$cells$marker_2)))
})

test_that("control normalization errors when group has no wells", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_error(
    cellreportR:::.cr_norm_control(exp, "marker_1", "DoesNotExist"),
    "No wells match"
  )
})

test_that("control normalization errors on non-positive reference", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  exp$cells$marker_1[exp$cells$well %in%
                       exp$design$well[exp$design$treatment == "Untreated"]] <- 0
  expect_error(
    cr_normalize(exp, "marker_1", method = "control",
                 control_group = "Untreated"),
    "non-positive"
  )
})

test_that("background subtraction modal method runs and clips", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp2 <- cr_background_subtract(exp, "marker_1", method = "modal")
  expect_true(all(exp2$cells$marker_1 >= 0, na.rm = TRUE))
  expect_equal(nrow(exp2$cells), nrow(exp$cells))
})

test_that("background subtraction empty_wells requires wells", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_error(
    cr_background_subtract(exp, "marker_1", method = "empty_wells"),
    "non-empty"
  )
})

test_that("background subtraction empty_wells uses provided wells", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_background_subtract(exp, "marker_1", method = "empty_wells",
                                 empty_wells = "A01")
  expect_true(all(exp2$cells$marker_1 >= 0, na.rm = TRUE))
})

test_that("background subtraction errors on missing channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_background_subtract(exp, "nope"), "not found")
})

test_that(".cr_mode returns NA for empty input and a number otherwise", {
  expect_true(is.na(cellreportR:::.cr_mode(numeric(0))))
  expect_true(is.na(cellreportR:::.cr_mode(c(NA, Inf, -Inf))))
  m <- cellreportR:::.cr_mode(c(1, 1, 1, 2, 3, 10))
  expect_true(is.numeric(m) && length(m) == 1)
})

test_that("batch correction errors on missing batch var and channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_correct_batch(exp, "nope", "marker_1"), "not found in design")
  exp$design$batch <- "b1"
  expect_error(cr_correct_batch(exp, "batch", "nope"), "not found")
})

test_that("batch correction combat falls back to median_center without sva", {
  skip_if(requireNamespace("sva", quietly = TRUE),
          "sva is installed; fallback branch not exercised")
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  exp$design$batch <- rep(c("b1", "b2"), length.out = nrow(exp$design))
  expect_warning(
    exp2 <- cr_correct_batch(exp, "batch", "marker_1", method = "combat"),
    "sva"
  )
  expect_equal(nrow(exp2$cells), nrow(exp$cells))
})
