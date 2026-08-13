#' Effect sizes for a whole grid of contrasts
#'
#' Drives [cr_effect_size()] over every group in a screen: for each
#' stratum given by `by`, each comparison level of `group_var` is
#' contrasted against `reference_level`, and every requested effect
#' size is reported with a confidence interval. The same function
#' serves both aggregation levels: supply `unit` to aggregate the rows
#' to one value per experimental unit (the unit of replication) before
#' the contrast is computed, or leave it `NULL` to work on the rows as
#' they are (typically single cells).
#'
#' Cell-level intervals are anticonservative by construction, because
#' cells within a unit are not independent. Compute both levels and
#' pass them to [cr_compare_levels()] to quantify the difference;
#' interpretation belongs to the unit level.
#'
#' Multiplicity adjustment is applied across the entire returned grid
#' and reported *alongside* the unadjusted p-value, never in place of
#' it: for an exploratory screen the effect sizes and their intervals
#' are the reportable quantity.
#'
#' @param data A data frame (one row per cell or per unit) or a
#'   `cr_experiment`, in which case the design is joined onto the
#'   cells first.
#' @param value Name of the numeric response column, for example a
#'   standardized log2 fold change or a raw channel.
#' @param group_var Name of the column holding the compared groups.
#' @param reference_level Level of `group_var` used as the reference
#'   arm of every contrast.
#' @param comparison_levels Levels contrasted against the reference.
#'   `NULL` (default) uses every other level present, in factor-level
#'   order when `group_var` is a factor.
#' @param by Optional character vector of stratifying columns. One set
#'   of contrasts is computed per combination, for example one per
#'   compound.
#' @param unit Optional name of the column identifying the unit of
#'   replication. When given, rows are averaged to one value per unit
#'   before the contrast is computed.
#' @param methods Effect sizes to compute; see [cr_effect_size()].
#' @param conf_level Confidence level for the intervals.
#' @param min_n Minimum number of observations required in *each* arm.
#'   Contrasts below it are skipped and recorded in the `skipped`
#'   attribute. Use 3 for unit level and something like 10 for cell
#'   level.
#' @param test P-value to accompany the effect sizes: `"t"` (Welch
#'   two-sample t-test, the default), `"wilcox"` or `"none"`.
#' @param p_adjust Multiplicity adjustments applied across the grid.
#'   Default both `"bonferroni"` and `"BH"`; see [stats::p.adjust()].
#' @param level Optional label written into the `level` column.
#'   Defaults to `"unit"` when `unit` is given and `"cell"` otherwise.
#'
#' @return A tibble with one row per stratum and contrast: the `by`
#'   columns, `contrast`, `level`, `n_ref`, `n_cmp`, `mean_shift`, one
#'   `<method>`, `<method>_ci_low`, `<method>_ci_high` and
#'   `<method>_magnitude` triplet per requested method, `p_value`, one
#'   `p_<adjustment>` column per entry of `p_adjust`, and
#'   `ci_excludes_zero` for the first method. The attributes
#'   `conf_level`, `level`, `primary_method` and `skipped` (a tibble of
#'   the contrasts that fell below `min_n`) are attached.
#'
#' @examples
#' set.seed(1)
#' units <- data.frame(
#'   compound = rep(c("CompoundA", "CompoundB"), each = 12),
#'   arm = rep(rep(c("reference", "interval_short"), each = 6), 2),
#'   unit_id = paste0("u", 1:24),
#'   log2_fc = c(stats::rnorm(6, 0, 0.3), stats::rnorm(6, -1, 0.3),
#'               stats::rnorm(6, 0, 0.3), stats::rnorm(6, -0.1, 0.3))
#' )
#' eff <- cr_effect_grid(units, value = "log2_fc", group_var = "arm",
#'                       reference_level = "reference", by = "compound")
#' eff[, c("compound", "contrast", "cohens_d", "cohens_d_ci_low",
#'         "cohens_d_ci_high", "ci_excludes_zero")]
#'
#' @seealso [cr_effect_size()], [cr_compare_levels()],
#'   [cr_power_grid()], [cr_blocked_effect()].
#' @family effect sizes
#'
#' @export
cr_effect_grid <- function(data,
                           value,
                           group_var,
                           reference_level,
                           comparison_levels = NULL,
                           by = NULL,
                           unit = NULL,
                           methods = c("cohens_d", "hedges_g",
                                       "cliffs_delta"),
                           conf_level = 0.95,
                           min_n = 3,
                           test = c("t", "wilcox", "none"),
                           p_adjust = c("bonferroni", "BH"),
                           level = NULL) {
  data <- .cr_stat_data(data)
  test <- match.arg(test)
  methods <- match.arg(methods, choices = c("cohens_d", "hedges_g",
                                            "cliffs_delta",
                                            "rank_biserial",
                                            "glass_delta"),
                       several.ok = TRUE)
  .cr_check_prob(conf_level)
  .cr_require_cols(data, list(value, group_var, by, unit))
  if (!is.numeric(data[[value]])) {
    cli::cli_abort("Column {.field {value}} must be numeric.")
  }
  if (!is.null(p_adjust)) {
    p_adjust <- match.arg(p_adjust, choices = stats::p.adjust.methods,
                          several.ok = TRUE)
  }
  level <- level %||% if (is.null(unit)) "cell" else "unit"

  if (!is.null(unit)) {
    data <- .cr_aggregate_units(data, value = value, unit = unit,
                                keys = c(by, group_var))
  }

  .cr_check_reference(data[[group_var]], reference_level, group_var)
  levels_cmp <- .cr_comparison_levels(data[[group_var]], reference_level,
                                      comparison_levels)
  if (!length(levels_cmp)) {
    cli::cli_abort(
      c("No comparison levels found in {.field {group_var}}.",
        "i" = "Reference level {.val {reference_level}} is the only level present.")
    )
  }

  groups <- .cr_stat_groups(data, by)
  rows <- list()
  skipped <- list()
  for (g in groups) {
    gd <- data[g$idx, , drop = FALSE]
    gv <- as.character(gd[[group_var]])
    ref <- as.numeric(stats::na.omit(gd[[value]][gv == reference_level]))
    for (lv in levels_cmp) {
      cmp <- as.numeric(stats::na.omit(gd[[value]][gv == lv]))
      contrast <- paste0(reference_level, " -> ", lv)
      if (length(ref) < min_n || length(cmp) < min_n) {
        skipped[[length(skipped) + 1L]] <- .cr_bind_key(g$key, tibble::tibble(
          contrast = contrast, level = level,
          n_ref = length(ref), n_cmp = length(cmp),
          reason = "fewer observations than min_n"
        ))
        next
      }
      rows[[length(rows) + 1L]] <- .cr_bind_key(g$key, tibble::tibble(
        contrast = contrast,
        level = level,
        n_ref = length(ref),
        n_cmp = length(cmp),
        mean_shift = mean(cmp) - mean(ref),
        !!!.cr_es_columns(cmp, ref, methods, conf_level),
        p_value = .cr_grid_p(cmp, ref, test)
      ))
    }
  }

  out <- if (length(rows)) {
    dplyr::bind_rows(rows)
  } else {
    .cr_empty_grid(data, by, methods)
  }
  for (m in p_adjust) {
    out[[paste0("p_", m)]] <- stats::p.adjust(out$p_value, method = m)
  }
  lo <- out[[paste0(methods[1], "_ci_low")]]
  hi <- out[[paste0(methods[1], "_ci_high")]]
  out$ci_excludes_zero <- is.finite(lo) & is.finite(hi) & sign(lo) == sign(hi)
  attr(out, "conf_level") <- conf_level
  attr(out, "level") <- level
  attr(out, "primary_method") <- methods[1]
  attr(out, "skipped") <- dplyr::bind_rows(skipped)
  out
}

