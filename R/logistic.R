#' Univariate logistic regression of treatment vs. control
#'
#' Fits a univariate logistic regression on a single fluorescence
#' channel for the binary outcome `treatment == treatment` (vs.
#' `treatment == control`). Returns a `cr_result` with the fitted
#' model, ROC curve and AUC.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param treatment Name of treatment group.
#' @param control Name of control group.
#' @param level `"cell"` (default) or `"replicate"`.
#' @return A `cr_result`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_logistic(exp,
#'                    channel = "marker_1",
#'                    treatment = "CompoundA_high",
#'                    control = "Untreated")
#' print(res)
cr_logistic <- function(experiment,
                        channel,
                        treatment,
                        control,
                        level = c("cell", "replicate")) {
  cr_validate_experiment(experiment)
  level <- match.arg(level)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  if (level == "cell") {
    joined <- .cr_join_design(experiment)
    joined <- joined[joined$treatment %in% c(treatment, control), , drop = FALSE]
    resp <- as.integer(joined$treatment == treatment)
    pred <- joined[[channel]]
  } else {
    wells <- cr_summarize_wells(experiment, channel, stats::median)
    wells <- wells[wells$treatment %in% c(treatment, control), , drop = FALSE]
    resp <- as.integer(wells$treatment == treatment)
    pred <- wells$value
  }

  data <- data.frame(resp = resp, pred = pred)
  data <- stats::na.omit(data)
  if (!length(unique(data$resp)) == 2L) {
    cli::cli_abort("Need two distinct groups for logistic regression.")
  }
  model <- suppressWarnings(
    stats::glm(resp ~ pred, family = stats::binomial(), data = data)
  )

  probs <- as.numeric(stats::predict(model, type = "response"))
  roc_obj <- tryCatch(
    pROC::roc(response = data$resp, predictor = probs, quiet = TRUE,
              levels = c(0, 1), direction = "<"),
    error = function(e) NULL
  )
  roc_tbl <- NULL
  auc_val <- NA_real_
  ci_low <- NA_real_
  ci_high <- NA_real_
  if (!is.null(roc_obj)) {
    auc_val <- as.numeric(pROC::auc(roc_obj))
    tryCatch({
      ci <- pROC::ci.auc(roc_obj)
      ci_low <- ci[1]; ci_high <- ci[3]
    }, error = function(e) NULL)
    roc_tbl <- tibble::tibble(
      threshold = as.numeric(roc_obj$thresholds),
      sensitivity = as.numeric(roc_obj$sensitivities),
      specificity = as.numeric(roc_obj$specificities)
    )
    roc_tbl$fpr <- 1 - roc_tbl$specificity
    roc_tbl$tpr <- roc_tbl$sensitivity
  }

  roc_list <- list(
    roc_table = roc_tbl,
    auc = auc_val,
    ci_low = ci_low,
    ci_high = ci_high
  )

  # Effect sizes on the original scale
  eff <- cr_effect_size(
    x = data$pred[data$resp == 1],
    y = data$pred[data$resp == 0],
    method = c("cohens_d", "cliffs_delta")
  )

  .cr_new_result(
    comparison = list(channel = channel,
                      treatment = treatment,
                      control = control,
                      test = "logistic",
                      level = level),
    cell_level = if (level == "cell") .cr_logistic_summary(model) else NULL,
    rep_level = if (level == "replicate") .cr_logistic_summary(model) else NULL,
    effect_sizes = eff,
    roc = roc_list,
    model = list(model = model, coefficients = stats::coef(model))
  )
}

#' Extract or compute an ROC curve from a `cr_result`
#'
#' @param result A `cr_result` produced by [cr_logistic()].
#' @return A tibble with `threshold`, `sensitivity`, `specificity`,
#'   `fpr` and `tpr`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
#' head(cr_roc(res))
cr_roc <- function(result) {
  if (!inherits(result, "cr_result")) {
    cli::cli_abort("`result` must be a {.cls cr_result}.")
  }
  if (is.null(result$roc) || is.null(result$roc$roc_table)) {
    cli::cli_abort("No ROC data available in this result.")
  }
  result$roc$roc_table
}

