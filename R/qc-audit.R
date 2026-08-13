# Auditing the gate: what its exclusions cost, applying them, and the
# per-unit record that keeps the decision reviewable afterwards.

#' Quantify the leverage of gate exclusions
#'
#' Re-estimates every contrast affected by a gate exclusion twice —
#' with the failing unit retained and with it removed — so that "one
#' excluded unit changes the verdict" carries a number rather than a
#' recollection. This matters most when an excluded unit sits in the
#' *reference* arm, where retaining it makes the untreated condition
#' look as though it were already responding.
#'
#' Call this **before** [cr_apply_gate()]: the "retained" state needs
#' the failing units to still be present in `experiment`.
#'
#' @param experiment A `cr_experiment` that still contains the gated
#'   units.
#' @param gate A `cr_qc_gate` from [cr_qc_gate()].
#' @param value Per-cell numeric column averaged to the unit level
#'   before the contrast is taken. Default `"log2_fc"`.
#' @param group_var Column holding the arm labels of the contrast.
#' @param reference_level Level of `group_var` used as the reference
#'   arm.
#' @param comparison_levels Levels contrasted against the reference.
#'   `NULL` (default) uses every other level present.
#' @param by Optional character vector of columns to compute the
#'   contrasts within (for example the compound).
#' @param unit Analysis unit column. Defaults to the gate's unit.
#' @param min_units Minimum number of units per arm; contrasts below
#'   it return `NA` estimates. Default `3`.
#' @param affected_only Restrict the output to `by` groups that
#'   actually lost a unit. Default `TRUE`.
#' @return A tibble with one row per `by` group and contrast:
#'   unit counts in both states, `estimate_with_excluded`,
#'   `estimate_without_excluded`, their magnitudes, and whether the
#'   magnitude or the sign changes when the unit is dropped. The
#'   estimate is a pooled, uncorrected standardised mean difference.
#' @seealso [cr_qc_gate()], [cr_apply_gate()].
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
#' exp$cells$signal <- log2(exp$cells$marker_1)
#' gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
#' cr_qc_gate_impact(exp, gate,
#'   value = "signal",
#'   group_var = "treatment",
#'   reference_level = "Untreated"
#' )
cr_qc_gate_impact <- function(experiment,
                              gate,
                              value = "log2_fc",
                              group_var,
                              reference_level,
                              comparison_levels = NULL,
                              by = NULL,
                              unit = NULL,
                              min_units = 3,
                              affected_only = TRUE) {
  cr_validate_experiment(experiment)
  .cr_check_gate(gate)
  unit <- unit %||% gate$params$unit
  unit <- .cr_qc_unit(experiment, unit)
  by <- by %||% character()
  tbl <- .cr_qc_cells(experiment)
  .cr_qc_require(tbl, c(value, group_var, by))
  if (!is.numeric(tbl[[value]])) {
    cli::cli_abort("{.arg value} must name a numeric column; {.field {value}} is not.")
  }

  tbl$.cr_value <- tbl[[value]]
  units <- tbl |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(by, group_var, unit)))) |>
    dplyr::summarise(unit_value = .cr_qc_stat(.data$.cr_value, mean),
                     .groups = "drop")
  units <- units[is.finite(units$unit_value), , drop = FALSE]
  units$.cr_excluded <- as.character(units[[unit]]) %in% gate$excluded

  empty <- .cr_impact_empty(by)
  if (!length(gate$excluded)) return(empty)
  if (!any(units$.cr_excluded)) {
    cli::cli_warn(c(
      "None of the gated units are present in {.arg experiment}.",
      "i" = "Call {.fn cr_qc_gate_impact} before {.fn cr_apply_gate}."
    ))
    return(empty)
  }

  levels_present <- unique(as.character(units[[group_var]]))
  if (!reference_level %in% levels_present) {
    cli::cli_abort(c(
      "Reference level {.val {reference_level}} not found in {.field {group_var}}.",
      "i" = "Levels present: {.val {utils::head(levels_present, 8)}}"
    ))
  }
  comparison_levels <- comparison_levels %||%
    setdiff(levels_present, reference_level)

  keys <- if (length(by)) {
    dplyr::distinct(units[by])
  } else {
    tibble::tibble(.cr_all = "all")
  }
  res <- lapply(seq_len(nrow(keys)), function(i) {
    sub <- if (length(by)) {
      dplyr::semi_join(units, keys[i, , drop = FALSE], by = by)
    } else {
      units
    }
    if (affected_only && !any(sub$.cr_excluded)) return(NULL)
    rows <- lapply(comparison_levels, function(lvl) {
      arm <- function(l, drop_excluded) {
        keep <- as.character(sub[[group_var]]) == l
        if (drop_excluded) keep <- keep & !sub$.cr_excluded
        sub$unit_value[keep]
      }
      ref_with <- arm(reference_level, FALSE)
      cmp_with <- arm(lvl, FALSE)
      ref_without <- arm(reference_level, TRUE)
      cmp_without <- arm(lvl, TRUE)
      d_with <- .cr_gate_cohens_d(cmp_with, ref_with, min_units)
      d_without <- .cr_gate_cohens_d(cmp_without, ref_without, min_units)
      tibble::tibble(
        contrast = paste0(reference_level, " -> ", lvl),
        n_reference_with = length(ref_with),
        n_comparison_with = length(cmp_with),
        n_reference_without = length(ref_without),
        n_comparison_without = length(cmp_without),
        n_units_excluded = sum(sub$.cr_excluded &
                                 as.character(sub[[group_var]]) %in%
                                   c(reference_level, lvl)),
        estimate_with_excluded = d_with,
        magnitude_with_excluded = .cr_gate_magnitude(d_with),
        estimate_without_excluded = d_without,
        magnitude_without_excluded = .cr_gate_magnitude(d_without),
        magnitude_changed = !identical(.cr_gate_magnitude(d_with),
                                       .cr_gate_magnitude(d_without)),
        sign_changed = is.finite(d_with) && is.finite(d_without) &&
          sign(d_with) != sign(d_without)
      )
    })
    rows <- dplyr::bind_rows(rows)
    # A contrast whose arms are not both present in this group is not a
    # contrast; dropping it keeps the leverage table readable.
    rows <- rows[rows$n_reference_with > 0 & rows$n_comparison_with > 0, ,
                 drop = FALSE]
    if (!nrow(rows)) return(NULL)
    if (length(by)) {
      dplyr::bind_cols(keys[rep(i, nrow(rows)), , drop = FALSE], rows)
    } else {
      rows
    }
  })
  out <- dplyr::bind_rows(res)
  if (!nrow(out)) return(empty)
  out
}

