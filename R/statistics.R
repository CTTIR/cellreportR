#' Hypothesis test comparing treatment to control
#'
#' Runs a parametric or non-parametric two-sample test comparing
#' cells (or replicate summaries) from a treatment group to the
#' control group on a single channel.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel to test.
#' @param treatment Name of the treatment group (matches
#'   `design$treatment`).
#' @param control Name of the control group.
#' @param test One of `"mann_whitney"`, `"t_test"`, `"welch"`,
#'   `"wilcoxon_signed"`, `"kruskal"`, `"anova"`. For two-group
#'   tests, the first four are valid. `"kruskal"` and `"anova"` can
#'   be used only with `cr_test_all()` where additional groups are
#'   compared together.
#' @param level `"cell"` (default) or `"replicate"`.
#'
#' @return A `cr_result` object.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_test(exp,
#'                channel = "marker_1",
#'                treatment = "CompoundA_high",
#'                control = "Untreated",
#'                test = "mann_whitney",
#'                level = "replicate")
#' print(res)
cr_test <- function(experiment,
                    channel,
                    treatment,
                    control,
                    test = c("mann_whitney", "t_test", "welch",
                             "wilcoxon_signed"),
                    level = c("cell", "replicate", "both")) {
  cr_validate_experiment(experiment)
  test <- match.arg(test)
  level <- match.arg(level)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  joined <- .cr_join_design(experiment)
  joined <- joined[joined$treatment %in% c(treatment, control), , drop = FALSE]
  if (!nrow(joined)) {
    cli::cli_abort("No cells match treatment/control {.val {treatment}} / {.val {control}}.")
  }

  cell_level <- NULL
  if (level %in% c("cell", "both")) {
    cell_level <- .cr_do_test(
      joined[[channel]][joined$treatment == treatment],
      joined[[channel]][joined$treatment == control],
      test = test, grouping = "cell"
    )
  }

  rep_level <- NULL
  if (level %in% c("replicate", "both")) {
    wells <- cr_summarize_wells(experiment, channel, fun = stats::median)
    wells <- wells[wells$treatment %in% c(treatment, control), , drop = FALSE]
    rep_level <- .cr_do_test(
      wells$value[wells$treatment == treatment],
      wells$value[wells$treatment == control],
      test = test, grouping = "replicate"
    )
  }

  eff <- cr_effect_size(
    joined[[channel]][joined$treatment == treatment],
    joined[[channel]][joined$treatment == control],
    method = c("cohens_d", "hedges_g", "cliffs_delta", "rank_biserial")
  )

  fc <- cr_fold_change(experiment, channel = channel,
                       control_group = control)$summary
  fc <- fc[fc$treatment %in% c(treatment, control), , drop = FALSE]

  .cr_new_result(
    comparison = list(channel = channel,
                      treatment = treatment,
                      control = control,
                      test = test,
                      level = level),
    cell_level = cell_level,
    rep_level = rep_level,
    effect_sizes = eff,
    fold_change = fc
  )
}

