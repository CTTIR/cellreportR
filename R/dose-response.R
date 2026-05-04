#' Fit a dose-response curve
#'
#' Fits a dose-response model to well-level summaries of a treatment
#' across doses. Supports 4-parameter log-logistic (`"4pl"`),
#' 3-parameter log-logistic with fixed lower asymptote at zero
#' (`"3pl"`), and a simple linear model (`"linear"`).
#'
#' The 4PL model fitted is:
#' \deqn{y = d + \frac{a - d}{1 + (x / e)^b}}
#' where `a` is the top asymptote, `d` the bottom asymptote, `e` the
#' inflection point (EC50 / IC50), and `b` the Hill slope.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param treatment Character. Names of treatments to include (for
#'   example a compound at several doses). If `NULL`, the entire
#'   design is used after filtering by `dose > 0`.
#' @param model `"4pl"`, `"3pl"` or `"linear"`.
#' @param log_dose If `TRUE`, the fit is done on log10 doses. Doses
#'   must all be positive in that case.
#' @return A list with class `"cr_dose_response"` containing the
#'   fitted model, the data used for the fit, the estimated
#'   parameters, and helper predictions.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' # Add a synthetic dose-response sub-design
#' exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
#'                           500, exp$design$dose)
#' fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
#' print(fit$params)
cr_dose_response <- function(experiment,
                             channel,
                             treatment = NULL,
                             model = c("4pl", "3pl", "linear"),
                             log_dose = TRUE) {
  cr_validate_experiment(experiment)
  model <- match.arg(model)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  if (!"dose" %in% names(experiment$design)) {
    cli::cli_abort("Design table must have a {.field dose} column for dose-response.")
  }

  wells <- cr_summarize_wells(experiment, channel, stats::median)
  wells <- wells[!is.na(wells$dose) & wells$dose >= 0, , drop = FALSE]
  if (!is.null(treatment)) {
    wells <- wells[wells$treatment %in% treatment, , drop = FALSE]
  }
  if (log_dose) wells <- wells[wells$dose > 0, , drop = FALSE]
  if (!nrow(wells)) cli::cli_abort("No data rows to fit dose-response.")

  x <- if (log_dose) log10(wells$dose) else wells$dose
  y <- wells$value

  fit <- NULL
  params <- NULL
  if (model == "linear") {
    fit <- stats::lm(y ~ x)
    co <- stats::coef(fit)
    params <- tibble::tibble(
      parameter = c("intercept", "slope"),
      estimate = c(co[1], co[2])
    )
  } else {
    # Starting values
    a_start <- max(y, na.rm = TRUE)
    d_start <- min(y, na.rm = TRUE)
    e_start <- stats::median(x, na.rm = TRUE)
    b_start <- 1
    fit <- tryCatch({
      if (model == "4pl") {
        suppressWarnings(stats::nls(
          y ~ d + (a - d) / (1 + exp(b * (x - e))),
          start = list(a = a_start, d = d_start, e = e_start, b = b_start),
          control = stats::nls.control(maxiter = 200, warnOnly = TRUE)
        ))
      } else {
        suppressWarnings(stats::nls(
          y ~ a / (1 + exp(b * (x - e))),
          start = list(a = a_start, e = e_start, b = b_start),
          control = stats::nls.control(maxiter = 200, warnOnly = TRUE)
        ))
      }
    }, error = function(e) NULL)

    if (is.null(fit)) {
      fit <- stats::lm(y ~ x)
      model <- "linear"
      co <- stats::coef(fit)
      params <- tibble::tibble(
        parameter = c("intercept", "slope"),
        estimate = c(co[1], co[2]),
        std_error = NA_real_
      )
    } else {
      co_vec <- stats::coef(fit)
      se_vec <- tryCatch({
        sm <- suppressWarnings(summary(fit))$coefficients
        sm[, 2]
      }, error = function(e) rep(NA_real_, length(co_vec)))
      params <- tibble::tibble(
        parameter = names(co_vec),
        estimate = as.numeric(co_vec),
        std_error = as.numeric(se_vec)
      )
    }
  }

  # Fitted curve
  xs <- seq(min(x), max(x), length.out = 200)
  ys <- tryCatch(stats::predict(fit, newdata = data.frame(x = xs)),
                 error = function(e) rep(NA_real_, length(xs)))
  curve <- tibble::tibble(x = xs, y = ys)

  # Dose for display
  if (log_dose) {
    wells$log_dose <- log10(wells$dose)
    curve$dose <- 10 ^ curve$x
  } else {
    curve$dose <- curve$x
  }

  out <- list(
    fit = fit,
    model = model,
    data = wells,
    params = params,
    curve = curve,
    log_dose = log_dose,
    channel = channel
  )
  class(out) <- c("cr_dose_response", "list")
  out
}

#' Extract IC50 / EC50 from a dose-response fit
#'
#' @param fit A `cr_dose_response` returned by [cr_dose_response()].
#' @param level Confidence level for the interval (default 0.95).
#' @return A tibble with `estimate`, `ci_low`, `ci_high`,
#'   `parameter` (IC50 or EC50) and `units`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
#'                           500, exp$design$dose)
#' fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
#' cr_ic50(fit)
cr_ic50 <- function(fit, level = 0.95) {
  if (!inherits(fit, "cr_dose_response")) {
    cli::cli_abort("`fit` must be a {.cls cr_dose_response}.")
  }
  if (fit$model == "linear") {
    return(tibble::tibble(parameter = "IC50",
                          estimate = NA_real_,
                          ci_low = NA_real_,
                          ci_high = NA_real_,
                          units = NA_character_))
  }
  e_row <- fit$params[fit$params$parameter == "e", ]
  if (!nrow(e_row)) {
    return(tibble::tibble(parameter = "IC50",
                          estimate = NA_real_,
                          ci_low = NA_real_,
                          ci_high = NA_real_,
                          units = NA_character_))
  }
  est <- e_row$estimate
  se <- if ("std_error" %in% names(e_row)) e_row$std_error else NA_real_
  zcrit <- stats::qnorm(1 - (1 - level) / 2)
  ci_low <- est - zcrit * se
  ci_high <- est + zcrit * se
  if (fit$log_dose) {
    est <- 10 ^ est
    ci_low <- 10 ^ ci_low
    ci_high <- 10 ^ ci_high
  }
  units_str <- unique(fit$data$dose_unit)[1]
  tibble::tibble(
    parameter = "IC50",
    estimate = est,
    ci_low = ci_low,
    ci_high = ci_high,
    units = units_str
  )
}
