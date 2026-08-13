# Cell-population conditioning: what enters the analysis and in what
# proportions. Both steps run between import and standardisation, in
# this order -- see cr_exclude_small() for why the order matters.

#' Exclude sub-threshold objects with a data-derived cut-off
#'
#' Removes objects whose segmentation size falls below a quantile of
#' the observed size distribution. Unlike [cr_qc_filter()], which
#' applies an absolute threshold, the cut-off here is derived from the
#' data, so it adapts to magnification and segmentation settings. The
#' realised threshold is recorded, because a data-derived cut-off is
#' only reproducible if the value it resolved to is reported.
#'
#' Cells with a non-finite value in `var` are always removed: they
#' cannot be placed on either side of the threshold.
#'
#' @details
#' `scope = "pooled"` computes one threshold from all cells. That is
#' the right choice when the segmentation settings were shared across
#' the whole study. `scope = "batch"` computes one threshold per
#' combination of `batch_vars`, which protects a batch acquired at a
#' different magnification from being trimmed against a pool it does
#' not belong to — at the cost of a threshold that is no longer
#' comparable between batches.
#'
#' Run this step *before* [cr_balance_cells()]: balancing changes how
#' many cells each unit contributes to the pool, so a threshold
#' computed afterwards is taken on a differently weighted
#' distribution.
#'
#' @param experiment A `cr_experiment`.
#' @param var Name of the size column in `cells`. Default `"area"`.
#' @param probs Quantile of the `var` distribution used as the
#'   threshold (0-1). Default `0.10`, i.e. the lowest tenth is
#'   dropped. Ignored when `threshold` is supplied.
#' @param threshold Optional absolute threshold. When supplied it
#'   overrides `probs` and is used for every batch.
#' @param scope `"pooled"` (default) computes a single threshold from
#'   all cells; `"batch"` computes one threshold per batch.
#' @param batch_vars Character vector of columns (from `cells` or
#'   `design`) that define a batch. Required when `scope = "batch"`.
#' @return A modified `cr_experiment`. The realised threshold(s) are
#'   stored in `metadata$exclude_small` as a tibble and summarised in
#'   the QC log.
#' @seealso [cr_balance_cells()], [cr_qc_filter()], [cr_qc_report()].
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
#' exp2 <- cr_exclude_small(exp, var = "area", probs = 0.10)
#' exp2$metadata$exclude_small
#'
#' # one threshold per replicate block
#' exp3 <- cr_exclude_small(exp, scope = "batch", batch_vars = "replicate")
#' exp3$metadata$exclude_small
cr_exclude_small <- function(experiment,
                             var = "area",
                             probs = 0.10,
                             threshold = NULL,
                             scope = c("pooled", "batch"),
                             batch_vars = NULL) {
  cr_validate_experiment(experiment)
  scope <- match.arg(scope)
  tbl <- .cr_qc_cells(experiment)
  .cr_qc_require(tbl, var)
  v <- tbl[[var]]
  if (!is.numeric(v)) {
    cli::cli_abort("{.arg var} must name a numeric column; {.field {var}} is not.")
  }
  if (is.null(threshold)) {
    if (!is.numeric(probs) || length(probs) != 1L || is.na(probs) ||
        probs < 0 || probs > 1) {
      cli::cli_abort("{.arg probs} must be a single number between 0 and 1.")
    }
  } else if (!is.numeric(threshold) || length(threshold) != 1L ||
             !is.finite(threshold)) {
    cli::cli_abort("{.arg threshold} must be a single finite number.")
  }

  before <- nrow(experiment$cells)
  if (scope == "pooled") {
    thr <- threshold %||% unname(stats::quantile(v, probs = probs, na.rm = TRUE))
    thresholds <- tibble::tibble(n_cells = length(v), threshold = thr)
    thr_row <- rep(thr, length(v))
    param <- .cr_params_str(list(var = var, probs = probs, scope = scope,
                                 threshold = signif(thr, 6)))
  } else {
    if (!length(batch_vars)) {
      cli::cli_abort(c(
        "{.arg batch_vars} is required when {.code scope = \"batch\"}.",
        "i" = "Name the columns that define one acquisition batch."
      ))
    }
    .cr_qc_require(tbl, batch_vars)
    key <- .cr_qc_key(tbl, batch_vars)
    thr_map <- vapply(split(v, key), function(x) {
      if (!is.null(threshold)) return(threshold)
      if (!length(x) || all(is.na(x))) return(NA_real_)
      unname(stats::quantile(x, probs = probs, na.rm = TRUE))
    }, numeric(1))
    thr_row <- unname(thr_map[key])
    thresholds <- dplyr::distinct(tbl[batch_vars])
    thresholds$n_cells <- as.integer(table(key)[.cr_qc_key(thresholds, batch_vars)])
    thresholds$threshold <- unname(thr_map[.cr_qc_key(thresholds, batch_vars)])
    param <- .cr_params_str(list(
      var = var, probs = probs, scope = scope,
      batches = nrow(thresholds),
      threshold_range = paste(signif(range(thr_row, na.rm = TRUE), 6),
                              collapse = "-")
    ))
  }

  keep <- is.finite(v) & !is.na(thr_row) & v >= thr_row
  experiment$cells <- experiment$cells[keep, , drop = FALSE]
  experiment$metadata$exclude_small <- thresholds
  experiment <- .cr_log_qc(experiment, "cr_exclude_small", param,
                           before, nrow(experiment$cells))
  experiment
}

