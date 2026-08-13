#' Block-stratified sensitivity fit
#'
#' Re-estimates each contrast *within* a blocking factor, typically the
#' plate. Units on one plate share a preparation run, an imaging
#' session and a single control denominator, so they are not
#' independent and a pooled estimate carries the between-plate variance
#' inside its standard deviation. Fitting `value ~ group + block` on
#' unit-level data removes the additive block effect and shows whether
#' the pooled headline estimate is conservative or inflated by pooling.
#'
#' The reported `d_within_block` is the group coefficient divided by
#' the residual standard deviation of the blocked fit, so it is on the
#' same scale as Cohen's *d* from [cr_effect_grid()] but conditions on
#' the block.
#'
#' @param data A data frame with one row per unit (or per cell when
#'   `unit` is given), or a `cr_experiment`.
#' @param value Name of the numeric response column.
#' @param group_var Name of the column holding the compared groups.
#' @param reference_level Reference level of `group_var`.
#' @param comparison_levels Levels contrasted against the reference.
#'   `NULL` (default) uses every other level present.
#' @param block_var Name of the blocking column, for example the plate.
#' @param by Optional character vector of stratifying columns, for
#'   example the compound.
#' @param unit Optional column identifying the unit of replication.
#'   When given, rows are averaged per unit before the model is fitted.
#' @param conf_level Confidence level for the coefficient interval.
#' @param min_blocks Minimum number of blocks that must carry data for
#'   a contrast to be fitted (default 2; with one block the model is
#'   the unblocked one).
#'
#' @return A tibble with the `by` columns, `contrast`, `n_units`,
#'   `n_blocks`, `shift_within_block` (the group coefficient),
#'   `ci_low`, `ci_high`, `resid_sd`, `d_within_block` and `p_value`.
#'   Contrasts that could not be fitted are returned in the `skipped`
#'   attribute.
#'
#' @examples
#' set.seed(1)
#' units <- data.frame(
#'   compound = rep(c("CompoundA", "CompoundB"), each = 16),
#'   arm = rep(rep(c("reference", "interval_short"), each = 8), 2),
#'   plate = rep(rep(c("P1", "P2"), each = 4), 8),
#'   log2_fc = stats::rnorm(32)
#' )
#' units$log2_fc <- units$log2_fc +
#'   ifelse(units$compound == "CompoundA" & units$arm == "interval_short",
#'          -1.2, 0) +
#'   ifelse(units$plate == "P2", 0.5, 0)
#' cr_blocked_effect(units, value = "log2_fc", group_var = "arm",
#'                   reference_level = "reference",
#'                   block_var = "plate", by = "compound")
#'
#' @seealso [cr_effect_grid()], [cr_unit_variability()].
#' @family screen statistics
#'
#' @export
cr_blocked_effect <- function(data,
                              value,
                              group_var,
                              reference_level,
                              comparison_levels = NULL,
                              block_var,
                              by = NULL,
                              unit = NULL,
                              conf_level = 0.95,
                              min_blocks = 2) {
  data <- .cr_stat_data(data)
  .cr_check_prob(conf_level)
  .cr_require_cols(data, list(value, group_var, block_var, by, unit))
  if (!is.numeric(data[[value]])) {
    cli::cli_abort("Column {.field {value}} must be numeric.")
  }
  if (!is.null(unit)) {
    data <- .cr_aggregate_units(data, value = value, unit = unit,
                                keys = c(by, group_var, block_var))
  }
  .cr_check_reference(data[[group_var]], reference_level, group_var)
  levels_cmp <- .cr_comparison_levels(data[[group_var]], reference_level,
                                      comparison_levels)

  rows <- list()
  skipped <- list()
  for (g in .cr_stat_groups(data, by)) {
    gd <- data[g$idx, , drop = FALSE]
    gv <- as.character(gd[[group_var]])
    for (lv in levels_cmp) {
      contrast <- paste0(reference_level, " -> ", lv)
      keep <- gv %in% c(reference_level, lv)
      sub <- tibble::tibble(
        y = as.numeric(gd[[value]][keep]),
        grp = factor(gv[keep], levels = c(reference_level, lv)),
        block = factor(as.character(gd[[block_var]][keep]))
      )
      sub <- sub[stats::complete.cases(sub), , drop = FALSE]
      fit <- .cr_fit_blocked(sub, conf_level = conf_level,
                             min_blocks = min_blocks)
      if (is.null(fit)) {
        skipped[[length(skipped) + 1L]] <- .cr_bind_key(g$key, tibble::tibble(
          contrast = contrast,
          n_units = nrow(sub),
          n_blocks = length(unique(sub$block)),
          reason = "both arms and at least min_blocks blocks are required"
        ))
        next
      }
      rows[[length(rows) + 1L]] <- .cr_bind_key(g$key, tibble::tibble(
        contrast = contrast, !!!fit
      ))
    }
  }
  out <- if (length(rows)) {
    dplyr::bind_rows(rows)
  } else {
    .cr_bind_key(if (is.null(by)) NULL else data[0, by, drop = FALSE],
                 tibble::tibble(
                   contrast = character(), n_units = integer(),
                   n_blocks = integer(), shift_within_block = numeric(),
                   ci_low = numeric(), ci_high = numeric(),
                   resid_sd = numeric(), d_within_block = numeric(),
                   p_value = numeric()
                 ))
  }
  attr(out, "conf_level") <- conf_level
  attr(out, "skipped") <- dplyr::bind_rows(skipped)
  out
}

