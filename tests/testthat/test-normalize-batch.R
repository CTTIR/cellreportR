# Tests for R/normalize-batch.R: batch keys, per-batch control
# references and per-batch standardization.


.norm_batch_exp <- function(seed = 1, n = 20) {
  exp <- cr_example_experiment(seed = seed, n_cells_per_well = n)
  exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
  exp
}

test_that("cr_batch_key collapses several columns into one key", {
  exp <- .norm_batch_exp()
  key <- cr_batch_key(exp, c("plate", "timepoint"))
  expect_type(key, "character")
  expect_length(key, nrow(exp$cells))
  expect_setequal(unique(key), c("P1 | 24", "P2 | 24"))
})

test_that("cr_batch_key works on data frames and labels NA explicitly", {
  df <- data.frame(a = c("x", NA), b = 1:2)
  expect_equal(cr_batch_key(df, "a"), c("x", "<NA>"))
  expect_equal(cr_batch_key(df, c("a", "b"), sep = "_"), c("x_1", "<NA>_2"))
  expect_equal(cr_batch_key(df[0, ], "a"), character())
})

test_that("cr_batch_key validates its inputs", {
  exp <- .norm_batch_exp(n = 10)
  expect_error(cr_batch_key(exp, character()), "non-empty")
  expect_error(cr_batch_key(exp, "not_a_column"), "not found")
  expect_error(cr_batch_key(1:3, "a"), "data frame")
})

test_that("cr_batch_reference reports one row per batch with control stats", {
  exp <- .norm_batch_exp()
  ref <- cr_batch_reference(exp, "marker_1", "Untreated", "plate")
  expect_s3_class(ref, "tbl_df")
  expect_equal(nrow(ref), 2L)
  expect_true(all(c("plate", "batch_key", "n_cells", "ctrl_n", "ctrl_mean",
                    "ctrl_median", "ctrl_sd", "has_control") %in% names(ref)))
  expect_true(all(ref$has_control))
  expect_true(all(ref$ctrl_n > 0))
  expect_equal(sum(ref$n_cells), nrow(exp$cells))
})

test_that("cr_batch_reference marks batches without controls", {
  exp <- .norm_batch_exp()
  exp$design$plate[exp$design$treatment == "Untreated"] <- "P1"
  ref <- cr_batch_reference(exp, "marker_1", "Untreated", "plate")
  expect_false(all(ref$has_control))
  expect_true(is.na(ref$ctrl_mean[!ref$has_control]))
})

test_that("cr_batch_reference floors a degenerate control standard deviation", {
  exp <- .norm_batch_exp()
  ctrl_wells <- exp$design$well[exp$design$treatment == "Untreated"]
  exp$cells$marker_1[exp$cells$well %in% ctrl_wells] <- 100
  ref <- cr_batch_reference(exp, "marker_1", "Untreated", "plate",
                            sd_floor = 1e-8)
  expect_true(all(ref$ctrl_sd > 0))
})

test_that("cr_batch_reference validates channel, control and batch columns", {
  exp <- .norm_batch_exp(n = 10)
  expect_error(cr_batch_reference(exp, "nope", "Untreated", "plate"),
               "not found")
  expect_error(cr_batch_reference(exp, "marker_1", "Untreated", "plate",
                                  control_var = "nope"), "not found")
  expect_error(cr_batch_reference(exp, "well", "Untreated", "plate"),
               "must be numeric")
  expect_error(cr_batch_reference(exp, "marker_1", character(), "plate"),
               "control_level")
})

test_that("cr_standardize_batch adds the standardized columns", {
  exp <- .norm_batch_exp()
  std <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate")
  expect_s3_class(std, "cr_experiment")
  expect_true(all(c("batch_key", "ctrl_n", "ctrl_mean", "ctrl_median",
                    "ctrl_sd", "z_ctrl", "log2_fc", "value_std") %in%
                    names(std$cells)))
  expect_equal(nrow(std$cells), nrow(exp$cells))
  expect_identical(std$cells$value_std, std$cells$log2_fc)
  expect_identical(std$batch_vars, "plate")
  expect_equal(nrow(std$batch_reference), 2L)
  expect_equal(std$metadata$standardization$method, "log2_fc")
  expect_true("standardize_batch" %in% std$qc_log$step)
})

