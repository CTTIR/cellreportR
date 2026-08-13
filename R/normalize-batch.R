# Per-batch standardization: batch keys, per-batch control references
# and standardization of a channel against the control cells of each
# cell's own batch. Companion to R/normalize.R, which holds the
# pooled-reference normalizations.

#' Construct a batch key
#'
#' A batch is rarely identified by a single column. Once an assay
#' spans several plates, acquisition runs or experiment days, the
#' analytical batch is the *combination* of those columns, and any
#' analysis that standardizes against a control has to respect that
#' combination. `cr_batch_key()` collapses any number of design or
#' cell columns into one character key that can be grouped on, joined
#' on and reported.
#'
#' Missing values are replaced by `na_label` rather than propagated,
#' so that two rows with an unrecorded plate are grouped together
#' visibly instead of silently producing `NA` keys.
#'
#' @param x A `cr_experiment` or a data frame. For a `cr_experiment`
#'   the design columns are joined onto the cells first; a column
#'   present in both tables is taken from `cells`.
#' @param batch_vars Character vector of column names that jointly
#'   define a batch, for example
#'   `c("compound", "run", "plate", "experiment", "interval")`.
#' @param sep Separator placed between the parts of the key.
#' @param na_label Label substituted for missing values.
#'
#' @return A character vector with one key per row of `x` (one key per
#'   cell when `x` is a `cr_experiment`).
#' @export
#' @family batch standardization functions
#' @seealso [cr_batch_reference()], [cr_standardize_batch()]
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
#' key <- cr_batch_key(exp, c("plate", "timepoint"))
#' head(unique(key))
#'
#' # Works on a plain data frame too
#' cr_batch_key(data.frame(a = c("x", "y"), b = 1:2), c("a", "b"))
cr_batch_key <- function(x,
                         batch_vars,
                         sep = " | ",
                         na_label = "<NA>") {
  tbl <- .cr_batch_table(x)
  if (!is.character(batch_vars) || !length(batch_vars)) {
    cli::cli_abort("{.arg batch_vars} must be a non-empty character vector.")
  }
  missing_vars <- setdiff(batch_vars, names(tbl))
  if (length(missing_vars)) {
    cli::cli_abort(c(
      "Batch variables not found: {.field {missing_vars}}.",
      "i" = "Available columns: {.field {utils::head(names(tbl), 20)}}"
    ))
  }
  parts <- lapply(batch_vars, function(v) {
    val <- as.character(tbl[[v]])
    val[is.na(val)] <- na_label
    val
  })
  if (!nrow(tbl)) return(character())
  do.call(paste, c(parts, list(sep = sep)))
}

