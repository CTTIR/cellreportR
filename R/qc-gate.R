#' Gate analysis units against their own in-batch control
#'
#' A biological rather than a statistical gate: a treated unit must
#' carry more target signal than the vehicle control acquired in its
#' own batch. Units that do not are candidates for exclusion. The
#' comparison is made against the control of the unit's *own* batch,
#' so a plate that ran hot or cold as a whole cannot pass or fail
#' units in unrelated batches.
#'
#' @details
#' Two properties of this gate decide whether it is honest, and both
#' are made explicit here.
#'
#' **Like for like.** Target signal is usually right-skewed, so a
#' control's mean sits above its median. Comparing a unit's median
#' against the control's *mean* is therefore silently stricter than
#' the rule it claims to apply. Because the gate can only ever drop
#' *low* units, an over-strict gate manufactures apparent treatment
#' effects. Both verdicts are computed for every unit —
#' `fails_vs_median` and `fails_vs_mean` — and the units whose verdict
#' *depends* on that choice are returned in `$disputed`. The default
#' (`statistic = "median"`, `reference = "median"`) is like for like.
#'
#' **Leverage.** Excluding a unit changes the estimate it fed into.
#' Quantify that with [cr_qc_gate_impact()] *before* calling
#' [cr_apply_gate()], while both states are still in hand.
#'
#' Gate the analysis unit, not the acquisition file: a unit assembled
#' from two files would otherwise be gated twice.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Name of the raw signal column in `cells`.
#' @param control_level Value of `control_var` marking the vehicle
#'   control units.
#' @param batch_vars Character vector of columns (from `cells` or
#'   `design`) whose combination defines one batch. `NULL` (default)
#'   treats the whole experiment as a single batch.
#' @param unit Column identifying the analysis unit. Defaults to the
#'   experiment's unit column, falling back to its spatial unit.
#' @param control_var Column holding the treatment labels. Default
#'   `"treatment"`.
#' @param statistic Centre of the *unit* used for the comparison:
#'   `"median"` (default) or `"mean"`.
#' @param reference Centre of the *control* used as the threshold:
#'   `"median"` (default) or `"mean"`.
#' @param direction `"greater"` (default) requires a unit to exceed
#'   its control; `"less"` requires it to fall below.
#' @param gate_controls Should control units be gated against
#'   themselves? Default `FALSE`; they form the reference arm.
#' @param min_cells Units with fewer than `min_cells` cells fail
#'   regardless of their signal. Default `1`, i.e. no effect.
#' @return An object of class `cr_qc_gate`, a list with:
#'   \describe{
#'     \item{`units`}{One row per analysis unit: cell count, both raw
#'       centres, the control statistics of its batch,
#'       `pct_of_control`, `fails_vs_median`, `fails_vs_mean`,
#'       `disputed`, `verdict` and `reason`.}
#'     \item{`disputed`}{The units whose verdict depends on which
#'       control centre is used.}
#'     \item{`excluded`}{Identifiers of the units that fail under the
#'       chosen `statistic`/`reference` combination.}
#'     \item{`params`}{The arguments the gate was built with.}
#'   }
#' @seealso [cr_qc_gate_impact()], [cr_apply_gate()],
#'   [cr_qc_report()].
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
#' gate <- cr_qc_gate(exp,
#'   channel = "marker_1",
#'   control_level = "Untreated",
#'   batch_vars = "replicate"
#' )
#' gate
#' head(gate$units[, c("well", "n_cells", "pct_of_control", "verdict")])
#' gate$excluded
cr_qc_gate <- function(experiment,
                       channel,
                       control_level,
                       batch_vars = NULL,
                       unit = NULL,
                       control_var = "treatment",
                       statistic = c("median", "mean"),
                       reference = c("median", "mean"),
                       direction = c("greater", "less"),
                       gate_controls = FALSE,
                       min_cells = 1L) {
  cr_validate_experiment(experiment)
  statistic <- match.arg(statistic)
  reference <- match.arg(reference)
  direction <- match.arg(direction)
  unit <- .cr_qc_unit(experiment, unit)
  batch_vars <- batch_vars %||% character()

  tbl <- .cr_qc_cells(experiment)
  .cr_qc_require(tbl, c(channel, control_var, batch_vars))
  if (!is.numeric(tbl[[channel]])) {
    cli::cli_abort("{.arg channel} must name a numeric column; {.field {channel}} is not.")
  }
  # Shadow columns keep the data mask out of the way of user column
  # names that happen to match an argument value.
  tbl$.cr_signal <- tbl[[channel]]
  tbl$.cr_condition <- as.character(tbl[[control_var]])
  tbl$.cr_is_ctrl <- tbl$.cr_condition == as.character(control_level)
  if (!any(tbl$.cr_is_ctrl)) {
    levels_seen <- utils::head(unique(tbl$.cr_condition), 8)
    cli::cli_abort(c(
      "No cells belong to control level {.val {control_level}}.",
      "i" = "Levels in {.field {control_var}}: {.val {levels_seen}}"
    ))
  }
  bvars <- batch_vars
  if (!length(bvars)) {
    tbl$.cr_batch <- ""
    bvars <- ".cr_batch"
  }

  units <- tbl |>
    dplyr::group_by(dplyr::across(dplyr::all_of(c(unit, bvars)))) |>
    dplyr::summarise(
      n_cells = dplyr::n(),
      condition = paste(unique(.data$.cr_condition), collapse = " | "),
      is_control = any(.data$.cr_is_ctrl),
      raw_mean = .cr_qc_stat(.data$.cr_signal, mean),
      raw_median = .cr_qc_stat(.data$.cr_signal, stats::median),
      .groups = "drop"
    )
  if (anyDuplicated(units[[unit]])) {
    cli::cli_abort(c(
      "Unit {.field {unit}} spans more than one batch.",
      "x" = "Each unit must sit in exactly one combination of {.field {batch_vars}}.",
      "i" = "Assign a unit identifier that already encodes the batch."
    ))
  }

  ctrl <- tbl[tbl$.cr_is_ctrl, , drop = FALSE] |>
    dplyr::group_by(dplyr::across(dplyr::all_of(bvars))) |>
    dplyr::summarise(
      ctrl_n = dplyr::n(),
      ctrl_mean = .cr_qc_stat(.data$.cr_signal, mean),
      ctrl_median = .cr_qc_stat(.data$.cr_signal, stats::median),
      ctrl_sd = .cr_qc_stat(.data$.cr_signal, stats::sd),
      .groups = "drop"
    )
  units <- dplyr::left_join(units, ctrl, by = bvars)

  units$unit_statistic <- if (statistic == "median") {
    units$raw_median
  } else {
    units$raw_mean
  }
  units$control_reference <- if (reference == "median") {
    units$ctrl_median
  } else {
    units$ctrl_mean
  }
  denom <- units$control_reference
  denom[!is.finite(denom) | denom == 0] <- NA_real_
  units$pct_of_control <- 100 * units$unit_statistic / denom

  units$fails_vs_median <- .cr_gate_fail(units$unit_statistic,
                                         units$ctrl_median, direction)
  units$fails_vs_mean <- .cr_gate_fail(units$unit_statistic,
                                       units$ctrl_mean, direction)
  disputed <- !is.na(units$fails_vs_median) &
    !is.na(units$fails_vs_mean) &
    units$fails_vs_median != units$fails_vs_mean

  fails <- if (reference == "median") {
    units$fails_vs_median
  } else {
    units$fails_vs_mean
  }
  thin <- units$n_cells < min_cells
  gated <- (!units$is_control | isTRUE(gate_controls)) & !is.na(fails)
  fails[!gated] <- NA
  fails[thin] <- TRUE

  units$gated <- gated | thin
  units$fails <- fails
  # A verdict can only be disputed where a verdict was reached.
  units$disputed <- disputed & units$gated
  units$verdict <- ifelse(
    is.na(fails), "not gated",
    ifelse(fails, "fail", "pass")
  )
  units$verdict[!units$gated & units$is_control] <- "control"
  units$reason <- ""
  units$reason[units$verdict == "control"] <- "reference arm, not gated"
  units$reason[units$verdict == "not gated" & !units$is_control] <-
    ifelse(is.finite(units$unit_statistic[units$verdict == "not gated" &
                                            !units$is_control]),
           "no control reference in batch", "no finite values")
  fail_word <- if (direction == "greater") "does not exceed" else "does not fall below"
  units$reason[units$verdict == "fail"] <- sprintf(
    "unit %s %s the control %s", statistic, fail_word, reference
  )
  units$reason[thin] <- sprintf("fewer than %d cells", as.integer(min_cells))
  if (!length(batch_vars)) units$.cr_batch <- NULL

  front <- c(unit, batch_vars, "condition", "is_control", "n_cells")
  units <- units[c(front, setdiff(names(units), front))]

  out <- list(
    units = units,
    disputed = units[units$disputed %in% TRUE, , drop = FALSE],
    excluded = as.character(units[[unit]][units$fails %in% TRUE]),
    params = list(
      channel = channel,
      control_level = control_level,
      control_var = control_var,
      batch_vars = batch_vars,
      unit = unit,
      statistic = statistic,
      reference = reference,
      direction = direction,
      gate_controls = isTRUE(gate_controls),
      min_cells = as.integer(min_cells)
    )
  )
  class(out) <- c("cr_qc_gate", "list")
  out
}

