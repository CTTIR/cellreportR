#' Summarize cell-level data to the analysis unit
#'
#' Aggregates the per-cell values of one channel to a single number
#' per analysis unit. By default the analysis unit is the spatial unit
#' of the experiment (`well` or `slide`), which is the unit of
#' replication for most plate-based assays. Pass `unit` to aggregate to
#' a merged analysis unit instead — for example when one physical unit
#' was acquired as several files and the acquisitions were assigned a
#' common identifier.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name (a column of `experiment$cells`).
#' @param fun Aggregation function. Default `stats::median`. The
#'   function is called with `na.rm = TRUE` when it accepts that
#'   argument (directly or through `...`), and with the values only
#'   otherwise. It must return a single number.
#' @param unit Optional name of the column that identifies the
#'   analysis unit. May be a column of `cells` or of `design`. If
#'   `NULL` (default) the experiment's `unit_var` slot is used when
#'   present, and the spatial unit otherwise.
#' @return A tibble with one row per analysis unit containing the unit
#'   identifier, `n_cells`, the aggregated `value`, and the design
#'   columns. Design columns that are not constant within a unit are
#'   returned as `NA`.
#' @seealso [cr_compute_metrics()] for a richer per-unit summary and
#'   [cr_table_disposition()] for unit and cell counts per arm.
#' @family quantification
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_summarize_wells(exp, channel = "marker_1")
#'
#' # aggregate with a different estimator
#' cr_summarize_wells(exp, channel = "marker_1", fun = mean)
cr_summarize_wells <- function(experiment, channel, fun = stats::median,
                               unit = NULL) {
  cr_validate_experiment(experiment)
  .cr_check_channel(experiment, channel)
  if (!is.function(fun)) {
    cli::cli_abort("{.arg fun} must be a function.")
  }
  unit <- .cr_unit_var(experiment, unit)
  ix <- .cr_unit_index(experiment, unit)
  values <- experiment$cells[[channel]]
  groups <- .cr_unit_groups(ix$keys)
  agg <- .cr_aggregator(fun)

  out <- tibble::tibble(
    !!unit := names(groups),
    n_cells = vapply(groups, length, integer(1), USE.NAMES = FALSE),
    value = vapply(groups, function(i) agg(values[i]), numeric(1),
                   USE.NAMES = FALSE)
  )
  dplyr::left_join(out, ix$meta, by = unit)
}

#' Compute per-unit summary metrics
#'
#' Returns a rich set of per-unit summary statistics for a single
#' channel: mean, median, SD, MAD, CV, cell count and percent positive
#' above a threshold. Useful as input for QC dashboards and as the
#' between-unit variability input of a screen.
#'
#' @inheritParams cr_summarize_wells
#' @param positive_threshold Optional numeric threshold. Cells above it
#'   are counted as "positive"; without it `pct_positive` is `NA`.
#' @return A tibble with one row per analysis unit and the design
#'   columns appended.
#' @seealso [cr_summarize_wells()], [cr_table_disposition()].
#' @family quantification
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_compute_metrics(exp, channel = "marker_1")
#' cr_compute_metrics(exp, channel = "marker_1", positive_threshold = 800)
cr_compute_metrics <- function(experiment, channel,
                               positive_threshold = NULL,
                               unit = NULL) {
  cr_validate_experiment(experiment)
  .cr_check_channel(experiment, channel)
  if (!is.null(positive_threshold) &&
      (!is.numeric(positive_threshold) || length(positive_threshold) != 1L)) {
    cli::cli_abort("{.arg positive_threshold} must be a single number or {.code NULL}.")
  }
  unit <- .cr_unit_var(experiment, unit)
  ix <- .cr_unit_index(experiment, unit)
  values <- experiment$cells[[channel]]
  groups <- .cr_unit_groups(ix$keys)
  pull <- function(f) {
    vapply(groups, function(i) f(values[i]), numeric(1), USE.NAMES = FALSE)
  }

  out <- tibble::tibble(
    !!unit := names(groups),
    n_cells = vapply(groups, length, integer(1), USE.NAMES = FALSE),
    mean = pull(function(x) mean(x, na.rm = TRUE)),
    median = pull(function(x) stats::median(x, na.rm = TRUE)),
    sd = pull(function(x) stats::sd(x, na.rm = TRUE)),
    mad = pull(function(x) stats::mad(x, na.rm = TRUE)),
    cv = NA_real_,
    pct_positive = NA_real_
  )
  out$cv <- ifelse(out$mean > 0, out$sd / out$mean, NA_real_)
  if (!is.null(positive_threshold)) {
    out$pct_positive <- pull(function(x) {
      if (!length(x)) return(NA_real_)
      100 * mean(x > positive_threshold, na.rm = TRUE)
    })
  }
  dplyr::left_join(out, ix$meta, by = unit)
}