#' Per-batch control reference statistics
#'
#' Summarizes the control cells of every batch: how many there are,
#' and their mean, median and standard deviation for one channel.
#' This table is the reference that [cr_standardize_batch()] divides
#' by, and it is worth inspecting on its own -- a batch with very few
#' control cells, or none at all, is visible here before any
#' standardized value is computed.
#'
#' Both centres are reported deliberately. A right-skewed signal has
#' `mean > median`, so a downstream gate that compares a well's median
#' against a control *mean* is silently stricter than the rule it
#' states. Keeping both lets each consumer compare like with like.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel column to summarize. Must be numeric.
#' @param control_level Value (or values) of `control_var` that mark
#'   the control cells of a batch.
#' @param batch_vars Character vector of columns that jointly define a
#'   batch. See [cr_batch_key()].
#' @param control_var Column holding the treatment assignment.
#'   Defaults to `"treatment"`.
#' @param sd_floor Lower bound for the control standard deviation. A
#'   batch whose control cells are identical would otherwise divide by
#'   zero.
#'
#' @return A tibble with one row per batch and the columns
#'   \describe{
#'     \item{`batch_vars`}{The columns that define the batch.}
#'     \item{`batch_key`}{The collapsed batch key.}
#'     \item{`n_cells`}{Cells in the batch.}
#'     \item{`ctrl_n`}{Control cells with a finite channel value.}
#'     \item{`ctrl_mean`, `ctrl_median`, `ctrl_sd`}{Control statistics;
#'       `NA` when the batch has no control cells.}
#'     \item{`has_control`}{Whether the batch can be standardized.}
#'   }
#' @export
#' @family batch standardization functions
#' @seealso [cr_standardize_batch()], [cr_batch_key()]
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
#' cr_batch_reference(exp, channel = "marker_1",
#'                    control_level = "Untreated", batch_vars = "plate")
cr_batch_reference <- function(experiment,
                               channel,
                               control_level,
                               batch_vars,
                               control_var = "treatment",
                               sd_floor = 1e-8) {
  cr_validate_experiment(experiment)
  tbl <- .cr_batch_table(experiment)
  .cr_norm_require_col(tbl, channel, "channel")
  .cr_norm_require_col(tbl, control_var, "control_var")
  y <- tbl[[channel]]
  if (!is.numeric(y)) {
    cli::cli_abort("Channel {.field {channel}} must be numeric.")
  }
  if (!length(control_level)) {
    cli::cli_abort("{.arg control_level} must not be empty.")
  }
  key <- cr_batch_key(tbl, batch_vars)
  is_ctrl <- tbl[[control_var]] %in% control_level & is.finite(y)

  keys <- unique(key)
  idx_by_key <- split(seq_along(key), factor(key, levels = keys))
  stat_rows <- lapply(idx_by_key, function(idx) {
    ctrl <- y[idx[is_ctrl[idx]]]
    n <- length(ctrl)
    sd_ctrl <- if (n > 1L) stats::sd(ctrl) else NA_real_
    if (n > 0L && (!is.finite(sd_ctrl) || sd_ctrl <= 0)) sd_ctrl <- sd_floor
    c(
      n_cells = length(idx),
      ctrl_n = n,
      ctrl_mean = if (n > 0L) mean(ctrl) else NA_real_,
      ctrl_median = if (n > 0L) stats::median(ctrl) else NA_real_,
      ctrl_sd = sd_ctrl
    )
  })
  stat_mat <- do.call(rbind, stat_rows)

  ref <- tibble::as_tibble(tbl[match(keys, key), batch_vars, drop = FALSE])
  ref$batch_key <- keys
  ref$n_cells <- as.integer(stat_mat[, "n_cells"])
  ref$ctrl_n <- as.integer(stat_mat[, "ctrl_n"])
  ref$ctrl_mean <- as.numeric(stat_mat[, "ctrl_mean"])
  ref$ctrl_median <- as.numeric(stat_mat[, "ctrl_median"])
  ref$ctrl_sd <- as.numeric(stat_mat[, "ctrl_sd"])
  ref$has_control <- ref$ctrl_n > 0L
  ref
}