#' Test all treatments against a control group
#'
#' Runs [cr_test()] pairwise for every treatment versus the control
#' and adjusts p-values across comparisons.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param control_group Control group.
#' @param tests Tests to run (see [cr_test()]). First one is used
#'   for the summary p-value.
#' @param p_adjust P-value adjustment method (see [stats::p.adjust]).
#' @param level `"cell"` or `"replicate"` or `"both"`.
#' @return A list of `cr_result` objects plus an attribute
#'   `summary` holding a single overview tibble.
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' all_res <- cr_test_all(exp, channel = "marker_1",
#'                        control_group = "Untreated",
#'                        level = "replicate")
#' attr(all_res, "summary")
#' }
cr_test_all <- function(experiment,
                        channel,
                        control_group,
                        tests = "mann_whitney",
                        p_adjust = "BH",
                        level = c("replicate", "cell", "both")) {
  cr_validate_experiment(experiment)
  level <- match.arg(level)
  treatments <- setdiff(unique(experiment$design$treatment), control_group)
  if (!length(treatments)) {
    cli::cli_abort("No treatments to compare against {.val {control_group}}.")
  }
  results <- lapply(treatments, function(t) {
    cr_test(experiment, channel = channel, treatment = t,
            control = control_group, test = tests[1], level = level)
  })
  names(results) <- treatments

  summary_tbl <- dplyr::bind_rows(lapply(treatments, function(t) {
    res <- results[[t]]
    lvl_tbl <- if (level == "cell") res$cell_level else res$rep_level
    pv <- if (!is.null(lvl_tbl) && nrow(lvl_tbl)) lvl_tbl$p_value[1] else NA_real_
    d_row <- res$effect_sizes[res$effect_sizes$method == "cohens_d", ]
    d_val <- if (nrow(d_row)) d_row$estimate[1] else NA_real_
    fc_row <- res$fold_change[res$fold_change$treatment == t, ]
    fc_val <- if (nrow(fc_row)) fc_row$median_log2_fc[1] else NA_real_
    tibble::tibble(
      treatment = t,
      log2_fc = fc_val,
      p_value = pv,
      cohens_d = d_val
    )
  }))
  summary_tbl$p_adj <- stats::p.adjust(summary_tbl$p_value, method = p_adjust)
  summary_tbl$interpretation <- .cr_interpret(summary_tbl$p_adj,
                                              summary_tbl$cohens_d)
  attr(results, "summary") <- summary_tbl
  attr(results, "control_group") <- control_group
  attr(results, "channel") <- channel
  attr(results, "level") <- level
  results
}

#' Compute effect sizes between two samples
#'
#' @param x Numeric vector (treatment group).
#' @param y Numeric vector (control / reference group).
#' @param method Character vector of methods to compute. Allowed:
#'   `"cohens_d"`, `"hedges_g"`, `"cliffs_delta"`,
#'   `"rank_biserial"`, `"glass_delta"`.
#' @param ci Confidence level for bootstrap CI (default 0.95). Set
#'   `NULL` to skip.
#' @param n_boot Number of bootstrap resamples used for the CI.
#' @return A tibble with columns `method`, `estimate`,
#'   `ci_low`, `ci_high`, `magnitude`.
#' @export
#' @examples
#' set.seed(1)
#' cr_effect_size(stats::rnorm(100, 1), stats::rnorm(100, 0))
cr_effect_size <- function(x, y,
                           method = c("cohens_d", "hedges_g",
                                      "cliffs_delta", "rank_biserial"),
                           ci = 0.95,
                           n_boot = 200) {
  method <- match.arg(method, several.ok = TRUE)
  x <- stats::na.omit(x); y <- stats::na.omit(y)
  out <- lapply(method, function(m) {
    est <- .cr_effsize(x, y, m)
    ci_vals <- c(NA_real_, NA_real_)
    if (!is.null(ci) && length(x) > 2 && length(y) > 2) {
      boots <- replicate(n_boot, {
        .cr_effsize(sample(x, replace = TRUE),
                    sample(y, replace = TRUE), m)
      })
      probs <- c((1 - ci) / 2, 1 - (1 - ci) / 2)
      ci_vals <- as.numeric(stats::quantile(boots, probs, na.rm = TRUE))
    }
    tibble::tibble(method = m, estimate = est,
                   ci_low = ci_vals[1], ci_high = ci_vals[2],
                   magnitude = .cr_magnitude(est, m))
  })
  dplyr::bind_rows(out)
}

#' Post-hoc power for a hierarchical cell-based assay
#'
#' A Monte-Carlo approximation that accounts for the hierarchical
#' structure (cells nested within replicates). Used mainly for
#' reporting.
#'
#' @param effect_size Cohen's d.
#' @param n_replicates Number of replicate units per group.
#' @param n_cells_per_rep Cells per replicate.
#' @param alpha Type I error rate.
#' @param test Only `"t_test"` implemented.
#' @param n_sim Number of simulations (default 500).
#' @return A tibble with the computed power.
#' @export
#' @examples
#' cr_power_analysis(effect_size = 0.8, n_replicates = 4,
#'                   n_cells_per_rep = 100)
cr_power_analysis <- function(effect_size,
                              n_replicates,
                              n_cells_per_rep,
                              alpha = 0.05,
                              test = "t_test",
                              n_sim = 500) {
  if (test != "t_test") {
    cli::cli_abort("Only t_test is implemented at present.")
  }
  positives <- replicate(n_sim, {
    x_means <- vapply(seq_len(n_replicates), function(i) {
      mean(stats::rnorm(n_cells_per_rep, mean = effect_size))
    }, numeric(1))
    y_means <- vapply(seq_len(n_replicates), function(i) {
      mean(stats::rnorm(n_cells_per_rep, mean = 0))
    }, numeric(1))
    tt <- suppressWarnings(stats::t.test(x_means, y_means))
    tt$p.value < alpha
  })
  tibble::tibble(
    effect_size = effect_size,
    n_replicates = n_replicates,
    n_cells_per_rep = n_cells_per_rep,
    alpha = alpha,
    power = mean(positives)
  )
}

