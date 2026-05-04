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