#' Compare unit-level and cell-level effect estimates
#'
#' Puts the two aggregation levels of a screen side by side and
#' quantifies how much narrower the cell-level intervals are. A ratio
#' well above one is pseudo-replication rather than precision: cells
#' within a unit are not independent, so the cell-level interval
#' understates the uncertainty of the very same estimate.
#'
#' @param unit_effects Effect grid computed with `unit` set, from
#'   [cr_effect_grid()].
#' @param cell_effects Effect grid computed on the same data without
#'   `unit`.
#' @param by Join keys. `NULL` (default) uses every non-numeric column
#'   the two grids share, which is the stratifying columns plus
#'   `contrast`.
#' @param estimate Name of the effect size column to compare.
#'
#' @return A tibble with the join keys, `estimate_unit`,
#'   `estimate_cell`, `width_unit`, `width_cell` and `ratio`
#'   (`width_unit / width_cell`). The median ratio is attached as the
#'   `median_ratio` attribute.
#'
#' @examples
#' set.seed(1)
#' cells <- data.frame(
#'   compound = rep(c("CompoundA", "CompoundB"), each = 240),
#'   arm = rep(rep(c("reference", "interval_short"), each = 120), 2),
#'   unit_id = rep(paste0("u", 1:8), each = 60),
#'   log2_fc = stats::rnorm(480)
#' )
#' cells$log2_fc <- cells$log2_fc +
#'   ifelse(cells$compound == "CompoundA" & cells$arm == "interval_short",
#'          -1, 0)
#' u <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
#'                     by = "compound", unit = "unit_id")
#' k <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
#'                     by = "compound", min_n = 10)
#' cmp <- cr_compare_levels(u, k)
#' cmp
#' attr(cmp, "median_ratio")
#'
#' @seealso [cr_effect_grid()].
#' @family effect sizes
#'
#' @export
cr_compare_levels <- function(unit_effects,
                              cell_effects,
                              by = NULL,
                              estimate = "cohens_d") {
  unit_effects <- .cr_stat_data(unit_effects, arg = "unit_effects")
  cell_effects <- .cr_stat_data(cell_effects, arg = "cell_effects")
  cols <- c(estimate, paste0(estimate, c("_ci_low", "_ci_high")))
  .cr_require_cols(unit_effects, cols, arg = "unit_effects")
  .cr_require_cols(cell_effects, cols, arg = "cell_effects")

  if (is.null(by)) {
    shared <- intersect(names(unit_effects), names(cell_effects))
    keep <- vapply(shared, function(nm) {
      is.character(unit_effects[[nm]]) || is.factor(unit_effects[[nm]])
    }, logical(1))
    by <- setdiff(shared[keep], c("level", grep("_magnitude$", shared,
                                                value = TRUE)))
  }
  if (!length(by)) {
    cli::cli_abort(
      c("No join keys shared by {.arg unit_effects} and {.arg cell_effects}.",
        "i" = "Pass {.arg by} explicitly.")
    )
  }

  u <- unit_effects[, c(by, cols), drop = FALSE]
  k <- cell_effects[, c(by, cols), drop = FALSE]
  out <- dplyr::inner_join(u, k, by = by, suffix = c("_unit", "_cell"))
  res <- out[, by, drop = FALSE]
  res$estimate_unit <- out[[paste0(estimate, "_unit")]]
  res$estimate_cell <- out[[paste0(estimate, "_cell")]]
  res$width_unit <- out[[paste0(estimate, "_ci_high_unit")]] -
    out[[paste0(estimate, "_ci_low_unit")]]
  res$width_cell <- out[[paste0(estimate, "_ci_high_cell")]] -
    out[[paste0(estimate, "_ci_low_cell")]]
  res$ratio <- res$width_unit / res$width_cell
  attr(res, "median_ratio") <- if (nrow(res)) {
    stats::median(res$ratio, na.rm = TRUE)
  } else {
    NA_real_
  }
  attr(res, "estimate") <- estimate
  res
}