# Internal: run a two-sample test
.cr_do_test <- function(x, y, test, grouping) {
  x <- stats::na.omit(x); y <- stats::na.omit(y)
  res <- switch(
    test,
    mann_whitney = suppressWarnings(stats::wilcox.test(x, y,
                                                       exact = FALSE)),
    t_test = suppressWarnings(stats::t.test(x, y, var.equal = TRUE)),
    welch = suppressWarnings(stats::t.test(x, y, var.equal = FALSE)),
    wilcoxon_signed = {
      n <- min(length(x), length(y))
      suppressWarnings(stats::wilcox.test(x[seq_len(n)], y[seq_len(n)],
                                          paired = TRUE, exact = FALSE))
    }
  )
  tibble::tibble(
    level = grouping,
    test = test,
    statistic = unname(res$statistic),
    p_value = res$p.value,
    n_x = length(x),
    n_y = length(y),
    median_x = stats::median(x),
    median_y = stats::median(y)
  )
}

# Internal: one effect size
.cr_effsize <- function(x, y, m) {
  switch(
    m,
    cohens_d = {
      s <- sqrt(((length(x) - 1) * stats::var(x) +
                   (length(y) - 1) * stats::var(y)) /
                  (length(x) + length(y) - 2))
      if (s == 0) return(NA_real_)
      (mean(x) - mean(y)) / s
    },
    hedges_g = {
      s <- sqrt(((length(x) - 1) * stats::var(x) +
                   (length(y) - 1) * stats::var(y)) /
                  (length(x) + length(y) - 2))
      if (s == 0) return(NA_real_)
      d <- (mean(x) - mean(y)) / s
      df <- length(x) + length(y) - 2
      d * (1 - 3 / (4 * df - 1))
    },
    cliffs_delta = {
      gt <- mean(outer(x, y, ">"))
      lt <- mean(outer(x, y, "<"))
      gt - lt
    },
    rank_biserial = {
      ww <- suppressWarnings(stats::wilcox.test(x, y, exact = FALSE))
      u <- ww$statistic
      1 - 2 * u / (length(x) * length(y))
    },
    glass_delta = {
      s <- stats::sd(y)
      if (s == 0) return(NA_real_)
      (mean(x) - mean(y)) / s
    },
    NA_real_
  )
}

.cr_magnitude <- function(est, m) {
  if (is.na(est)) return(NA_character_)
  a <- abs(est)
  if (m %in% c("cohens_d", "hedges_g", "glass_delta")) {
    if (a < 0.2) return("negligible")
    if (a < 0.5) return("small")
    if (a < 0.8) return("medium")
    return("large")
  }
  if (m == "cliffs_delta") {
    if (a < 0.147) return("negligible")
    if (a < 0.33) return("small")
    if (a < 0.474) return("medium")
    return("large")
  }
  if (m == "rank_biserial") {
    if (a < 0.1) return("negligible")
    if (a < 0.3) return("small")
    if (a < 0.5) return("medium")
    return("large")
  }
  NA_character_
}

.cr_interpret <- function(p, d) {
  out <- rep("no evidence", length(p))
  out[!is.na(p) & p < 0.05 & !is.na(d) & abs(d) >= 0.8] <- "strong"
  out[!is.na(p) & p < 0.05 & !is.na(d) & abs(d) >= 0.5 & abs(d) < 0.8] <- "moderate"
  out[!is.na(p) & p < 0.05 & !is.na(d) & abs(d) < 0.5] <- "weak"
  out
}
