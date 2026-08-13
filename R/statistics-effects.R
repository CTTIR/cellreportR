#' Compute effect sizes between two samples
#'
#' Standardized effect sizes for a comparison of two independent
#' samples, each with a confidence interval. Confidence intervals are
#' analytic by default (deterministic and cheap on large samples); a
#' bootstrap interval is available for cases where the analytic
#' approximation is not wanted.
#'
#' Cohen's *d* uses the pooled standard deviation without small-sample
#' correction and its interval is the large-sample (Hedges-Olkin)
#' approximation with a *t* quantile on `n_x + n_y - 2` degrees of
#' freedom. Hedges' *g* applies the bias correction
#' \eqn{J = 1 - 3 / (4 \cdot df - 1)} to both estimate and interval.
#' Glass's delta standardizes by the standard deviation of `y` only.
#' Cliff's delta uses the consistent variance estimator with the
#' interval on the transformed scale, so the bounds always lie inside
#' \eqn{[-1, 1]}. The rank-biserial correlation of two independent
#' samples equals Cliff's delta and is reported on the same scale.
#'
#' @param x Numeric vector (treatment group).
#' @param y Numeric vector (control / reference group).
#' @param method Character vector of methods to compute. Allowed:
#'   `"cohens_d"`, `"hedges_g"`, `"cliffs_delta"`,
#'   `"rank_biserial"`, `"glass_delta"`.
#' @param ci Confidence level for the interval (default 0.95). Set
#'   `NULL` to skip interval estimation.
#' @param ci_method `"analytic"` (default) or `"bootstrap"`.
#' @param n_boot Number of bootstrap resamples used when
#'   `ci_method = "bootstrap"`.
#' @param seed Optional integer seed for the bootstrap. The global
#'   random number stream is restored on exit.
#'
#' @return A tibble with columns `method`, `estimate`, `ci_low`,
#'   `ci_high` and `magnitude`.
#'
#' @examples
#' set.seed(1)
#' cr_effect_size(stats::rnorm(100, 1), stats::rnorm(100, 0))
#'
#' # bootstrap interval with a reproducible seed
#' cr_effect_size(stats::rnorm(50, 1), stats::rnorm(50, 0),
#'                method = "cliffs_delta",
#'                ci_method = "bootstrap", n_boot = 50, seed = 42)
#'
#' @seealso [cr_effect_grid()] for a whole grid of contrasts,
#'   [cr_power()] for the sample size implied by an effect size.
#' @family effect sizes
#'
#' @export
cr_effect_size <- function(x, y,
                           method = c("cohens_d", "hedges_g",
                                      "cliffs_delta", "rank_biserial",
                                      "glass_delta"),
                           ci = 0.95,
                           ci_method = c("analytic", "bootstrap"),
                           n_boot = 200,
                           seed = NULL) {
  method <- match.arg(method, several.ok = TRUE)
  ci_method <- match.arg(ci_method)
  if (!is.null(ci)) .cr_check_prob(ci)
  x <- as.numeric(stats::na.omit(x))
  y <- as.numeric(stats::na.omit(y))

  if (!is.null(seed) && identical(ci_method, "bootstrap") && !is.null(ci)) {
    old_seed <- .cr_capture_seed()
    on.exit(.cr_restore_seed(old_seed), add = TRUE)
    set.seed(seed)
  }

  out <- lapply(method, function(m) {
    est <- .cr_effsize(x, y, m)
    ci_vals <- c(NA_real_, NA_real_)
    if (!is.null(ci) && length(x) > 2L && length(y) > 2L) {
      ci_vals <- if (identical(ci_method, "analytic")) {
        .cr_effsize_ci(x, y, m, conf_level = ci)
      } else {
        boots <- replicate(n_boot, {
          .cr_effsize(sample(x, replace = TRUE),
                      sample(y, replace = TRUE), m)
        })
        probs <- c((1 - ci) / 2, 1 - (1 - ci) / 2)
        as.numeric(stats::quantile(boots, probs, na.rm = TRUE))
      }
    }
    tibble::tibble(method = m, estimate = est,
                   ci_low = ci_vals[1], ci_high = ci_vals[2],
                   magnitude = .cr_magnitude(est, m))
  })
  dplyr::bind_rows(out)
}

# ---- effect size engine ------------------------------------------------

# Internal: snapshot / restore the global random number stream so that a
# seeded sampling step never leaks into the caller's stream. Capture the
# state first, register the restore on exit, and only then set the seed.
.cr_capture_seed <- function() {
  if (exists(".Random.seed", envir = globalenv(), inherits = FALSE)) {
    get(".Random.seed", envir = globalenv(), inherits = FALSE)
  } else {
    NULL
  }
}

.cr_restore_seed <- function(old) {
  if (is.null(old)) {
    suppressWarnings(rm(".Random.seed", envir = globalenv()))
  } else {
    assign(".Random.seed", old, envir = globalenv())
  }
  invisible(NULL)
}

# Internal: pooled standard deviation of two samples.
.cr_pooled_sd <- function(x, y) {
  n1 <- length(x); n2 <- length(y)
  if (n1 < 2L || n2 < 2L) return(NA_real_)
  sqrt(((n1 - 1) * stats::var(x) + (n2 - 1) * stats::var(y)) / (n1 + n2 - 2))
}