#' Compute fold change relative to a control group
#'
#' Returns log2 fold changes at the cell and unit levels, relative to
#' one pooled reference computed from the control group.
#'
#' The reference is pooled across the whole experiment. When controls
#' differ systematically between plates, runs or acquisition days,
#' standardize each cell against the control of its own batch instead —
#' a pooled reference silently mixes those batches together.
#'
#' @inheritParams cr_summarize_wells
#' @param control_group Value in `design$treatment` that defines the
#'   reference.
#' @param method `"median"` (default) or `"mean"` — the estimator used
#'   to aggregate within a unit before taking log2 ratios.
#' @param eps Additive offset applied to numerator and denominator
#'   before the ratio is taken, i.e. `log2((value + eps) / (ref + eps))`.
#'   The default `0` keeps the historical behavior, which floors the
#'   numerator at a small positive value instead. An additive offset is
#'   the better choice for counts and for signals that legitimately
#'   reach zero, because flooring turns every zero into the same
#'   arbitrary large negative fold change.
#' @return A list with components `cell` (tibble, one row per cell with
#'   `log2_fc`), `well` (one row per analysis unit) and `summary` (per
#'   treatment: number of units, median, mean and SD of the unit-level
#'   log2 fold change).
#' @seealso [cr_summarize_wells()].
#' @family quantification
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' fc <- cr_fold_change(exp, channel = "marker_1",
#'                      control_group = "Untreated")
#' fc$summary
#'
#' # additive offset instead of a floor
#' fc2 <- cr_fold_change(exp, channel = "marker_1",
#'                       control_group = "Untreated", eps = 1)
#' fc2$summary
cr_fold_change <- function(experiment,
                           channel,
                           control_group,
                           method = c("median", "mean"),
                           eps = 0,
                           unit = NULL) {
  cr_validate_experiment(experiment)
  method <- match.arg(method)
  .cr_check_channel(experiment, channel)
  if (!is.numeric(eps) || length(eps) != 1L || is.na(eps) || eps < 0) {
    cli::cli_abort("{.arg eps} must be a single non-negative number.")
  }
  fun <- if (method == "median") stats::median else mean
  unit_var <- .cr_unit_var(experiment, unit)
  wells <- cr_summarize_wells(experiment, channel, fun, unit = unit_var)
  if (!"treatment" %in% names(wells)) {
    cli::cli_abort(c(
      "No {.field treatment} column available at the unit level.",
      "i" = "Treatment is not constant within {.field {unit_var}}."
    ))
  }
  if (!control_group %in% wells$treatment) {
    cli::cli_abort("Control group {.val {control_group}} not found in design.")
  }
  ctrl_ref <- fun(wells$value[wells$treatment == control_group], na.rm = TRUE)
  if (is.na(ctrl_ref) || ctrl_ref <= 0) {
    cli::cli_abort("Control reference is NA or non-positive.")
  }
  ratio <- function(x) {
    if (eps > 0) log2((x + eps) / (ctrl_ref + eps)) else log2(pmax(x, 1e-6) / ctrl_ref)
  }
  wells$log2_fc <- ratio(wells$value)

  spatial <- experiment$spatial_unit
  cell_tbl <- dplyr::left_join(
    experiment$cells[, c("cell_id", spatial, channel)],
    experiment$design[, c(spatial, "treatment")],
    by = spatial
  )
  names(cell_tbl)[3] <- "value"
  cell_tbl$log2_fc <- ratio(cell_tbl$value)

  summary_tbl <- wells |>
    dplyr::group_by(.data$treatment) |>
    dplyr::summarise(
      n_wells = dplyr::n(),
      median_log2_fc = stats::median(.data$log2_fc, na.rm = TRUE),
      mean_log2_fc = mean(.data$log2_fc, na.rm = TRUE),
      sd_log2_fc = stats::sd(.data$log2_fc, na.rm = TRUE),
      .groups = "drop"
    )

  list(cell = cell_tbl, well = wells, summary = summary_tbl)
}

