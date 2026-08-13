# Result figures -------------------------------------------------------------
#
# Figures drawn from a fitted result rather than from the raw cells: fold
# changes, effect sizes, discriminability and dose-response.

#' Fold-change forest plot
#'
#' @param result A `cr_result`, a list of `cr_result`s (from
#'   [cr_test_all()]), or a precomputed data frame with columns
#'   `treatment`, `median_log2_fc`.
#' @return A `ggplot` object.
#' @seealso [cr_plot_forest()] for effect sizes with confidence intervals.
#' @family visualisation
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
#' cr_plot_foldchange(res)
#' }
cr_plot_foldchange <- function(result) {
  df <- .cr_fc_dataframe(result)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$median_log2_fc,
                                   y = stats::reorder(.data$treatment,
                                                      .data$median_log2_fc))) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey50", linetype = 2) +
    ggplot2::geom_col(fill = unname(cr_palette(1L)), alpha = 0.85,
                      colour = "grey25", linewidth = 0.2) +
    ggplot2::labs(x = "log2 fold change", y = NULL,
                  title = "Fold change vs. control") +
    cr_theme()
}

.cr_fc_dataframe <- function(result) {
  if (is.data.frame(result)) return(result)
  if (inherits(result, "cr_result")) return(result$fold_change)
  if (is.list(result)) {
    s <- attr(result, "summary")
    if (!is.null(s) && "log2_fc" %in% names(s)) {
      return(tibble::tibble(treatment = s$treatment,
                            median_log2_fc = s$log2_fc))
    }
    parts <- lapply(result, function(r) r$fold_change)
    return(dplyr::distinct(dplyr::bind_rows(parts)))
  }
  cli::cli_abort("Unsupported result type for {.fn cr_plot_foldchange}.")
}

#' Forest plot of effect sizes
#'
#' Convenience wrapper around [cr_plot_forest()] for the result objects
#' produced by [cr_test()] and [cr_test_all()]. Use [cr_plot_forest()]
#' directly for an effect-size table with its own labelling, facetting or
#' colouring.
#'
#' @param results A single `cr_result`, a list of `cr_result`s (from
#'   [cr_test_all()]) or a precomputed tibble with columns
#'   `treatment`, `method`, `estimate`, `ci_low`, `ci_high`.
#' @param method Effect-size method to plot (default `"cohens_d"`).
#' @param ... Further arguments passed to [cr_plot_forest()], for example
#'   `facet_by`, `colour_by` or `descending`.
#' @return A `ggplot` object.
#' @seealso [cr_plot_forest()]
#' @family visualisation
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
#' cr_plot_effect_sizes(all_res)
#' }
cr_plot_effect_sizes <- function(results, method = "cohens_d", ...) {
  df <- .cr_effect_sizes_df(results, method)
  args <- list(...)
  if (is.null(args$label)) args$label <- "treatment"
  if (is.null(args$x_lab)) {
    args$x_lab <- sprintf("effect size (%s, 95%% CI)", method)
  }
  do.call(cr_plot_forest, c(list(effects = df, method = method), args))
}

.cr_effect_sizes_df <- function(results, method) {
  if (is.data.frame(results)) {
    return(results[results$method == method, , drop = FALSE])
  }
  if (inherits(results, "cr_result")) {
    df <- results$effect_sizes[results$effect_sizes$method == method, ]
    df$treatment <- results$comparison$treatment
    return(df)
  }
  if (is.list(results)) {
    parts <- lapply(names(results), function(nm) {
      r <- results[[nm]]
      row <- r$effect_sizes[r$effect_sizes$method == method, , drop = FALSE]
      if (nrow(row)) row$treatment <- r$comparison$treatment %||% nm
      row
    })
    return(dplyr::bind_rows(parts))
  }
  cli::cli_abort("Unsupported input to {.fn cr_plot_effect_sizes}.")
}

#' ROC curve plot
#'
#' @param result A single `cr_result` or a list of such results.
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
#' cr_plot_roc(res)
cr_plot_roc <- function(result) {
  df <- .cr_roc_df(result)
  label_df <- unique(df[, c("name", "auc")])
  ggplot2::ggplot(df, ggplot2::aes(x = .data$fpr, y = .data$tpr,
                                   colour = .data$name,
                                   linetype = .data$name)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60",
                         linetype = 2) +
    ggplot2::geom_path(linewidth = 1) +
    cr_scale_group(c("colour", "linetype"), name = NULL,
                   guide_for = "all") +
    ggplot2::labs(x = "False Positive Rate",
                  y = "True Positive Rate",
                  colour = NULL,
                  title = sprintf(
                    "ROC (AUC %s)",
                    paste(
                      sprintf("%s: %.3f", label_df$name, label_df$auc),
                      collapse = " / "
                    ))) +
    cr_theme()
}

