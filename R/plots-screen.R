# Screen figures -------------------------------------------------------------
#
# Figures for a multi-compound screen: the distribution figure that shows the
# unit of replication on top of the cells it summarises, and the forest plot
# of effect sizes with confidence intervals.

#' Distribution figure with the unit of replication overlaid
#'
#' Draws width-scaled violins of the cell-level value for each group, with the
#' per-unit means overplotted as jittered points. Cells are the observations;
#' the unit (well, slide or merged acquisition) is the unit of replication, and
#' drawing both in one panel is what keeps a reader from reading cell counts as
#' replicate counts.
#'
#' The point layer is drawn with a fixed jitter seed so the figure is
#' reproducible, and the subtitle states which layer is the unit of
#' replication rather than leaving it to the caption.
#'
#' @param cells Cell-level data: a data frame, or a `cr_experiment` whose
#'   cells are joined to its design.
#' @param value Name of the cell-level value column, typically a standardised
#'   value such as a log fold change (default `"log2_fc"`).
#' @param group_var Name of the column defining the x-axis groups (default
#'   `"treatment"`).
#' @param units Unit-level data. Either a data frame of one row per unit, or
#'   the name of a column in `cells` identifying the unit, in which case the
#'   per-unit means are computed. `NULL` draws the violins alone.
#' @param unit_value Name of the unit-level value column. Defaults to `value`.
#' @param facet_by One or two column names to facet on, or `NULL`.
#' @param colour_by Column mapped to fill and shape. `NULL` (default) draws a
#'   single colour, because hue that encodes nothing is decoration.
#' @param reference Horizontal reference line, or `NULL` for none (default
#'   `0`, the null of a log fold change).
#' @param seed Integer seed for the point jitter, so the figure reproduces.
#' @param title,subtitle,x_lab,y_lab Plot labels. `NULL` uses a computed
#'   default; `NA` omits the label.
#' @return A `ggplot` object.
#' @seealso [cr_plot_forest()], [cr_theme()], [cr_scale_group()]
#' @family screen figures
#' @export
#' @examples
#' set.seed(1)
#' cells <- data.frame(
#'   treatment = rep(c("Vehicle", "CompoundA", "CompoundB"), each = 120),
#'   well_id = rep(paste0("W", 1:18), each = 20),
#'   log2_fc = c(rnorm(120, 0, 0.5), rnorm(120, -0.8, 0.5),
#'               rnorm(120, -0.2, 0.5))
#' )
#' cr_plot_screen(cells, group_var = "treatment", units = "well_id", seed = 1)
cr_plot_screen <- function(cells,
                           value = "log2_fc",
                           group_var = "treatment",
                           units = NULL,
                           unit_value = NULL,
                           facet_by = NULL,
                           colour_by = NULL,
                           reference = 0,
                           seed = NULL,
                           title = NULL,
                           subtitle = NULL,
                           x_lab = NA,
                           y_lab = NULL) {
  cell_df <- .cr_plot_df(cells, "cells", slots = "cells")
  .cr_need_cols(cell_df, list(value, group_var, facet_by, colour_by), "cells")

  unit_label <- "unit"
  unit_df <- NULL
  if (is.character(units) && length(units) == 1L) {
    if (!units %in% names(cell_df)) {
      cli::cli_abort(c(
        "{.arg units} names a column that is not in {.arg cells}.",
        "x" = "No column {.val {units}}.",
        "i" = "Pass a unit-level data frame instead, or one of \\
               {.val {names(cell_df)}}."
      ))
    }
    unit_label <- units
    keys <- unique(c(units, group_var, facet_by, colour_by))
    unit_df <- dplyr::summarise(
      dplyr::group_by(cell_df, dplyr::across(dplyr::all_of(keys))),
      !!value := mean(.data[[value]], na.rm = TRUE),
      .groups = "drop"
    )
    unit_value <- value
  } else if (!is.null(units)) {
    unit_df <- .cr_plot_df(units, "units", slots = "units")
    if (is.null(unit_value)) unit_value <- value
    .cr_need_cols(unit_df, list(unit_value, group_var, facet_by, colour_by),
                  "units")
  }

  p <- ggplot2::ggplot(
    cell_df,
    ggplot2::aes(x = .data[[group_var]], y = .data[[value]])
  )
  if (!is.null(reference) && !is.na(reference)) {
    p <- p + ggplot2::geom_hline(yintercept = reference, linewidth = 0.3,
                                 colour = "grey40")
  }
  if (is.null(colour_by)) {
    p <- p + ggplot2::geom_violin(
      fill = unname(cr_palette(1L)), alpha = 0.45,
      scale = "width", trim = TRUE, linewidth = 0.2, colour = "grey35"
    )
  } else {
    p <- p + ggplot2::geom_violin(
      ggplot2::aes(fill = .data[[colour_by]]), alpha = 0.45,
      scale = "width", trim = TRUE, linewidth = 0.2, colour = "grey35"
    )
  }

  if (!is.null(unit_df) && nrow(unit_df)) {
    jitter <- ggplot2::position_jitter(
      width = 0.12, height = 0,
      seed = if (is.null(seed)) NA else as.integer(seed)
    )
    if (is.null(colour_by)) {
      p <- p + ggplot2::geom_point(
        data = unit_df,
        mapping = ggplot2::aes(x = .data[[group_var]],
                               y = .data[[unit_value]]),
        inherit.aes = FALSE, position = jitter,
        size = 1.7, alpha = 0.95, colour = "grey15",
        shape = 21, fill = unname(cr_palette(1L)), stroke = 0.35
      )
    } else {
      p <- p + ggplot2::geom_point(
        data = unit_df,
        mapping = ggplot2::aes(x = .data[[group_var]],
                               y = .data[[unit_value]],
                               fill = .data[[colour_by]],
                               shape = .data[[colour_by]]),
        inherit.aes = FALSE, position = jitter,
        size = 1.7, alpha = 0.95, colour = "grey15", stroke = 0.35
      )
    }
  }

  if (!is.null(colour_by)) {
    p <- p + cr_scale_group(c("fill", "shape"), name = colour_by,
                            guide_for = "all")
  }
  p <- .cr_facet(p, facet_by)

  if (is.null(subtitle)) {
    subtitle <- if (is.null(unit_df)) {
      "violins = cells"
    } else {
      sprintf("violins = cells; points = %s means, the unit of replication",
              unit_label)
    }
  }
  p +
    ggplot2::labs(
      x = .cr_lab(x_lab),
      y = .cr_lab(y_lab, value),
      title = .cr_lab(title),
      subtitle = .cr_lab(subtitle)
    ) +
    cr_theme() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1)
    )
}