# Internal: the typed zero-row shape of an effect grid, so that a screen
# in which no contrast reached min_n still returns the same columns.
.cr_empty_grid <- function(data, by, methods) {
  out <- tibble::tibble(
    contrast = character(),
    level = character(),
    n_ref = integer(),
    n_cmp = integer(),
    mean_shift = numeric()
  )
  for (m in methods) {
    out[[m]] <- numeric()
    out[[paste0(m, "_ci_low")]] <- numeric()
    out[[paste0(m, "_ci_high")]] <- numeric()
    out[[paste0(m, "_magnitude")]] <- character()
  }
  out$p_value <- numeric()
  key <- if (is.null(by)) NULL else data[0, by, drop = FALSE]
  .cr_bind_key(key, out)
}

# Internal: prepend the (possibly empty) grouping key to a result row.
.cr_bind_key <- function(key, row) {
  if (is.null(key) || !ncol(key)) return(row)
  dplyr::bind_cols(key, row)
}

# Internal: mean of `value` per unit, keeping the design keys.
.cr_aggregate_units <- function(data, value, unit, keys) {
  grp <- .cr_stat_groups(data, unique(c(keys, unit)))
  dplyr::bind_rows(lapply(grp, function(g) {
    k <- g$key
    k$n_cells <- length(g$idx)
    k[[value]] <- mean(data[[value]][g$idx], na.rm = TRUE)
    k
  }))
}

# Internal: named list of effect size columns for one contrast.
.cr_es_columns <- function(cmp, ref, methods, conf_level) {
  out <- list()
  for (m in methods) {
    est <- .cr_effsize(cmp, ref, m)
    ci <- .cr_effsize_ci(cmp, ref, m, conf_level = conf_level)
    out[[m]] <- est
    out[[paste0(m, "_ci_low")]] <- ci[1]
    out[[paste0(m, "_ci_high")]] <- ci[2]
    out[[paste0(m, "_magnitude")]] <- .cr_magnitude(est, m)
  }
  out
}

# Internal: accompanying p-value for one contrast.
.cr_grid_p <- function(cmp, ref, test) {
  if (identical(test, "none")) return(NA_real_)
  tt <- try(switch(
    test,
    t = stats::t.test(cmp, ref),
    wilcox = suppressWarnings(stats::wilcox.test(cmp, ref, exact = FALSE))
  ), silent = TRUE)
  if (inherits(tt, "try-error")) return(NA_real_)
  as.numeric(tt$p.value)
}

# Version 0.1.0