#' Compute AUC with confidence interval from a `cr_result`
#'
#' @param result A `cr_result` from [cr_logistic()].
#' @param ci_method `"delong"` (default) or `"bootstrap"`.
#' @param n_boot Number of bootstrap resamples for `"bootstrap"`.
#' @return A tibble with `auc`, `ci_low`, `ci_high`, `method`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
#' cr_auc(res)
cr_auc <- function(result,
                   ci_method = c("delong", "bootstrap"),
                   n_boot = 1000) {
  if (!inherits(result, "cr_result")) {
    cli::cli_abort("`result` must be a {.cls cr_result}.")
  }
  ci_method <- match.arg(ci_method)
  model <- result$model$model
  if (is.null(model)) {
    cli::cli_abort("No fitted model present in the result.")
  }
  resp <- model$model$resp
  probs <- as.numeric(stats::predict(model, type = "response"))
  roc_obj <- tryCatch(
    pROC::roc(response = resp, predictor = probs, quiet = TRUE,
              levels = c(0, 1), direction = "<"),
    error = function(e) NULL
  )
  if (is.null(roc_obj)) {
    return(tibble::tibble(auc = NA_real_, ci_low = NA_real_,
                          ci_high = NA_real_, method = ci_method))
  }
  auc_val <- as.numeric(pROC::auc(roc_obj))
  ci_low <- NA_real_; ci_high <- NA_real_
  tryCatch({
    if (ci_method == "delong") {
      ci <- pROC::ci.auc(roc_obj, method = "delong")
    } else {
      ci <- pROC::ci.auc(roc_obj, method = "bootstrap", boot.n = n_boot)
    }
    ci_low <- ci[1]; ci_high <- ci[3]
  }, error = function(e) NULL)
  tibble::tibble(auc = auc_val,
                 ci_low = ci_low, ci_high = ci_high,
                 method = ci_method)
}

#' Confusion matrix for a logistic `cr_result`
#'
#' @param result A `cr_result` from [cr_logistic()].
#' @param threshold Classification threshold on predicted probability
#'   (default `0.5`).
#' @return A tibble with `sensitivity`, `specificity`, `ppv`, `npv`,
#'   `accuracy`, and the confusion-matrix counts.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
#' cr_confusion_matrix(res, 0.5)
cr_confusion_matrix <- function(result, threshold = 0.5) {
  if (!inherits(result, "cr_result")) {
    cli::cli_abort("`result` must be a {.cls cr_result}.")
  }
  model <- result$model$model
  if (is.null(model)) cli::cli_abort("No fitted model available.")
  resp <- model$model$resp
  probs <- as.numeric(stats::predict(model, type = "response"))
  pred <- as.integer(probs >= threshold)
  tp <- sum(pred == 1 & resp == 1)
  tn <- sum(pred == 0 & resp == 0)
  fp <- sum(pred == 1 & resp == 0)
  fn <- sum(pred == 0 & resp == 1)
  tibble::tibble(
    threshold = threshold,
    sensitivity = if ((tp + fn) > 0) tp / (tp + fn) else NA_real_,
    specificity = if ((tn + fp) > 0) tn / (tn + fp) else NA_real_,
    ppv = if ((tp + fp) > 0) tp / (tp + fp) else NA_real_,
    npv = if ((tn + fn) > 0) tn / (tn + fn) else NA_real_,
    accuracy = (tp + tn) / max(length(resp), 1),
    tp = tp, tn = tn, fp = fp, fn = fn
  )
}

.cr_logistic_summary <- function(model) {
  co <- summary(model)$coefficients
  tibble::tibble(
    term = rownames(co),
    estimate = co[, 1],
    std_error = co[, 2],
    z_value = co[, 3],
    p_value = co[, 4]
  )
}