#' Balance the number of cells per analysis unit
#'
#' Randomly subsamples each analysis unit to a common cell count. A
#' unit acquired in several passes otherwise contributes several times
#' as many cells as its single-pass neighbour and is silently
#' over-weighted in every pooled quantity they share — including the
#' control statistics of their own batch.
#'
#' @details
#' Three modes:
#' \describe{
#'   \item{`n_max`}{cap each unit at `n_max` cells, leaving smaller
#'     units untouched. This is the usual choice for large
#'     acquisitions.}
#'   \item{`n`}{take exactly `n` cells per unit (units with fewer
#'     cells keep all of theirs).}
#'   \item{neither}{take the smallest unit's cell count from every
#'     unit, which equalises the units exactly at the cost of
#'     discarding the most data.}
#' }
#'
#' Subsampling is random, so pass `seed` for a reproducible result.
#' The RNG state of the calling session is saved and restored, so a
#' seeded stream outside this function is never disturbed.
#'
#' @param experiment A `cr_experiment`.
#' @param unit Column in `cells` identifying the analysis unit.
#'   Defaults to the experiment's unit column, falling back to its
#'   spatial unit (`well` / `slide`).
#' @param n_max Optional maximum number of cells per unit.
#' @param n Optional exact number of cells per unit. Cannot be
#'   combined with `n_max`.
#' @param seed Optional integer seed.
#' @return A modified `cr_experiment`. Per-unit counts before and
#'   after are stored in `metadata$balance_cells`.
#' @seealso [cr_exclude_small()], which should run first.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
#' exp2 <- cr_balance_cells(exp, n_max = 20, seed = 1)
#' max(exp2$metadata$balance_cells$n_after)
#'
#' # equalise every unit at the smallest unit's count
#' exp3 <- cr_balance_cells(exp, seed = 1)
#' length(unique(exp3$metadata$balance_cells$n_after))
cr_balance_cells <- function(experiment,
                             unit = NULL,
                             n_max = NULL,
                             n = NULL,
                             seed = NULL) {
  cr_validate_experiment(experiment)
  unit <- .cr_qc_unit(experiment, unit)
  if (!is.null(n) && !is.null(n_max)) {
    cli::cli_abort(c(
      "Supply either {.arg n} or {.arg n_max}, not both.",
      "i" = "{.arg n} takes a fixed count; {.arg n_max} only caps large units."
    ))
  }
  .cr_qc_count(n, "n")
  .cr_qc_count(n_max, "n_max")

  cells <- experiment$cells
  before <- nrow(cells)
  key <- as.character(cells[[unit]])
  idx <- split(seq_len(nrow(cells)), key)
  counts <- lengths(idx)
  target <- if (!is.null(n)) {
    rep(as.integer(n), length(counts))
  } else if (!is.null(n_max)) {
    pmin(counts, as.integer(n_max))
  } else {
    rep(min(counts), length(counts))
  }
  names(target) <- names(counts)

  keep <- .cr_with_seed(seed, unlist(
    lapply(names(idx), function(u) {
      i <- idx[[u]]
      k <- min(length(i), target[[u]])
      if (k >= length(i)) i else sample(i, k)
    }),
    use.names = FALSE
  ))
  experiment$cells <- cells[sort(keep), , drop = FALSE]

  experiment$metadata$balance_cells <- tibble::tibble(
    !!unit := names(counts),
    n_before = as.integer(counts),
    n_after = as.integer(pmin(counts, target))
  )
  experiment <- .cr_log_qc(
    experiment, "cr_balance_cells",
    .cr_params_str(list(unit = unit, n = n, n_max = n_max, seed = seed,
                        units = length(counts))),
    before, nrow(experiment$cells)
  )
  experiment
}

# Version 0.1.0