#' Between-unit variability within a condition
#'
#' Summarizes how far apart the units of one condition sit. For every
#' group defined by `by` that holds at least `min_units` units, the
#' number of units, the coefficient of variation, the spread
#' (`max - min` of the unit values) and the fold range
#' (`log_base ^ spread`) are reported.
#'
#' This is unit-to-unit variability. It is **not** within-unit
#' technical repeatability: that would require the same unit to be
#' measured twice, which a design with one acquisition per unit cannot
#' deliver. A unit assembled from two partial acquisitions is two
#' halves of one unit, not two reads of it.
#'
#' The coefficient of variation is computed as
#' `100 * sd / abs(mean)`, which is unstable when the mean of a
#' log-scale response approaches zero; the fold range is the robust
#' summary and is what the attached overall summary reports.
#'
#' @param data A data frame with one row per unit (or per cell when
#'   `unit` is given), or a `cr_experiment`.
#' @param value Name of the numeric response column, typically a
#'   log-scale fold change.
#' @param by Character vector of columns defining a condition, for
#'   example compound, experiment, plate and pre-treatment interval.
#' @param unit Optional column identifying the unit of replication.
#'   When given, rows are averaged per unit first.
#' @param min_units Minimum number of units a group must contain to be
#'   reported (default 2).
#' @param log_base Base of the logarithm the response is on. Used to
#'   turn the spread into a fold range. Default 2.
#'
#' @return A tibble with the `by` columns, `n_units`, `mean_value`,
#'   `sd_value`, `cv_pct`, `spread` and `fold_range`, carrying a
#'   `summary` attribute (a one-row tibble with the number of groups
#'   and the median, quartiles and maximum of the fold range).
#'
#' @examples
#' set.seed(1)
#' units <- data.frame(
#'   compound = rep(c("CompoundA", "CompoundB"), each = 12),
#'   plate = rep(rep(c("P1", "P2"), each = 6), 2),
#'   log2_fc = stats::rnorm(24, 0, 0.4)
#' )
#' v <- cr_unit_variability(units, value = "log2_fc",
#'                          by = c("compound", "plate"))
#' v
#' attr(v, "summary")
#'
#' @seealso [cr_blocked_effect()], [cr_effect_grid()].
#' @family screen statistics
#'
#' @export
cr_unit_variability <- function(data,
                                value,
                                by,
                                unit = NULL,
                                min_units = 2,
                                log_base = 2) {
  data <- .cr_stat_data(data)
  .cr_require_cols(data, list(value, by, unit))
  if (!is.numeric(data[[value]])) {
    cli::cli_abort("Column {.field {value}} must be numeric.")
  }
  if (!is.numeric(log_base) || length(log_base) != 1L || log_base <= 1) {
    cli::cli_abort("{.arg log_base} must be a single number greater than 1.")
  }
  if (!is.null(unit)) {
    data <- .cr_aggregate_units(data, value = value, unit = unit, keys = by)
  }

  rows <- lapply(.cr_stat_groups(data, by), function(g) {
    v <- as.numeric(stats::na.omit(data[[value]][g$idx]))
    if (length(v) < min_units) return(NULL)
    spread <- max(v) - min(v)
    .cr_bind_key(g$key, tibble::tibble(
      n_units = length(v),
      mean_value = mean(v),
      sd_value = stats::sd(v),
      cv_pct = 100 * stats::sd(v) / abs(mean(v)),
      spread = spread,
      fold_range = log_base^spread
    ))
  })
  out <- dplyr::bind_rows(rows)
  if (!nrow(out)) {
    out <- .cr_bind_key(data[0, by, drop = FALSE], tibble::tibble(
      n_units = integer(), mean_value = numeric(), sd_value = numeric(),
      cv_pct = numeric(), spread = numeric(), fold_range = numeric()
    ))
  }
  attr(out, "summary") <- if (nrow(out)) {
    q <- stats::quantile(out$fold_range, c(0.25, 0.75), na.rm = TRUE)
    tibble::tibble(
      n_groups = nrow(out),
      median_fold_range = stats::median(out$fold_range, na.rm = TRUE),
      q25_fold_range = unname(q[1]),
      q75_fold_range = unname(q[2]),
      max_fold_range = max(out$fold_range, na.rm = TRUE)
    )
  } else {
    tibble::tibble(
      n_groups = 0L, median_fold_range = NA_real_,
      q25_fold_range = NA_real_, q75_fold_range = NA_real_,
      max_fold_range = NA_real_
    )
  }
  out
}

