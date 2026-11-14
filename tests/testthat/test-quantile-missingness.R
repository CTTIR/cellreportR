test_that("missing observations do not change a well's empirical quantile ranks", {
  cells <- data.frame(cell_id = 1:10,
    well = c(rep("a", 3), rep("b", 4), rep("c", 3)),
    signal = c(1, 2, 3, 1, 2, 3, NA, NA, NA, NA))
  design <- data.frame(well = c("a", "b", "c"), treatment = "Control")
  exp <- cr_build_experiment(cells, design, channels = data.frame(channel = "signal"))
  original <- exp$cells
  out <- cr_normalize(exp, "signal", method = "quantile")
  expect_equal(out$cells$signal, c(1, 2, 3, 1, 2, 3, NA, NA, NA, NA))
  expect_identical(out$cells$cell_id, original$cell_id)
  expect_identical(exp$cells, original)
  expect_equal(out$metadata$normalization$method, "quantile")
})

test_that("quantile normalization retains existing all-missing and tied-value behavior", {
  exp <- list(cells = data.frame(well = c("a", "a", "b", "b", "b"),
                                 signal = c(2, 2, 2, 2, NA)), spatial_unit = "well")
  expect_equal(.cr_norm_quantile(exp, "signal"), c(2, 2, 2, 2, NA))
  exp$cells$signal <- NA_real_
  expect_identical(.cr_norm_quantile(exp, "signal"), exp$cells$signal)
})
