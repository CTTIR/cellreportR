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
#' @param test One of `"mann_whitney"`, `"t_test"` (pooled variance),
#'   `"welch"` (unequal variance) or `"wilcoxon_signed"` (paired).
#' @param level `"cell"` (default), `"replicate"` or `"both"`.
#'
#' @return A `cr_result` object with the elements `comparison`,
#'   `cell_level`, `rep_level`, `effect_sizes` and `fold_change`.
#'
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_test(exp,
#'                channel = "marker_1",
#'                treatment = "CompoundA_high",
#'                control = "Untreated",
#'                test = "mann_whitney",
#'                level = "replicate")
#' print(res)
#'
#' @seealso [cr_test_all()], [cr_effect_size()], [cr_effect_grid()].
#' @family statistics
#'
#' @export
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
#' and adjusts the p-values across the whole family of comparisons.
#' Both a Bonferroni and a Benjamini-Hochberg adjustment are reported
#' next to the unadjusted p-value, never in place of it.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param control_group Control group.
#' @param tests Test to run (see [cr_test()]). Only the first element
#'   is used; the argument is a vector for backwards compatibility.
#' @param p_adjust P-value adjustment method used for the `p_adj`
#'   column (see [stats::p.adjust]). The dedicated `p_bonferroni` and
#'   `p_BH` columns are always added as well.
#' @param level `"cell"`, `"replicate"` or `"both"`.
#'
#' @return A named list of `cr_result` objects, one per treatment,
#'   carrying the attributes `summary` (a tibble with `treatment`,
#'   `log2_fc`, `p_value`, `cohens_d`, `p_adj`, `p_bonferroni`,
#'   `p_BH` and `interpretation`), `control_group`, `channel` and
#'   `level`.
#'
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' all_res <- cr_test_all(exp, channel = "marker_1",
#'                        control_group = "Untreated",
#'                        level = "replicate")
#' attr(all_res, "summary")
#' }
#'
#' @seealso [cr_test()], [cr_effect_grid()].
#' @family statistics
#'
#' @export
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
  summary_tbl$p_bonferroni <- stats::p.adjust(summary_tbl$p_value,
                                              method = "bonferroni")
  summary_tbl$p_BH <- stats::p.adjust(summary_tbl$p_value, method = "BH")
  summary_tbl$interpretation <- .cr_interpret(summary_tbl$p_adj,
                                              summary_tbl$cohens_d)
  attr(results, "summary") <- summary_tbl
  attr(results, "control_group") <- control_group
  attr(results, "channel") <- channel
  attr(results, "level") <- level
  results
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

.cr_interpret <- function(p, d) {
  out <- rep("no evidence", length(p))
  out[!is.na(p) & p < 0.05 & !is.na(d) & abs(d) >= 0.8] <- "strong"
  out[!is.na(p) & p < 0.05 & !is.na(d) & abs(d) >= 0.5 & abs(d) < 0.8] <- "moderate"
  out[!is.na(p) & p < 0.05 & !is.na(d) & abs(d) < 0.5] <- "weak"
  out
}

# ---- shared helpers for the statistics module --------------------------

# Internal: accept either a data frame or a cr_experiment. For an
# experiment the design is joined onto the cells so that design columns
# (treatment, plate, ...) are available as ordinary columns.
.cr_stat_data <- function(data, arg = "data", call = rlang::caller_env()) {
  if (inherits(data, "cr_experiment")) {
    return(tibble::as_tibble(.cr_join_design(data)))
  }
  if (!is.data.frame(data)) {
    cli::cli_abort(
      c("{.arg {arg}} must be a data frame or a {.cls cr_experiment}.",
        "x" = "Got {.cls {class(data)[[1L]]}} instead."),
      call = call
    )
  }
  tibble::as_tibble(data)
}

# Internal: assert that columns exist, naming the offenders.
.cr_require_cols <- function(data, cols, arg = "data",
                             call = rlang::caller_env()) {
  cols <- cols[!vapply(cols, is.null, logical(1))]
  cols <- unique(unlist(cols, use.names = FALSE))
  missing <- setdiff(cols, names(data))
  if (length(missing)) {
    cli::cli_abort(
      c("{.arg {arg}} is missing the column{?s} {.field {missing}}.",
        "i" = "Available columns: {.field {names(data)}}."),
      call = call
    )
  }
  invisible(cols)
}

# Internal: the reference arm has to exist before any contrast is built.
.cr_check_reference <- function(g, reference_level, group_var,
                                call = rlang::caller_env()) {
  if (length(reference_level) != 1L || is.na(reference_level)) {
    cli::cli_abort("{.arg reference_level} must be a single level.",
                   call = call)
  }
  present <- if (is.factor(g)) levels(g) else unique(as.character(g))
  if (!as.character(reference_level) %in% as.character(present)) {
    cli::cli_abort(
      c("Level {.val {reference_level}} is not present in {.field {group_var}}.",
        "i" = "Levels found: {.val {present}}."),
      call = call
    )
  }
  invisible(reference_level)
}

# Internal: split row indices by one or more grouping columns, keeping
# the original column types (and factor levels) in the key tibble.
.cr_stat_groups <- function(data, by) {
  if (is.null(by) || !length(by)) {
    return(list(list(idx = seq_len(nrow(data)), key = tibble::tibble())))
  }
  keys <- lapply(by, function(b) as.character(data[[b]]))
  flat <- do.call(paste, c(keys, list(sep = "\r")))
  idx <- split(seq_len(nrow(data)), factor(flat, levels = unique(flat)))
  lapply(unname(idx), function(i) {
    list(idx = i, key = data[i[1L], by, drop = FALSE])
  })
}

# Internal: comparison levels present in a grouping column, excluding
# the reference level and preserving factor level order where given.
.cr_comparison_levels <- function(g, reference_level, comparison_levels) {
  if (!is.null(comparison_levels)) return(comparison_levels)
  lv <- if (is.factor(g)) levels(g) else unique(as.character(g))
  setdiff(lv, reference_level)
}

# Internal: a single numeric scalar in a range.
.cr_check_prob <- function(x, arg = rlang::caller_arg(x),
                           lower = 0, upper = 1,
                           call = rlang::caller_env()) {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) ||
      x <= lower || x >= upper) {
    cli::cli_abort(
      c("{.arg {arg}} must be a single number between {lower} and {upper}.",
        "x" = "Got {.val {x}}."),
      call = call
    )
  }
  invisible(x)
}

# Version 0.1.0