# Internal: fit value ~ group + block for one contrast. Returns NULL
# when the design cannot support the model (one arm missing, too few
# blocks, or the group effect fully confounded with the block).
.cr_fit_blocked <- function(sub, conf_level, min_blocks) {
  if (nrow(sub) < 3L) return(NULL)
  if (length(unique(sub$grp)) < 2L) return(NULL)
  n_blocks <- length(unique(as.character(sub$block)))
  if (n_blocks < min_blocks) return(NULL)
  form <- if (n_blocks > 1L) y ~ grp + block else y ~ grp
  fit <- try(stats::lm(form, data = sub), silent = TRUE)
  if (inherits(fit, "try-error")) return(NULL)
  cf <- stats::coef(fit)
  nm <- grep("^grp", names(cf), value = TRUE)[1]
  if (is.na(nm) || !is.finite(cf[[nm]])) return(NULL)
  smry <- suppressWarnings(summary(fit))
  ci <- try(stats::confint(fit, parm = nm, level = conf_level),
            silent = TRUE)
  if (inherits(ci, "try-error")) ci <- matrix(NA_real_, 1, 2)
  sigma <- smry$sigma
  list(
    n_units = nrow(sub),
    n_blocks = n_blocks,
    shift_within_block = unname(cf[[nm]]),
    ci_low = unname(ci[1, 1]),
    ci_high = unname(ci[1, 2]),
    resid_sd = unname(sigma),
    d_within_block = if (is.finite(sigma) && sigma > 0) {
      unname(cf[[nm]] / sigma)
    } else {
      NA_real_
    },
    p_value = if (nm %in% rownames(smry$coefficients)) {
      unname(smry$coefficients[nm, 4])
    } else {
      NA_real_
    }
  )
}

# Version 0.1.0
