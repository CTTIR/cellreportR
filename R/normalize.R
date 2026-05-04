#' Normalize intensity data
#'
#' Applies a channel-wise normalization. The normalized channel
#' values replace the original column in `cells`.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel column to normalize.
#' @param method One of `"background"`, `"control"`, `"zscore"`,
#'   `"robust_zscore"`, `"quantile"`.
#' @param control_group For `method = "control"`: the treatment name
#'   (in `design$treatment`) whose median / mean is used as reference.
#' @param ... Additional arguments passed to the underlying method.
#'
#' @details
#' - `"background"` subtracts per-well background via
#'   [cr_background_subtract()] (percentile method, 5th percentile).
#' - `"control"` divides each cell's intensity by the median intensity
#'   of cells assigned to `control_group`, then takes the log2 ratio.
#' - `"zscore"` applies a global Z-score across all cells.
#' - `"robust_zscore"` uses the median and MAD.
#' - `"quantile"` maps the per-well empirical distributions onto the
#'   global quantile distribution.
#' @return A modified `cr_experiment`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_normalize(exp, channel = "marker_1", method = "robust_zscore")
cr_normalize <- function(experiment,
                         channel,
                         method = c("background", "control", "zscore",
                                    "robust_zscore", "quantile"),
                         control_group = NULL,
                         ...) {
  cr_validate_experiment(experiment)
  method <- match.arg(method)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }

  v <- experiment$cells[[channel]]
  out <- switch(
    method,
    background = return(cr_background_subtract(experiment, channel,
                                               method = "percentile")),
    control = .cr_norm_control(experiment, channel, control_group),
    zscore = (v - mean(v, na.rm = TRUE)) / stats::sd(v, na.rm = TRUE),
    robust_zscore = (v - stats::median(v, na.rm = TRUE)) /
      stats::mad(v, na.rm = TRUE, constant = 1),
    quantile = .cr_norm_quantile(experiment, channel)
  )

  experiment$cells[[channel]] <- out
  experiment$metadata$normalization <- list(
    channel = channel, method = method, control_group = control_group,
    timestamp = Sys.time()
  )
  experiment
}

.cr_norm_control <- function(experiment, channel, control_group) {
  if (is.null(control_group)) {
    cli::cli_abort("`control_group` is required for control normalization.")
  }
  design <- experiment$design
  spatial <- experiment$spatial_unit
  control_wells <- design[[spatial]][design$treatment == control_group]
  if (!length(control_wells)) {
    cli::cli_abort("No wells match control group {.val {control_group}}.")
  }
  mask <- experiment$cells[[spatial]] %in% control_wells
  ref <- stats::median(experiment$cells[[channel]][mask], na.rm = TRUE)
  if (ref <= 0 || is.na(ref)) {
    cli::cli_abort("Control reference is non-positive or NA.")
  }
  log2(experiment$cells[[channel]] / ref)
}

.cr_norm_quantile <- function(experiment, channel) {
  spatial <- experiment$spatial_unit
  wells <- split(experiment$cells[[channel]], experiment$cells[[spatial]])
  max_n <- max(lengths(wells))
  ranks <- lapply(wells, function(x) {
    rank(x, ties.method = "average", na.last = "keep") / max(length(x), 1)
  })
  global <- sort(unlist(wells, use.names = FALSE), na.last = NA)
  if (!length(global)) return(experiment$cells[[channel]])
  out_v <- experiment$cells[[channel]]
  for (w in names(wells)) {
    idx <- which(experiment$cells[[spatial]] == w)
    qs <- ranks[[w]]
    qs[is.na(qs)] <- NA_real_
    pos <- pmin(pmax(round(qs * length(global)), 1L), length(global))
    pos[is.na(pos)] <- NA_integer_
    out_v[idx] <- ifelse(is.na(pos), NA_real_, global[pos])
  }
  out_v
}