#' Standardize a channel against the control of each cell's own batch
#'
#' Expresses every cell relative to the control cells of the batch it
#' belongs to, rather than to one pooled reference for the whole
#' experiment. This is the standardization a plate-based screen needs:
#' plates, runs and acquisition days each carry their own offset, and
#' a single pooled control folds that offset into the estimate.
#'
#' Three quantities are always added, whichever `method` is chosen,
#' because downstream steps need different ones: `log2_fc`, `z_ctrl`
#' and the untouched channel. `method` only decides which of them is
#' copied into `value_to` as the canonical analysis value.
#'
#' @details
#' The log2 fold change uses an *additive* offset,
#' `log2((y + eps) / (ctrl_mean + eps))`, not a floor on `y`. An
#' offset keeps the transformation monotone and well behaved near
#' zero, whereas clamping small values to a floor flattens a whole
#' range of the signal onto one number.
#'
#' The fold change divides by the control **mean** while
#' [cr_batch_reference()] also reports the control **median**; see
#' there for why both are kept.
#'
#' A batch that contains no control cells cannot be standardized: its
#' reference does not exist, and a value computed against some other
#' batch's control would be a silent error rather than a measurement.
#' `cr_standardize_batch()` therefore refuses by default. Use
#' `on_missing_control = "drop"` to remove those cells (recorded in
#' the QC log) or `"warn"` to keep them with `NA` standardized values.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel column to standardize. Must be numeric.
#' @param control_level Value (or values) of `control_var` that mark
#'   the control cells of a batch.
#' @param batch_vars Character vector of columns that jointly define a
#'   batch. See [cr_batch_key()].
#' @param control_var Column holding the treatment assignment.
#'   Defaults to `"treatment"`.
#' @param method Which quantity becomes the canonical analysis value
#'   in `value_to`: `"log2_fc"` (default), `"zscore"` (the per-batch
#'   z-score `z_ctrl`), or `"raw"` (the untransformed channel, for a
#'   like-for-like comparison of standardized against measured
#'   signal).
#' @param eps Additive offset for the log2 fold change.
#' @param sd_floor Lower bound for the control standard deviation.
#' @param value_to Name of the column receiving the value selected by
#'   `method`. Use `NULL` to add the component columns only.
#' @param on_missing_control What to do with batches that have no
#'   control cells: `"error"` (default), `"warn"` or `"drop"`.
#'
#' @return The `cr_experiment` with these columns added to `cells`:
#'   \describe{
#'     \item{`batch_key`}{The batch each cell belongs to.}
#'     \item{`ctrl_n`, `ctrl_mean`, `ctrl_median`, `ctrl_sd`}{The
#'       reference statistics of that batch.}
#'     \item{`z_ctrl`}{`(y - ctrl_mean) / ctrl_sd`.}
#'     \item{`log2_fc`}{`log2((y + eps) / (ctrl_mean + eps))`.}
#'     \item{`value_to`}{The value selected by `method`.}
#'   }
#'   The reference table is stored as `$batch_reference`, the batch
#'   columns as `$batch_vars`, and the settings under
#'   `$metadata$standardization`.
#' @export
#' @family batch standardization functions
#' @seealso [cr_batch_reference()], [cr_batch_key()], [cr_normalize()]
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
#'
#' std <- cr_standardize_batch(exp, channel = "marker_1",
#'                             control_level = "Untreated",
#'                             batch_vars = "plate")
#' round(summary(std$cells$log2_fc), 2)
#' std$batch_reference
#'
#' # Per-batch z-score instead of the fold change
#' z <- cr_standardize_batch(exp, channel = "marker_1",
#'                           control_level = "Untreated",
#'                           batch_vars = "plate", method = "zscore")
#' round(stats::median(z$cells$value_std), 2)
#'
#' # A batch without control cells is refused, not guessed at
#' exp$design$plate[exp$design$treatment == "Untreated"] <- "P1"
#' try(cr_standardize_batch(exp, channel = "marker_1",
#'                          control_level = "Untreated",
#'                          batch_vars = "plate"))
cr_standardize_batch <- function(experiment,
                                 channel,
                                 control_level,
                                 batch_vars,
                                 control_var = "treatment",
                                 method = c("log2_fc", "zscore", "raw"),
                                 eps = 1,
                                 sd_floor = 1e-8,
                                 value_to = "value_std",
                                 on_missing_control = c("error", "warn",
                                                        "drop")) {
  cr_validate_experiment(experiment)
  method <- match.arg(method)
  on_missing_control <- match.arg(on_missing_control)
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort("Channel {.field {channel}} not found in cells.")
  }
  if (!is.numeric(eps) || length(eps) != 1L || !is.finite(eps)) {
    cli::cli_abort("{.arg eps} must be a single finite number.")
  }

  ref <- cr_batch_reference(
    experiment = experiment,
    channel = channel,
    control_level = control_level,
    batch_vars = batch_vars,
    control_var = control_var,
    sd_floor = sd_floor
  )

  bad <- ref$batch_key[!ref$has_control]
  if (length(bad)) {
    msg <- c(
      "{length(bad)} of {nrow(ref)} batches contain no control cells.",
      "x" = "Affected: {.val {utils::head(bad, 3)}}",
      "i" = paste("Control cells are those whose {.field {control_var}}",
                  "is {.val {control_level}}."),
      "i" = paste("Widen {.arg batch_vars}, or set",
                  "{.code on_missing_control = 'drop'} to exclude them.")
    )
    if (on_missing_control == "error") {
      cli::cli_abort(c("Cannot standardize {.field {channel}}.", msg))
    }
    cli::cli_warn(msg)
  }

  tbl <- .cr_batch_table(experiment)
  key <- cr_batch_key(tbl, batch_vars)
  y <- experiment$cells[[channel]]
  pos <- match(key, ref$batch_key)

  ctrl_mean <- ref$ctrl_mean[pos]
  ctrl_sd <- ref$ctrl_sd[pos]
  cells <- experiment$cells
  cells$batch_key <- key
  cells$ctrl_n <- ref$ctrl_n[pos]
  cells$ctrl_mean <- ctrl_mean
  cells$ctrl_median <- ref$ctrl_median[pos]
  cells$ctrl_sd <- ctrl_sd
  cells$z_ctrl <- .cr_finite_or_na((y - ctrl_mean) / ctrl_sd)
  cells$log2_fc <- .cr_log2_ratio(y, ctrl_mean, eps)
  if (!is.null(value_to)) {
    cells[[value_to]] <- switch(
      method,
      log2_fc = cells$log2_fc,
      zscore = cells$z_ctrl,
      raw = y
    )
  }

  n_before <- nrow(cells)
  if (length(bad) && on_missing_control == "drop") {
    keep <- !(key %in% bad)
    cells <- cells[keep, , drop = FALSE]
    ref <- ref[ref$has_control, , drop = FALSE]
  }
  experiment$cells <- cells
  experiment <- .cr_log_qc(
    experiment,
    step = "standardize_batch",
    parameters = paste0("channel=", channel, "; method=", method,
                        "; batch_vars=", paste(batch_vars, collapse = "+"),
                        "; control=", paste(control_level, collapse = "/")),
    before = n_before,
    after = nrow(cells)
  )
  experiment$batch_reference <- ref
  experiment$batch_vars <- batch_vars
  experiment$metadata$standardization <- list(
    channel = channel,
    method = method,
    control_var = control_var,
    control_level = control_level,
    batch_vars = batch_vars,
    eps = eps,
    value_to = value_to,
    n_batches = nrow(ref),
    timestamp = Sys.time()
  )
  experiment
}