#' Print a QC gate
#'
#' @param x A `cr_qc_gate` from [cr_qc_gate()].
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @family quality control
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
#' print(gate)
print.cr_qc_gate <- function(x, ...) {
  p <- x$params
  cli::cli_h1("QC gate")
  cli::cli_text("Signal {.field {p$channel}} vs {.val {p$control_level}} of the same batch")
  cli::cli_text("Rule: unit {p$statistic} must be {p$direction} than the control {p$reference}")
  g <- x$units$gated
  cli::cli_ul(c(
    "{nrow(x$units)} unit{?s}, {sum(g)} gated",
    "{sum(x$units$fails_vs_median[g] %in% TRUE)} fail vs the control median",
    "{sum(x$units$fails_vs_mean[g] %in% TRUE)} fail vs the control mean",
    "{length(x$excluded)} excluded under the chosen rule"
  ))
  if (nrow(x$disputed)) {
    cli::cli_alert_warning(
      "{nrow(x$disputed)} verdict{?s} depend{?s/} on which control centre is used."
    )
  } else {
    cli::cli_alert_success("Verdicts are robust to the control centre used.")
  }
  invisible(x)
}


# Internal: has a unit failed against a given reference centre?
.cr_gate_fail <- function(value, reference, direction) {
  ok <- is.finite(value) & is.finite(reference)
  out <- rep(NA, length(value))
  out[ok] <- if (direction == "greater") {
    value[ok] <= reference[ok]
  } else {
    value[ok] >= reference[ok]
  }
  out
}

# Internal: guard against a non-gate object
.cr_check_gate <- function(gate) {
  if (!inherits(gate, "cr_qc_gate")) {
    cli::cli_abort(c(
      "{.arg gate} must be a {.cls cr_qc_gate}.",
      "x" = "Got {.cls {class(gate)[[1L]]}}.",
      "i" = "Build one with {.fn cr_qc_gate}."
    ))
  }
  invisible(TRUE)
}

# Internal: a statistic that tolerates empty and non-finite input
.cr_qc_stat <- function(x, fn) {
  x <- x[is.finite(x)]
  if (!length(x)) return(NA_real_)
  as.numeric(fn(x))
}

# Version 0.1.0
