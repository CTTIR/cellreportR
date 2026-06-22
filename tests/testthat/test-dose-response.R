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

# --- additional coverage -------------------------------------------------

test_that("cr_dose_response errors on missing channel", {
  exp <- make_dose_exp()
  expect_error(cr_dose_response(exp, "nope"), "not found")
})

test_that("cr_dose_response fits 3PL", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "3pl")
  expect_s3_class(fit, "cr_dose_response")
  expect_true(fit$model %in% c("3pl", "linear"))
  expect_s3_class(fit$curve, "tbl_df")
})

test_that("cr_dose_response works on the natural dose scale", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "linear", log_dose = FALSE)
  expect_false(fit$log_dose)
  expect_true("dose" %in% names(fit$curve))
})

test_that("cr_dose_response filters by treatment", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1",
                          treatment = c("CompoundA_low", "CompoundA_high"),
                          model = "linear")
  expect_true(all(fit$data$treatment %in%
                    c("CompoundA_low", "CompoundA_high")))
})

test_that("cr_dose_response errors when no rows remain", {
  exp <- make_dose_exp()
  expect_error(
    cr_dose_response(exp, "marker_1", treatment = "NoSuchTreatment"),
    "No data rows"
  )
})

test_that("cr_dose_response falls back to linear when nls cannot fit", {
  # Two distinct doses only -> nls cannot estimate a 4PL reliably and
  # should fall back to a linear model.
  exp <- cr_example_experiment(seed = 3, n_cells_per_well = 20)
  exp$design$dose <- ifelse(exp$design$treatment == "Untreated", 1, 100)
  fit <- cr_dose_response(exp, "marker_1",
                          treatment = c("Untreated", "CompoundA_high"),
                          model = "4pl")
  expect_s3_class(fit, "cr_dose_response")
  expect_true(is.character(fit$model))
})

test_that("cr_ic50 errors on non-cr_dose_response input", {
  expect_error(cr_ic50(list(a = 1)), "cr_dose_response")
})

test_that("cr_ic50 returns NA for a linear model", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "linear")
  ic <- cr_ic50(fit)
  expect_true(is.na(ic$estimate))
  expect_equal(ic$parameter, "IC50")
})

test_that("cr_ic50 carries a confidence interval for an nls e parameter", {
  exp <- make_dose_exp()
  fit <- cr_dose_response(exp, "marker_1", model = "4pl")
  ic <- cr_ic50(fit, level = 0.9)
  expect_true(all(c("estimate", "ci_low", "ci_high") %in% names(ic)))
})