test_that("cr_standardize_batch references each cell's own batch", {
  exp <- .norm_batch_exp()
  std <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate")
  ref <- cr_batch_reference(exp, "marker_1", "Untreated", "plate")
  expect_setequal(unique(std$cells$batch_key), ref$batch_key)
  for (k in ref$batch_key) {
    idx <- std$cells$batch_key == k
    expect_equal(unique(std$cells$ctrl_mean[idx]),
                 ref$ctrl_mean[ref$batch_key == k])
  }
  # A treated arm sits above its own control on the log2 scale.
  treated <- exp$design$well[exp$design$treatment == "PosControl"]
  expect_gt(stats::median(std$cells$log2_fc[std$cells$well %in% treated]), 1)
})

test_that("cr_standardize_batch honours method and value_to", {
  exp <- .norm_batch_exp()
  z <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                            method = "zscore")
  expect_identical(z$cells$value_std, z$cells$z_ctrl)
  raw <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                              method = "raw")
  expect_identical(raw$cells$value_std, exp$cells$marker_1)
  # Components are added whichever method is chosen.
  expect_true(all(c("z_ctrl", "log2_fc") %in% names(raw$cells)))
  named <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                                value_to = "std_value")
  expect_true("std_value" %in% names(named$cells))
  none <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                               value_to = NULL)
  expect_false("value_std" %in% names(none$cells))
})

test_that("cr_standardize_batch refuses a batch without control cells", {
  exp <- .norm_batch_exp()
  exp$design$plate[exp$design$treatment == "Untreated"] <- "P1"
  expect_error(
    cr_standardize_batch(exp, "marker_1", "Untreated", "plate"),
    "no control cells"
  )
})

test_that("cr_standardize_batch can warn or drop instead of erroring", {
  exp <- .norm_batch_exp()
  exp$design$plate[exp$design$treatment == "Untreated"] <- "P1"
  expect_warning(
    kept <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                                 on_missing_control = "warn"),
    "no control cells"
  )
  expect_equal(nrow(kept$cells), nrow(exp$cells))
  expect_true(any(is.na(kept$cells$log2_fc)))

  expect_warning(
    dropped <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                                    on_missing_control = "drop")
  )
  expect_lt(nrow(dropped$cells), nrow(exp$cells))
  expect_false(anyNA(dropped$cells$log2_fc))
  expect_true(all(dropped$batch_reference$has_control))
  expect_gt(dropped$qc_log$cells_removed[1], 0)
})

test_that("cr_standardize_batch returns NA rather than NaN for a signal at or below -eps", {
  exp <- .norm_batch_exp()
  exp$cells$marker_1[1:5] <- -50
  std <- cr_standardize_batch(exp, "marker_1", "Untreated", "plate")
  expect_true(all(is.na(std$cells$log2_fc[1:5])))
  expect_false(any(is.nan(std$cells$log2_fc)))
})

test_that("cr_standardize_batch validates channel and eps", {
  exp <- .norm_batch_exp(n = 10)
  expect_error(cr_standardize_batch(exp, "nope", "Untreated", "plate"),
               "not found")
  expect_error(cr_standardize_batch(exp, "marker_1", "Untreated", "plate",
                                    eps = NA), "single finite")
})

test_that("cr_correct_batch accepts several batch columns", {
  exp <- .norm_batch_exp(n = 15)
  exp$design$batch <- rep(c("b1", "b2"), length.out = nrow(exp$design))
  out <- cr_correct_batch(exp, c("batch", "plate"), "marker_1")
  expect_equal(nrow(out$cells), nrow(exp$cells))
  expect_error(cr_correct_batch(exp, c("batch", "nope"), "marker_1"),
               "not found in design")
})

test_that(".cr_batch_table prefers cell columns over design columns", {
  exp <- .norm_batch_exp(n = 10)
  exp$cells$timepoint <- 99
  tbl <- cellreportR:::.cr_batch_table(exp)
  expect_equal(nrow(tbl), nrow(exp$cells))
  expect_true(all(tbl$timepoint == 99))
  expect_false(any(grepl("\\.x$|\\.y$", names(tbl))))
})