#' Apply a QC gate to an experiment
#'
#' Removes the cells of every unit the gate excluded, records the step
#' in the QC log and stores the gate on the experiment so the decision
#' remains auditable after the data have been trimmed.
#'
#' @param experiment A `cr_experiment`.
#' @param gate A `cr_qc_gate` from [cr_qc_gate()].
#' @param units Optional character vector of unit identifiers to
#'   remove instead of `gate$excluded`, for a reviewed exclusion list.
#' @param drop_disputed Also drop the units whose verdict depends on
#'   which control centre is used. Default `FALSE`.
#' @return A modified `cr_experiment`. The gate is stored in
#'   `metadata$qc_gate`.
#' @seealso [cr_qc_gate()], [cr_qc_gate_impact()], [cr_qc_report()].
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
#' gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
#' exp2 <- cr_apply_gate(exp, gate)
#' cr_qc_summary(exp2)
cr_apply_gate <- function(experiment,
                          gate,
                          units = NULL,
                          drop_disputed = FALSE) {
  cr_validate_experiment(experiment)
  .cr_check_gate(gate)
  unit <- .cr_qc_unit(experiment, gate$params$unit)
  drop <- units %||% gate$excluded
  if (isTRUE(drop_disputed)) {
    drop <- unique(c(drop, as.character(gate$disputed[[unit]])))
  }
  before <- nrow(experiment$cells)
  if (length(drop)) {
    keep <- !as.character(experiment$cells[[unit]]) %in% drop
    experiment$cells <- experiment$cells[keep, , drop = FALSE]
  }
  experiment$metadata$qc_gate <- gate
  experiment <- .cr_log_qc(
    experiment, "cr_apply_gate",
    .cr_params_str(list(unit = unit,
                        channel = gate$params$channel,
                        control_level = gate$params$control_level,
                        rule = paste0(gate$params$statistic, " vs ",
                                      gate$params$reference),
                        units_removed = length(drop))),
    before, nrow(experiment$cells)
  )
  experiment
}

