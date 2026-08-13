test_that("cr_logistic returns an AUC", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  expect_s3_class(res, "cr_result")
  expect_false(is.null(res$roc))
  expect_gt(res$roc$auc, 0.7)
})

test_that("cr_roc returns a tibble with fpr/tpr", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  tbl <- cr_roc(res)
  expect_s3_class(tbl, "tbl_df")
  expect_true(all(c("fpr", "tpr", "threshold") %in% names(tbl)))
})

test_that("cr_auc returns CI when possible", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  auc_tbl <- cr_auc(res)
  expect_true(!is.na(auc_tbl$auc))
})

test_that("cr_confusion_matrix computes metrics at 0.5", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  cm <- cr_confusion_matrix(res, threshold = 0.5)
  expect_true(all(c("sensitivity", "specificity", "accuracy") %in% names(cm)))
  expect_true(cm$sensitivity >= 0 && cm$sensitivity <= 1)
})

# --- additional coverage -------------------------------------------------

test_that("cr_logistic fits at replicate level", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated",
                     level = "replicate")
  expect_s3_class(res, "cr_result")
  expect_equal(res$comparison$level, "replicate")
  expect_gt(nrow(res$rep_level), 0)
  expect_equal(nrow(res$cell_level), 0L)
})

test_that("cr_logistic rejects an absent channel and a one-sided contrast", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_error(cr_logistic(exp, "nope", "CompoundA_high", "Untreated"),
               "not found")
  expect_error(cr_logistic(exp, "marker_1", "Untreated", "Untreated"),
               "two distinct groups")
})

test_that("cr_roc rejects anything but a result carrying a curve", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  expect_error(cr_roc(42), "must be a")
  expect_error(cr_roc(list(roc = NULL)), "must be a")
  plain <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                   level = "cell")
  expect_error(cr_roc(plain), "No ROC data available")
})

test_that("cr_auc reports a bootstrap interval and rejects bad input", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  boot <- suppressWarnings(cr_auc(res, ci_method = "bootstrap", n_boot = 25))
  expect_equal(boot$method, "bootstrap")
  expect_false(is.na(boot$auc))
  expect_error(cr_auc(42), "must be a")
  no_model <- res
  no_model$model <- list()
  expect_error(cr_auc(no_model), "No fitted model")
})

test_that("cr_confusion_matrix handles extreme thresholds and bad input", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  # Nothing is called positive, so the positive predictive value is
  # undefined rather than zero.
  none <- cr_confusion_matrix(res, threshold = 1.1)
  expect_equal(none$tp, 0L)
  expect_equal(none$fp, 0L)
  expect_true(is.na(none$ppv))
  all_pos <- cr_confusion_matrix(res, threshold = -0.1)
  expect_equal(all_pos$tn, 0L)
  expect_true(is.na(all_pos$npv))
  expect_error(cr_confusion_matrix(42), "must be a")
  no_model <- res
  no_model$model <- list()
  expect_error(cr_confusion_matrix(no_model), "No fitted model")
})
