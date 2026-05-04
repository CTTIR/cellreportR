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