# Internal: Cliff's delta and its consistent standard error, computed in
# O(n log n) via rank counting rather than an n1 x n2 outer product, so
# that cell-level samples of 1e4+ observations stay tractable.
.cr_cliff_stats <- function(x, y) {
  n1 <- length(x); n2 <- length(y)
  if (n1 < 1L || n2 < 1L) {
    return(list(delta = NA_real_, sigma = NA_real_))
  }
  sx <- sort(x); sy <- sort(y)
  # per-element counts of the other sample below / at or below
  y_lt <- findInterval(x, sy, left.open = TRUE)   # count of y < x_i
  y_le <- findInterval(x, sy)                     # count of y <= x_i
  y_gt <- n2 - y_le
  x_lt <- findInterval(y, sx, left.open = TRUE)   # count of x < y_j
  x_le <- findInterval(y, sx)
  x_gt <- n1 - x_le
  di <- (y_lt - y_gt) / n2                        # row means of sign(x-y)
  dj <- (x_gt - x_lt) / n1                        # column means
  delta <- sum(y_lt - y_gt) / (n1 * n2)
  sigma <- NA_real_
  if (n1 > 1L && n2 > 1L) {
    n_ties <- sum(y_le - y_lt)
    s_i <- sum((di - delta)^2)
    s_j <- sum((dj - delta)^2)
    s_ij <- (n1 * n2 - n_ties) - n1 * n2 * delta^2
    var_d <- (n2^2 * s_i + n1^2 * s_j - s_ij) /
      (n1 * n2 * (n1 - 1) * (n2 - 1))
    if (is.finite(var_d) && var_d > 0) sigma <- sqrt(var_d)
  }
  list(delta = delta, sigma = sigma)
}

# Internal: one effect size point estimate
.cr_effsize <- function(x, y, m) {
  switch(
    m,
    cohens_d = {
      s <- .cr_pooled_sd(x, y)
      if (is.na(s) || s == 0) return(NA_real_)
      (mean(x) - mean(y)) / s
    },
    hedges_g = {
      s <- .cr_pooled_sd(x, y)
      if (is.na(s) || s == 0) return(NA_real_)
      d <- (mean(x) - mean(y)) / s
      df <- length(x) + length(y) - 2
      d * (1 - 3 / (4 * df - 1))
    },
    cliffs_delta = .cr_cliff_stats(x, y)$delta,
    rank_biserial = .cr_cliff_stats(x, y)$delta,
    glass_delta = {
      s <- stats::sd(y)
      if (is.na(s) || s == 0) return(NA_real_)
      (mean(x) - mean(y)) / s
    },
    NA_real_
  )
}

# Internal: analytic confidence interval for one effect size
.cr_effsize_ci <- function(x, y, m, conf_level = 0.95) {
  n1 <- length(x); n2 <- length(y)
  na2 <- c(NA_real_, NA_real_)
  if (n1 < 2L || n2 < 2L) return(na2)
  alpha <- 1 - conf_level

  if (m %in% c("cliffs_delta", "rank_biserial")) {
    cs <- .cr_cliff_stats(x, y)
    d <- cs$delta; s <- cs$sigma
    if (!is.finite(d) || !is.finite(s)) return(na2)
    z <- stats::qnorm(1 - alpha / 2)
    denom <- 1 - d^2 + z^2 * s^2
    if (!is.finite(denom) || denom <= 0) return(na2)
    half <- z * s * sqrt((1 - d^2)^2 + z^2 * s^2)
    lo <- (d - d^3 - half) / denom
    hi <- (d - d^3 + half) / denom
    return(c(max(-1, min(1, lo)), max(-1, min(1, hi))))
  }

  df <- n1 + n2 - 2
  tq <- stats::qt(1 - alpha / 2, df = df)
  if (identical(m, "glass_delta")) {
    est <- .cr_effsize(x, y, m)
    if (!is.finite(est)) return(na2)
    se <- sqrt((n1 + n2) / (n1 * n2) + est^2 / (2 * (n2 - 1)))
    return(c(est - tq * se, est + tq * se))
  }

  d <- .cr_effsize(x, y, "cohens_d")
  if (!is.finite(d)) return(na2)
  se <- sqrt((n1 + n2) / (n1 * n2) + d^2 / (2 * df))
  if (identical(m, "hedges_g")) {
    jj <- 1 - 3 / (4 * df - 1)
    return(c(jj * d - tq * jj * se, jj * d + tq * jj * se))
  }
  c(d - tq * se, d + tq * se)
}

# Internal: verbal magnitude for an effect size estimate
.cr_magnitude <- function(est, m) {
  if (length(est) != 1L || is.na(est)) return(NA_character_)
  a <- abs(est)
  if (m %in% c("cohens_d", "hedges_g", "glass_delta")) {
    if (a < 0.2) return("negligible")
    if (a < 0.5) return("small")
    if (a < 0.8) return("medium")
    return("large")
  }
  if (m %in% c("cliffs_delta", "rank_biserial")) {
    if (a < 0.147) return("negligible")
    if (a < 0.33) return("small")
    if (a < 0.474) return("medium")
    return("large")
  }
  NA_character_
}

# Version 0.1.0