.cr_roc_df <- function(result) {
  if (inherits(result, "cr_result")) {
    tbl <- cr_roc(result)
    tbl$name <- result$comparison$treatment %||% "comparison"
    tbl$auc <- result$roc$auc
    return(tbl)
  }
  if (is.list(result)) {
    parts <- lapply(names(result), function(nm) {
      r <- result[[nm]]
      if (!inherits(r, "cr_result") || is.null(r$roc)) return(NULL)
      tbl <- cr_roc(r)
      tbl$name <- r$comparison$treatment %||% nm
      tbl$auc <- r$roc$auc
      tbl
    })
    return(dplyr::bind_rows(parts))
  }
  cli::cli_abort("Unsupported input to {.fn cr_plot_roc}.")
}

#' Dose-response plot
#'
#' @param fit A `cr_dose_response`.
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
#'                           500, exp$design$dose)
#' fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
#' cr_plot_dose_response(fit)
cr_plot_dose_response <- function(fit) {
  if (!inherits(fit, "cr_dose_response")) {
    cli::cli_abort("`fit` must be a {.cls cr_dose_response}.")
  }
  ic50 <- cr_ic50(fit)
  data <- fit$data[, c("dose", "value", "treatment")]
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data$dose,
                                          y = .data$value)) +
    ggplot2::geom_point(ggplot2::aes(colour = .data$treatment,
                                     shape = .data$treatment),
                        alpha = 0.85, size = 2) +
    ggplot2::geom_line(data = fit$curve,
                       ggplot2::aes(x = .data$dose, y = .data$y),
                       colour = "grey25", linewidth = 1) +
    cr_scale_group(c("colour", "shape"), name = "treatment",
                   guide_for = "all") +
    ggplot2::labs(x = "dose", y = fit$channel,
                  title = "Dose-response",
                  subtitle = if (!is.na(ic50$estimate)) {
                    sprintf("IC50 / EC50 = %.3g %s",
                            ic50$estimate,
                            ic50$units %||% "")
                  } else {
                    NULL
                  }) +
    cr_theme()
  if (fit$log_dose) p <- p + ggplot2::scale_x_log10()
  p
}

#' Comparison panel (box, fold change, p-value) for a single result
#'
#' @param result A `cr_result`.
#' @param experiment A `cr_experiment` (required to reconstruct the
#'   underlying intensity data).
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
#'                test = "mann_whitney", level = "replicate")
#' cr_plot_comparison(res, exp)
cr_plot_comparison <- function(result, experiment) {
  if (!inherits(result, "cr_result")) {
    cli::cli_abort("`result` must be a {.cls cr_result}.")
  }
  cr_validate_experiment(experiment)
  cmp <- result$comparison
  joined <- .cr_join_design(experiment)
  joined <- joined[joined$treatment %in% c(cmp$treatment, cmp$control), , drop = FALSE]
  p_val <- NA_real_
  if (nrow(result$rep_level)) p_val <- result$rep_level$p_value[1]
  else if (nrow(result$cell_level)) p_val <- result$cell_level$p_value[1]

  ggplot2::ggplot(joined, ggplot2::aes(x = .data$treatment,
                                       y = .data[[cmp$channel]],
                                       fill = .data$treatment)) +
    ggplot2::geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
    ggplot2::geom_boxplot(width = 0.15, outlier.size = 0.3, alpha = 0.8) +
    ggplot2::scale_y_log10() +
    cr_scale_group("fill", guide_for = "none") +
    ggplot2::labs(x = NULL, y = cmp$channel,
                  title = sprintf("%s vs %s", cmp$treatment, cmp$control),
                  subtitle = if (!is.na(p_val)) {
                    sprintf("%s p = %.3g", cmp$test, p_val)
                  } else {
                    NULL
                  }) +
    cr_theme() +
    ggplot2::theme(legend.position = "none")
}

# Version 0.1.0