#' Forest plot of effect sizes with confidence intervals
#'
#' Draws one row per contrast: the point estimate with its confidence
#' interval, a reference line at the null, and the rows ordered by the
#' estimate rather than alphabetically, so the ordering is computed from the
#' data and cannot go stale.
#'
#' The default subtitle states which intervals exclude the reference. It is
#' computed from the interval bounds for the same reason: the equivalent
#' sentence written by hand in the source pipeline stopped matching the data
#' the first time the data changed.
#'
#' @param effects A data frame of effect sizes (for example the output of an
#'   effect-size grid), a `cr_result`, or a list of `cr_result`s.
#' @param estimate,ci_low,ci_high Names of the estimate and interval columns.
#' @param label Name of the column identifying each row. `NULL` (default)
#'   picks the first of `group`, `compound`, `treatment`, `contrast`, `label`
#'   or `term` that is present.
#' @param facet_by One or two column names to facet on, or `NULL`.
#' @param colour_by Column mapped to colour, fill and shape, or `NULL`.
#' @param method Effect-size method to keep when `effects` carries a `method`
#'   column with several methods (default `"cohens_d"`).
#' @param reference Position of the null reference line (default `0`).
#' @param order_by_estimate Order rows by the estimate (default `TRUE`).
#'   `FALSE` keeps the order of `label`.
#' @param descending Order largest estimate at the top (default `FALSE`, which
#'   puts the most negative - typically the strongest protection - at the top).
#' @param title,subtitle,x_lab,y_lab Plot labels. `NULL` uses a computed
#'   default; `NA` omits the label.
#' @return A `ggplot` object.
#' @seealso [cr_plot_screen()], [cr_plot_effect_sizes()]
#' @family screen figures
#' @export
#' @examples
#' effects <- data.frame(
#'   group = c("CompoundA", "CompoundB", "CompoundC"),
#'   estimate = c(-1.2, -0.35, 0.1),
#'   ci_low = c(-1.9, -0.95, -0.4),
#'   ci_high = c(-0.5, 0.25, 0.6)
#' )
#' cr_plot_forest(effects)
cr_plot_forest <- function(effects,
                           estimate = "estimate",
                           ci_low = "ci_low",
                           ci_high = "ci_high",
                           label = NULL,
                           facet_by = NULL,
                           colour_by = NULL,
                           method = "cohens_d",
                           reference = 0,
                           order_by_estimate = TRUE,
                           descending = FALSE,
                           title = NULL,
                           subtitle = NULL,
                           x_lab = NULL,
                           y_lab = NA) {
  df <- .cr_effect_frame(effects, method = method, estimate = estimate)
  if (is.null(label)) {
    label <- .cr_first_col(df, c("group", "compound", "treatment", "contrast",
                                 "label", "term"))
  }
  if (is.null(label)) {
    cli::cli_abort(c(
      "Could not work out which column labels the rows.",
      "i" = "Pass {.arg label}; columns present are {.val {names(df)}}."
    ))
  }
  .cr_need_cols(df, list(estimate, ci_low, ci_high, label, facet_by,
                         colour_by), "effects")

  lev <- if (order_by_estimate) {
    .cr_order_levels(df, label, estimate, decreasing = descending)
  } else {
    unique(as.character(df[[label]]))
  }
  df[[label]] <- factor(as.character(df[[label]]), levels = lev)

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = .data[[estimate]], y = .data[[label]])
  ) +
    ggplot2::geom_vline(xintercept = reference, linewidth = 0.4,
                        colour = "grey30")

  if (is.null(colour_by)) {
    p <- p +
      ggplot2::geom_linerange(
        ggplot2::aes(xmin = .data[[ci_low]], xmax = .data[[ci_high]]),
        linewidth = 0.6, colour = unname(cr_palette(1L))
      ) +
      ggplot2::geom_point(size = 2.8, stroke = 0.4, shape = 21,
                          colour = "grey15",
                          fill = unname(cr_palette(1L)))
  } else {
    p <- p +
      ggplot2::geom_linerange(
        ggplot2::aes(xmin = .data[[ci_low]], xmax = .data[[ci_high]],
                     colour = .data[[colour_by]]),
        linewidth = 0.6
      ) +
      ggplot2::geom_point(
        ggplot2::aes(fill = .data[[colour_by]], shape = .data[[colour_by]]),
        size = 2.8, stroke = 0.4, colour = "grey15"
      ) +
      cr_scale_group(c("colour", "fill", "shape"), name = colour_by,
                     guide_for = c("fill", "shape"))
  }

  p <- .cr_facet(p, facet_by)
  if (is.null(subtitle)) {
    subtitle <- .cr_exclude_zero_text(df, label, ci_low, ci_high, reference,
                                      facet_by = if (length(facet_by) == 1L) {
                                        facet_by
                                      } else {
                                        NULL
                                      })
  }

  p +
    ggplot2::scale_y_discrete(limits = rev(lev)) +
    ggplot2::labs(
      x = .cr_lab(x_lab, "effect size (95% CI)"),
      y = .cr_lab(y_lab),
      title = .cr_lab(title),
      subtitle = .cr_lab(subtitle)
    ) +
    cr_theme()
}

# Internal: coerce effect-size input to a plottable data frame.
.cr_effect_frame <- function(effects, method, estimate) {
  if (is.data.frame(effects)) {
    df <- tibble::as_tibble(effects)
    if ("method" %in% names(df) && length(unique(df$method)) > 1L) {
      df <- df[df$method == method, , drop = FALSE]
      if (!nrow(df)) {
        cli::cli_abort(c(
          "No rows left after keeping {.arg method} = {.val {method}}.",
          "i" = "Methods present: {.val {unique(effects$method)}}."
        ))
      }
    }
    return(df)
  }
  if (inherits(effects, "cr_result") || is.list(effects)) {
    return(.cr_effect_sizes_df(effects, method))
  }
  cli::cli_abort(c(
    "{.arg effects} must be a data frame, a {.cls cr_result} or a list \\
     of them.",
    "x" = "Got {.cls {class(effects)[[1L]]}}."
  ))
}

# Version 0.1.0