#' Tabulate how many units and cells entered the analysis
#'
#' Counts of analysis units and cells, overall and per arm. The
#' reported counts of an assay are themselves an analysis output: once
#' they are generated from the object that was analyzed, a count in the
#' write-up cannot drift away from the data it describes.
#'
#' @inheritParams cr_summarize_wells
#' @param by Character vector of grouping columns from `design` or
#'   `cells`. Defaults to `"treatment"` when that column exists, and to
#'   no grouping otherwise.
#' @param total Whether to append a row holding the overall counts. The
#'   grouping columns of that row carry the label `"(total)"`.
#' @return A tibble with the grouping columns (as character), `n_units`,
#'   `n_cells` and `median_cells_per_unit`.
#' @seealso [cr_tables()], [cr_macros()].
#' @family quantification
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' cr_table_disposition(exp)
#' cr_table_disposition(exp, by = "group")
cr_table_disposition <- function(experiment, by = NULL, unit = NULL,
                                 total = TRUE) {
  cr_validate_experiment(experiment)
  if (is.null(by)) {
    by <- if ("treatment" %in% names(experiment$design)) "treatment" else character()
  }
  by <- as.character(by)
  unit <- .cr_unit_var(experiment, unit)
  ix <- .cr_unit_index(experiment, unit)

  cells <- experiment$cells
  design <- experiment$design
  spatial <- experiment$spatial_unit
  idx <- match(as.character(cells[[spatial]]), as.character(design[[spatial]]))

  tbl <- tibble::tibble(.unit = ix$keys)
  for (b in by) {
    if (b %in% names(cells)) {
      tbl[[b]] <- as.character(cells[[b]])
    } else if (b %in% names(design)) {
      tbl[[b]] <- as.character(design[[b]])[idx]
    } else {
      cli::cli_abort("Grouping column {.field {b}} not found in cells or design.")
    }
  }
  tbl <- tbl[!is.na(tbl$.unit), , drop = FALSE]

  counts <- function(x) {
    tibble::tibble(
      n_units = dplyr::n_distinct(x$.unit),
      n_cells = nrow(x),
      median_cells_per_unit = stats::median(as.numeric(table(x$.unit)))
    )
  }
  if (length(by)) {
    out <- tbl |>
      dplyr::group_by(dplyr::across(dplyr::all_of(by))) |>
      dplyr::summarise(
        n_units = dplyr::n_distinct(.data$.unit),
        n_cells = dplyr::n(),
        median_cells_per_unit = stats::median(as.numeric(table(.data$.unit))),
        .groups = "drop"
      )
  } else {
    out <- counts(tbl)
    total <- FALSE
  }
  if (isTRUE(total)) {
    all_row <- counts(tbl)
    for (b in by) all_row[[b]] <- "(total)"
    out <- dplyr::bind_rows(out, all_row[, names(out), drop = FALSE])
  }
  out
}

# Internal helpers ----------------------------------------------------------

