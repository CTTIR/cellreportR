#' Effect size at the confidence bound nearer the null
#'
#' Returns the end of a confidence interval that lies closer to zero,
#' which is the conservative effect a follow-up study should be powered
#' on. When the interval spans the null there is nothing to power on
#' and `NA` is returned.
#'
#' @param ci_low Numeric vector of lower interval bounds.
#' @param ci_high Numeric vector of upper interval bounds.
#'
#' @return A numeric vector the length of the recycled inputs.
#'
#' @examples
#' cr_conservative_effect(c(-1.8, -0.4), c(-0.6, 0.9))
#'
#' @seealso [cr_power()], [cr_effect_grid()].
#' @family power
#'
#' @export
cr_conservative_effect <- function(ci_low, ci_high) {
  n <- max(length(ci_low), length(ci_high))
  lo <- rep_len(as.numeric(ci_low), n)
  hi <- rep_len(as.numeric(ci_high), n)
  out <- rep(NA_real_, n)
  ok <- is.finite(lo) & is.finite(hi)
  spans <- ok & lo <= 0 & hi >= 0
  use <- ok & !spans
  out[use] <- ifelse(abs(lo[use]) < abs(hi[use]), lo[use], hi[use])
  out
}

#' Sample size for a future study, sized twice
#'
#' Solves the two-sample design for the number of units per arm needed
#' to reach `power` at `sig_level`, once for the observed effect and
#' once for the confidence bound nearer the null.
#'
#' The conservative figure is the reportable one. Powering a screen's
#' leading compound on its own point estimate is circular: that
#' compound is the largest of the set only by virtue of having been
#' selected for being largest, so a sample size derived from it can
#' hardly fail to be met. `n_conservative` is `NA` whenever the
#' interval spans the null, because an interval compatible with no
#' effect cannot be sized.
#'
#' The solver is [stats::power.t.test()], so the effect size is read as
#' a standardized mean difference and `n` is per group.
#'
#' @param effect_size Numeric vector of observed standardized effects
#'   (Cohen's *d*). May be `NULL` when only interval bounds are given.
#' @param ci_low,ci_high Numeric vectors of interval bounds for the
#'   same effects. Optional.
#' @param power Target power (default 0.8).
#' @param sig_level Significance level (default 0.05).
#' @param type Design: `"two.sample"` (default), `"one.sample"` or
#'   `"paired"`.
#' @param alternative `"two.sided"` (default) or `"one.sided"`.
#'
#' @return A tibble with one row per effect: `d_observed`,
#'   `n_observed`, `d_conservative`, `n_conservative`, `basis`,
#'   `power` and `sig_level`. Sample sizes are units per arm, rounded
#'   up.
#'
#' @examples
#' cr_power(effect_size = c(-1.31, -0.28),
#'          ci_low = c(-2.35, -1.20),
#'          ci_high = c(-0.27, 0.64))
#'
#' # without an interval only the (circular) observed sizing is possible
#' cr_power(effect_size = 0.8)
#'
#' @seealso [cr_power_grid()], [cr_conservative_effect()],
#'   [cr_power_analysis()].
#' @family power
#'
#' @export
cr_power <- function(effect_size = NULL,
                     ci_low = NULL,
                     ci_high = NULL,
                     power = 0.8,
                     sig_level = 0.05,
                     type = c("two.sample", "one.sample", "paired"),
                     alternative = c("two.sided", "one.sided")) {
  type <- match.arg(type)
  alternative <- match.arg(alternative)
  .cr_check_prob(power)
  .cr_check_prob(sig_level)
  if (is.null(effect_size) && (is.null(ci_low) || is.null(ci_high))) {
    cli::cli_abort(
      c("Supply {.arg effect_size}, or both {.arg ci_low} and {.arg ci_high}.",
        "i" = "The conservative sizing needs an interval.")
    )
  }
  n <- max(length(effect_size), length(ci_low), length(ci_high))
  d_obs <- if (is.null(effect_size)) {
    rep(NA_real_, n)
  } else {
    rep_len(as.numeric(effect_size), n)
  }
  has_ci <- !is.null(ci_low) && !is.null(ci_high)
  d_cons <- if (has_ci) {
    cr_conservative_effect(rep_len(as.numeric(ci_low), n),
                           rep_len(as.numeric(ci_high), n))
  } else {
    rep(NA_real_, n)
  }

  size <- function(d) {
    vapply(d, .cr_size_for, numeric(1), power = power,
           sig_level = sig_level, type = type, alternative = alternative)
  }
  n_obs <- size(d_obs)
  n_cons <- size(d_cons)

  basis <- rep("no usable estimate", n)
  basis[is.finite(n_obs)] <- "observed estimate (circular for a selected hit)"
  basis[is.finite(n_cons)] <- "confidence bound nearer the null"
  if (has_ci) {
    spans <- !is.finite(d_cons) & is.finite(d_obs)
    basis[spans] <- "interval spans the null; not sizable"
  }

  tibble::tibble(
    d_observed = d_obs,
    n_observed = n_obs,
    d_conservative = d_cons,
    n_conservative = n_cons,
    basis = basis,
    power = power,
    sig_level = sig_level
  )
}