#' Subtract background from a channel
#'
#' Computes a per-well background estimate and subtracts it from
#' every cell in that well. Negative values are clipped to zero.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param method Background estimator. `"percentile"` (default)
#'   uses a low percentile (default 5th), `"modal"` uses the mode of
#'   a kernel density estimate, and `"empty_wells"` uses the median
#'   intensity of wells listed in `empty_wells`.
#' @param q Percentile for `"percentile"` method (0-1, default 0.05).
#' @param empty_wells Character vector of well IDs for
#'   `"empty_wells"`.
#' @return A modified `cr_experiment`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_background_subtract(exp, channel = "marker_1")
cr_background_subtract <- function(experiment,
                                   channel,
                                   method = c("percentile", "modal",
                                              "empty_wells"),
                                   q = 0.05,
                                   empty_wells = NULL) {
  cr_validate_experiment(experiment)
  method <- match.arg(method)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  spatial <- experiment$spatial_unit
  cells <- experiment$cells
  if (method == "empty_wells") {
    if (!length(empty_wells)) {
      cli::cli_abort("`empty_wells` must be non-empty for this method.")
    }
    bg <- stats::median(cells[[channel]][cells[[spatial]] %in% empty_wells],
                        na.rm = TRUE)
    cells[[channel]] <- pmax(cells[[channel]] - bg, 0)
  } else {
    by_well <- split(cells[[channel]], cells[[spatial]])
    bg <- vapply(by_well, function(x) {
      if (!length(x) || all(is.na(x))) return(NA_real_)
      switch(
        method,
        percentile = stats::quantile(x, q, na.rm = TRUE),
        modal = .cr_mode(x)
      )
    }, numeric(1))
    idx <- match(cells[[spatial]], names(by_well))
    cells[[channel]] <- pmax(cells[[channel]] - bg[idx], 0)
  }
  experiment$cells <- cells
  experiment
}

.cr_mode <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  d <- stats::density(x, n = 512)
  d$x[which.max(d$y)]
}

#' Correct batch effects
#'
#' Applies a simple batch correction. `"median_center"` shifts each
#' batch's median to the overall median. `"combat"` delegates to
#' `sva::ComBat` when available.
#'
#' @param experiment A `cr_experiment`.
#' @param batch_var Name of the batch variable. Must exist in
#'   `design`.
#' @param channel Channel to correct.
#' @param method `"median_center"` or `"combat"`.
#' @return A modified `cr_experiment`.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' exp$design$batch <- rep(c("b1", "b2"), length.out = nrow(exp$design))
#' cr_correct_batch(exp, batch_var = "batch", channel = "marker_1")
cr_correct_batch <- function(experiment,
                             batch_var,
                             channel,
                             method = c("median_center", "combat")) {
  cr_validate_experiment(experiment)
  method <- match.arg(method)
  if (!batch_var %in% names(experiment$design)) {
    cli::cli_abort("`{batch_var}` not found in design.")
  }
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found.")
  }
  joined <- .cr_join_design(experiment)
  y <- joined[[channel]]
  b <- joined[[batch_var]]

  if (method == "combat") {
    if (!requireNamespace("sva", quietly = TRUE)) {
      cli::cli_warn("Package {.pkg sva} not available; falling back to median_center.")
      method <- "median_center"
    }
  }
  if (method == "combat") {
    mat <- matrix(y, nrow = 1)
    colnames(mat) <- seq_along(y)
    corrected <- tryCatch(
      sva::ComBat(dat = mat, batch = as.factor(b)),
      error = function(e) {
        cli::cli_warn("ComBat failed: {e$message}. Falling back to median_center.")
        NULL
      }
    )
    if (!is.null(corrected)) {
      experiment$cells[[channel]] <- as.numeric(corrected[1, ])
      return(experiment)
    }
  }
  # median-center fallback / default
  batch_med <- tapply(y, b, stats::median, na.rm = TRUE)
  overall_med <- stats::median(y, na.rm = TRUE)
  offset <- batch_med[as.character(b)] - overall_med
  experiment$cells[[channel]] <- y - as.numeric(offset)
  experiment
}
