# Shared plot helpers --------------------------------------------------------
#
# Input coercion, column checks and label resolution used by every cr_plot_*
# function, so the same contract holds across the figure set.

# Internal: coerce a plotting input to a data frame.
# Accepts a data frame, a cr_experiment (cells joined to design), or a list
# carrying a data frame in one of `slots`.
.cr_plot_df <- function(x, arg = "x", slots = character()) {
  if (inherits(x, "cr_experiment")) {
    return(dplyr::left_join(x$cells, x$design, by = x$spatial_unit))
  }
  if (is.data.frame(x)) return(tibble::as_tibble(x))
  if (is.list(x)) {
    for (s in slots) {
      if (!is.null(x[[s]]) && is.data.frame(x[[s]])) {
        return(tibble::as_tibble(x[[s]]))
      }
    }
  }
  cli::cli_abort(c(
    "{.arg {arg}} must be a data frame or a {.cls cr_experiment}.",
    "x" = "Got {.cls {class(x)[[1L]]}}.",
    if (length(slots)) {
      c("i" = "A list is accepted when it carries a data frame in \\
               {.field {slots}}.")
    }
  ))
}

# Internal: abort with a cli bullet vector when columns are missing.
.cr_need_cols <- function(df, cols, arg = "data") {
  cols <- cols[!vapply(cols, is.null, logical(1))]
  cols <- unique(unlist(cols, use.names = FALSE))
  missing_cols <- setdiff(cols, names(df))
  if (length(missing_cols)) {
    cli::cli_abort(c(
      "{.arg {arg}} is missing {length(missing_cols)} required \\
       column{?s}: {.val {missing_cols}}.",
      "i" = "Columns present: {.val {names(df)}}."
    ))
  }
  invisible(df)
}

# Internal: resolve a label argument. Every cr_plot_* label follows the same
# contract: NULL takes the computed default, NA drops the label, anything else
# is used verbatim.
.cr_lab <- function(x, default = NULL) {
  if (is.null(x)) return(default)
  if (is.atomic(x) && length(x) && is.na(x[[1L]])) return(NULL)
  x
}

# Internal: first candidate column present in `df`, or NULL.
.cr_first_col <- function(df, candidates) {
  hit <- intersect(candidates, names(df))
  if (length(hit)) hit[[1L]] else NULL
}

# Internal: order the levels of `key` by `value`. Row order in a screen figure
# is computed from the effect, never typed, so it cannot drift from the data.
.cr_order_levels <- function(df, key, value, decreasing = FALSE) {
  agg <- stats::aggregate(df[[value]], by = list(k = as.character(df[[key]])),
                          FUN = function(v) mean(v, na.rm = TRUE))
  agg <- agg[order(agg$x, decreasing = decreasing), , drop = FALSE]
  agg$k
}

# Internal: which intervals exclude the reference, as a sentence.
# Computed rather than typed: the equivalent claim in the source pipeline was
# written by hand once and then no longer tracked the data.
.cr_exclude_zero_text <- function(df, label, ci_low, ci_high, reference = 0,
                                  facet_by = NULL) {
  one <- function(d) {
    keep <- is.finite(d[[ci_low]]) & is.finite(d[[ci_high]]) &
      sign(d[[ci_low]] - reference) == sign(d[[ci_high]] - reference)
    v <- unique(as.character(d[[label]][keep]))
    if (!length(v)) {
      "no interval excludes the reference"
    } else if (length(v) == 1L) {
      paste0(v, "'s interval excludes the reference")
    } else {
      paste0(paste(utils::head(v, -1L), collapse = ", "), " and ",
             v[[length(v)]], " exclude the reference")
    }
  }
  if (is.null(facet_by) || !facet_by %in% names(df)) return(one(df))
  parts <- lapply(split(df, as.character(df[[facet_by]])), one)
  paste(paste0(names(parts), ": ", unlist(parts, use.names = FALSE)),
        collapse = "; ")
}

# Internal: add a facet layer for 1 or 2 facetting variables.
.cr_facet <- function(p, facet_by, scales = "fixed", nrow = NULL) {
  if (is.null(facet_by)) return(p)
  if (length(facet_by) == 1L) {
    return(p + ggplot2::facet_wrap(ggplot2::vars(.data[[facet_by]]),
                                   scales = scales, nrow = nrow))
  }
  p + ggplot2::facet_grid(
    rows = ggplot2::vars(.data[[facet_by[[1L]]]]),
    cols = ggplot2::vars(.data[[facet_by[[2L]]]]),
    scales = scales
  )
}

# Version 0.1.0
