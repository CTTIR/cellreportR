make_dose_exp <- function() {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp$design$dose <- dplyr::case_when(
    exp$design$treatment == "Untreated"       ~ 0.1,
    exp$design$treatment == "CompoundA_low"   ~ 50,
    exp$design$treatment == "CompoundA_high"  ~ 500,
    exp$design$treatment == "PosControl"      ~ 1000,
    TRUE ~ 10
  )
  exp
}

test_that("cr_dose_response fits 4PL", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "4pl")
  expect_s3_class(fit, "cr_dose_response")
  expect_equal(fit$channel, "marker_1")
  expect_true(nrow(fit$params) >= 2)
})

test_that("cr_dose_response fits linear", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "linear")
  expect_equal(fit$model, "linear")
})

test_that("cr_ic50 returns a value for a 4PL fit (or NA on degenerate)", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "4pl")
  ic <- cr_ic50(fit)
  expect_s3_class(ic, "tbl_df")
  expect_equal(ic$parameter, "IC50")
})

test_that("cr_dose_response errors if design lacks dose column", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  exp$design$dose <- NULL
  expect_error(cr_dose_response(exp, "marker_1"), "dose")
})