#' Sample sizes for a whole effect grid
#'
#' Applies [cr_power()] to every row of an effect grid produced by
#' [cr_effect_grid()] and binds the sizing columns onto it, so the
#' observed and the conservative sample size travel with the contrast
#' they belong to.
#'
#' @param effects An effect grid from [cr_effect_grid()], or any data
#'   frame with an estimate column and its two interval columns.
#' @param estimate Name of the effect size column. The interval columns
#'   default to `<estimate>_ci_low` and `<estimate>_ci_high`.
#' @param ci_low,ci_high Optional explicit names of the interval
#'   columns.
#' @param available Units already available per arm, used to flag which
#'   contrasts are already large enough. Either a column name in
#'   `effects` or a numeric vector. Defaults to `pmin(n_ref, n_cmp)`
#'   when those columns are present.
#' @param power Target power (default 0.8).
#' @param sig_level Significance level (default 0.05).
#' @param type Design passed to [cr_power()].
#' @param alternative Alternative passed to [cr_power()].
#'
#' @return `effects` with the columns `d_conservative`, `n_observed`,
#'   `n_conservative` and `basis` appended, plus `n_available` and
#'   `sufficient` when availability is known.
#'
#' @examples
#' set.seed(1)
#' units <- data.frame(
#'   compound = rep(c("CompoundA", "CompoundB"), each = 12),
#'   arm = rep(rep(c("reference", "interval_short"), each = 6), 2),
#'   log2_fc = c(stats::rnorm(6, 0, 0.3), stats::rnorm(6, -1.4, 0.3),
#'               stats::rnorm(6, 0, 0.3), stats::rnorm(6, -0.1, 0.3))
#' )
#' eff <- cr_effect_grid(units, "log2_fc", "arm", "reference",
#'                       by = "compound")
#' sizes <- cr_power_grid(eff)
#' sizes[, c("compound", "n_observed", "n_conservative", "basis")]
#'
#' @seealso [cr_power()], [cr_effect_grid()].
#' @family power
#'
#' @export
cr_power_grid <- function(effects,
                          estimate = "cohens_d",
                          ci_low = NULL,
                          ci_high = NULL,
                          available = NULL,
                          power = 0.8,
                          sig_level = 0.05,
                          type = c("two.sample", "one.sample", "paired"),
                          alternative = c("two.sided", "one.sided")) {
  effects <- .cr_stat_data(effects, arg = "effects")
  ci_low <- ci_low %||% paste0(estimate, "_ci_low")
  ci_high <- ci_high %||% paste0(estimate, "_ci_high")
  .cr_require_cols(effects, c(estimate, ci_low, ci_high), arg = "effects")

  sizes <- cr_power(effect_size = effects[[estimate]],
                    ci_low = effects[[ci_low]],
                    ci_high = effects[[ci_high]],
                    power = power, sig_level = sig_level,
                    type = type, alternative = alternative)

  out <- effects
  out$d_conservative <- sizes$d_conservative
  out$n_observed <- sizes$n_observed
  out$n_conservative <- sizes$n_conservative
  out$basis <- sizes$basis

  avail <- NULL
  if (is.character(available)) {
    .cr_require_cols(effects, available, arg = "effects")
    avail <- as.numeric(effects[[available]])
  } else if (is.numeric(available)) {
    avail <- rep_len(as.numeric(available), nrow(effects))
  } else if (all(c("n_ref", "n_cmp") %in% names(effects))) {
    avail <- pmin(effects$n_ref, effects$n_cmp)
  }
  if (!is.null(avail)) {
    out$n_available <- avail
    target <- ifelse(is.finite(out$n_conservative),
                     out$n_conservative, out$n_observed)
    out$sufficient <- is.finite(target) & avail >= target
  }
  attr(out, "power") <- power
  attr(out, "sig_level") <- sig_level
  out
}

#' Post-hoc power for a hierarchical cell-based assay
#'
#' A Monte-Carlo approximation of the power of a two-sample comparison
#' that accounts for the hierarchical structure (cells nested within
#' replicate units). Used mainly for reporting; for sizing a follow-up
#' study use [cr_power()], which inverts the design analytically.
#'
#' @param effect_size Cohen's *d* at the cell level.
#' @param n_replicates Number of replicate units per group.
#' @param n_cells_per_rep Cells per replicate unit.
#' @param alpha Type I error rate.
#' @param test Only `"t_test"` is implemented.
#' @param n_sim Number of simulations (default 500).
#' @param seed Optional integer seed. The caller's random number
#'   stream is restored on exit.
#'
#' @return A tibble with the inputs and the simulated `power`.
#'
#' @examples
#' cr_power_analysis(effect_size = 0.8, n_replicates = 4,
#'                   n_cells_per_rep = 100, n_sim = 100, seed = 1)
#'
#' @seealso [cr_power()].
#' @family power
#'
#' @export
cr_power_analysis <- function(effect_size,
                              n_replicates,
                              n_cells_per_rep,
                              alpha = 0.05,
                              test = "t_test",
                              n_sim = 500,
                              seed = NULL) {
  if (test != "t_test") {
    cli::cli_abort("Only t_test is implemented at present.")
  }
  if (!is.null(seed)) {
    old_seed <- .cr_capture_seed()
    on.exit(.cr_restore_seed(old_seed), add = TRUE)
    set.seed(seed)
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

# Internal: units per arm needed for one standardized effect. NA when
# the effect is not usable (missing, or indistinguishable from zero).
.cr_size_for <- function(d, power, sig_level, type, alternative) {
  if (!is.finite(d) || abs(d) < 1e-6) return(NA_real_)
  res <- try(stats::power.t.test(delta = abs(d), sd = 1,
                                 sig.level = sig_level, power = power,
                                 type = type, alternative = alternative),
             silent = TRUE)
  if (inherits(res, "try-error") || !is.finite(res$n)) return(NA_real_)
  ceiling(res$n)
}

# Version 0.1.0