# Internal: cells with the design columns they do not already carry.
# Columns present in both tables are taken from `cells`, so a join
# never renames a batch variable to `.x` / `.y` behind the caller.
.cr_batch_table <- function(x) {
  if (inherits(x, "cr_experiment")) {
    cr_validate_experiment(x)
    spatial <- x$spatial_unit
    extra <- setdiff(names(x$design), names(x$cells))
    if (!length(extra)) return(tibble::as_tibble(x$cells))
    return(dplyr::left_join(
      tibble::as_tibble(x$cells),
      x$design[, c(spatial, extra), drop = FALSE],
      by = spatial
    ))
  }
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a {.cls cr_experiment} or a data frame.")
  }
  tibble::as_tibble(x)
}

# Internal: column presence check with a pointed message.
.cr_norm_require_col <- function(tbl, col, arg) {
  if (!is.character(col) || length(col) != 1L) {
    cli::cli_abort("{.arg {arg}} must be a single column name.")
  }
  if (!col %in% names(tbl)) {
    cli::cli_abort(c(
      "{.arg {arg}}: column {.field {col}} not found.",
      "i" = "Available columns: {.field {utils::head(names(tbl), 20)}}"
    ))
  }
  invisible(TRUE)
}

# Internal: non-finite results become NA rather than Inf / NaN.
.cr_finite_or_na <- function(x) {
  x[!is.finite(x)] <- NA_real_
  x
}

# Internal: log2 ratio with an additive offset.
.cr_log2_ratio <- function(y, ref, eps) {
  num <- y + eps
  den <- ref + eps
  out <- rep(NA_real_, length(y))
  ok <- is.finite(num) & is.finite(den) & num > 0 & den > 0
  out[ok] <- log2(num[ok] / den[ok])
  out
}