#' Report every analysis unit with its QC verdict
#'
#' Returns one row per analysis unit so that the gate can be audited:
#' which units were seen, what their signal was relative to their own
#' control, which were excluded and why, and how many cells each still
#' contributes. Units the gate removed are kept in the report — a gate
#' whose casualties disappear from the record cannot be reviewed.
#'
#' @param experiment A `cr_experiment`.
#' @param gate Optional `cr_qc_gate`. Defaults to the gate stored by
#'   [cr_apply_gate()] in `metadata$qc_gate`, if any.
#' @param unit Analysis unit column. Defaults to the gate's unit, or
#'   the experiment's unit / spatial unit.
#' @param vars Optional character vector of extra design columns to
#'   carry into the report. `NULL` (default) carries the columns the
#'   gate was batched on.
#' @return A tibble with one row per unit: the unit identifier, the
#'   requested design columns, `n_cells_gated` (cells the gate saw),
#'   `n_cells` (cells present now), `retained`, and — when a gate is
#'   available — the control statistics, `pct_of_control`,
#'   `fails_vs_median`, `fails_vs_mean`, `disputed`, `verdict` and
#'   `reason`. Failing units are listed first.
#' @seealso [cr_qc_gate()], [cr_apply_gate()], [cr_qc_summary()].
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
#' gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
#' exp2 <- cr_apply_gate(exp, gate)
#' rep <- cr_qc_report(exp2)
#' head(rep[, c("well", "n_cells", "verdict", "reason")])
#'
#' # without a gate the report is still a per-unit inventory
#' head(cr_qc_report(exp))
cr_qc_report <- function(experiment,
                         gate = NULL,
                         unit = NULL,
                         vars = NULL) {
  cr_validate_experiment(experiment)
  gate <- gate %||% experiment$metadata$qc_gate
  if (!is.null(gate)) .cr_check_gate(gate)
  unit <- unit %||% gate$params$unit
  unit <- .cr_qc_unit(experiment, unit)

  counts <- table(as.character(experiment$cells[[unit]]))
  now <- tibble::tibble(.cr_unit = names(counts),
                        n_cells = as.integer(counts))

  if (is.null(gate)) {
    tbl <- .cr_qc_cells(experiment)
    vars <- vars %||% setdiff(names(experiment$design),
                              c(experiment$spatial_unit, unit))
    vars <- intersect(vars, names(tbl))
    out <- dplyr::distinct(tbl[c(unit, vars)])
    out$.cr_unit <- as.character(out[[unit]])
    out <- dplyr::left_join(out, now, by = ".cr_unit")
    out$n_cells[is.na(out$n_cells)] <- 0L
    out$n_cells_gated <- NA_integer_
    out$retained <- out$n_cells > 0L
    out$verdict <- "not gated"
    out$reason <- "no gate applied"
    out$.cr_unit <- NULL
    return(out)
  }

  units <- gate$units
  want <- vars %||% gate$params$batch_vars
  keep <- c(unit, want, "condition", "is_control", "n_cells",
            "raw_mean", "raw_median", "ctrl_n", "ctrl_mean", "ctrl_median",
            "ctrl_sd", "unit_statistic", "control_reference",
            "pct_of_control", "fails_vs_median", "fails_vs_mean",
            "disputed", "gated", "verdict", "reason")
  out <- units[intersect(keep, names(units))]
  # Columns the gate did not batch on are looked up per unit, so that a
  # report can carry design facts the gate never needed.
  add <- setdiff(want, names(out))
  if (length(add)) {
    src <- experiment$design
    if (!unit %in% names(src) || !all(add %in% names(src))) {
      src <- .cr_qc_cells(experiment)
    }
    add <- intersect(add, names(src))
    if (length(add) && unit %in% names(src)) {
      map <- dplyr::distinct(src[c(unit, add)])
      map <- map[!duplicated(map[[unit]]), , drop = FALSE]
      out <- dplyr::left_join(out, map, by = unit)
      out <- out[c(unit, intersect(want, names(out)),
                   setdiff(names(out), c(unit, want)))]
    }
  }
  names(out)[names(out) == "n_cells"] <- "n_cells_gated"
  out$.cr_unit <- as.character(out[[unit]])
  out <- dplyr::left_join(out, now, by = ".cr_unit")
  out$n_cells[is.na(out$n_cells)] <- 0L
  out$retained <- out$n_cells > 0L
  out$.cr_unit <- NULL

  ord <- order(match(out$verdict, c("fail", "not gated", "pass", "control")),
               !out$disputed, as.character(out[[unit]]))
  out[ord, , drop = FALSE]
}

# Internal: pooled, uncorrected standardised mean difference
.cr_gate_cohens_d <- function(x, y, min_n = 3) {
  x <- x[is.finite(x)]
  y <- y[is.finite(y)]
  if (length(x) < min_n || length(y) < min_n) return(NA_real_)
  nx <- length(x)
  ny <- length(y)
  s2 <- ((nx - 1) * stats::var(x) + (ny - 1) * stats::var(y)) / (nx + ny - 2)
  if (!is.finite(s2) || s2 <= 0) return(NA_real_)
  (mean(x) - mean(y)) / sqrt(s2)
}

# Internal: conventional magnitude labels for a standardised difference
.cr_gate_magnitude <- function(d) {
  if (!length(d) || !is.finite(d)) return(NA_character_)
  a <- abs(d)
  if (a < 0.2) "negligible" else if (a < 0.5) "small" else
    if (a < 0.8) "medium" else "large"
}

# Internal: typed zero-row result for cr_qc_gate_impact()
.cr_impact_empty <- function(by = character()) {
  out <- tibble::tibble(
    contrast = character(),
    n_reference_with = integer(),
    n_comparison_with = integer(),
    n_reference_without = integer(),
    n_comparison_without = integer(),
    n_units_excluded = integer(),
    estimate_with_excluded = numeric(),
    magnitude_with_excluded = character(),
    estimate_without_excluded = numeric(),
    magnitude_without_excluded = character(),
    magnitude_changed = logical(),
    sign_changed = logical()
  )
  for (v in rev(by)) out <- tibble::add_column(out, !!v := character(),
                                               .before = 1L)
  out
}

# Version 0.1.0