# Abort with a consistent message when a channel column is absent.
.cr_check_channel <- function(experiment, channel) {
  if (!is.character(channel) || length(channel) != 1L || is.na(channel)) {
    cli::cli_abort("{.arg channel} must be a single channel name.")
  }
  if (!channel %in% names(experiment$cells)) {
    cli::cli_abort(c(
      "Channel {.field {channel}} not found.",
      "i" = "Available: {.val {utils::head(names(experiment$cells), 12)}}"
    ))
  }
  invisible(TRUE)
}

# Internal: resolve the column that identifies the analysis unit.
.cr_unit_var <- function(experiment, unit = NULL) {
  known <- function(x) {
    is.character(x) && length(x) == 1L && !is.na(x) &&
      (x %in% names(experiment$cells) || x %in% names(experiment$design))
  }
  if (!is.null(unit)) {
    if (!is.character(unit) || length(unit) != 1L || is.na(unit)) {
      cli::cli_abort("{.arg unit} must be a single column name.")
    }
    if (!known(unit)) {
      cli::cli_abort(c(
        "Unit column {.field {unit}} not found.",
        "i" = "It must be a column of {.field cells} or of {.field design}."
      ))
    }
    return(unit)
  }
  slot <- experiment[["unit_var"]]
  if (known(slot)) return(slot)
  experiment$spatial_unit
}

# Internal: per-cell unit keys plus the design metadata collapsed to
# one row per unit. Design values that vary inside a unit become NA,
# which is deliberate: silently keeping the first value would hide a
# merge that pooled two different treatments into one unit.
.cr_unit_index <- function(experiment, unit) {
  cells <- experiment$cells
  design <- experiment$design
  spatial <- experiment$spatial_unit

  if (unit %in% names(cells)) {
    keys <- as.character(cells[[unit]])
  } else {
    lut <- stats::setNames(as.character(design[[unit]]),
                           as.character(design[[spatial]]))
    keys <- unname(lut[as.character(cells[[spatial]])])
  }

  map <- tibble::tibble(
    .unit = keys,
    .spatial = as.character(cells[[spatial]])
  )
  map <- dplyr::distinct(map[!is.na(map$.unit), , drop = FALSE])
  design2 <- design
  design2$.spatial <- as.character(design2[[spatial]])
  map <- dplyr::left_join(map, design2, by = ".spatial")

  carry <- setdiff(names(design), unit)
  meta <- map |>
    dplyr::group_by(.data$.unit) |>
    dplyr::summarise(
      dplyr::across(dplyr::all_of(carry), .cr_collapse_unique),
      .groups = "drop"
    )
  names(meta)[1] <- unit
  list(keys = keys, meta = meta)
}

# Internal: single value if constant within the group, typed NA otherwise.
.cr_collapse_unique <- function(x) {
  u <- unique(x)
  if (length(u) == 1L) u[[1]] else x[NA_integer_][[1]]
}

# Internal: split row indices by unit key, dropping cells without one.
.cr_unit_groups <- function(keys) {
  keep <- which(!is.na(keys))
  if (!length(keep)) {
    cli::cli_abort("No cells carry an analysis unit identifier.")
  }
  if (length(keep) < length(keys)) {
    cli::cli_warn("Dropping {length(keys) - length(keep)} cell{?s} without a unit identifier.")
  }
  split(keep, keys[keep])
}

# Internal: wrap an aggregation function so na.rm is passed only when
# the function can take it, and the result is checked to be scalar.
.cr_aggregator <- function(fun) {
  f <- tryCatch(formals(fun), error = function(e) NULL)
  if (is.null(f)) f <- tryCatch(formals(args(fun)), error = function(e) NULL)
  na_rm <- any(c("na.rm", "...") %in% names(f))
  function(x) {
    val <- if (na_rm) fun(x, na.rm = TRUE) else fun(x)
    if (length(val) != 1L) {
      cli::cli_abort("{.arg fun} must return a single value, not {length(val)}.")
    }
    as.numeric(val)
  }
}

# Version 0.1.0
