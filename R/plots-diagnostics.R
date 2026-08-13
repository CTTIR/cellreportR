# Screen diagnostics ---------------------------------------------------------
#
# Figures that report on the design rather than on the result: how many units
# a confirmatory study would need, whether the readout is specific, and which
# units the quality-control gate excluded.

#' Sample-size comparison plot
#'
#' Draws, per group, the number of units a confirmatory study would need when
#' powered on the observed effect beside the number needed when powered on the
#' confidence bound nearer the null.
#'
#' The gap between the two bars is the point of the figure. Powering on the
#' observed effect of a screen's top hit is circular - that group is the
#' largest only because it was selected for being largest - so the
#' conservative bar is the one a confirmatory design should be built on, and a
#' conservative figure exists only where the interval excludes the null.
#'
#' Value labels are drawn in ink above the bars, never inside them, and the
#' number of units already available is folded into the axis label rather than
#' plotted as a marker that collides with the labels on short bars.
#'
#' @param sizes A data frame with one row per group, carrying the two
#'   sample-size columns.
#' @param label Name of the grouping column. `NULL` (default) picks the first
#'   of `group`, `compound`, `treatment` or `label` that is present.
#' @param observed,conservative Names of the two sample-size columns.
#' @param available Optional name of a column giving the units already
#'   available per group; folded into the axis labels in brackets.
#' @param colour_by Column mapped to fill, or `NULL` for a single colour.
#' @param log_y Draw the count axis on a log scale (default `TRUE`, because
#'   the two bars routinely differ by an order of magnitude).
#' @param title,subtitle,caption,x_lab,y_lab Plot labels. `NULL` uses a
#'   computed default; `NA` omits the label.
#' @return A `ggplot` object.
#' @seealso [cr_plot_forest()]
#' @family screen figures
#' @export
#' @examples
#' sizes <- data.frame(
#'   group = c("CompoundA", "CompoundB", "CompoundC"),
#'   n_observed = c(12, 84, 640),
#'   n_conservative = c(46, NA, NA),
#'   n_available = c(6, 6, 6)
#' )
#' cr_plot_sample_size(sizes, available = "n_available")
cr_plot_sample_size <- function(sizes,
                                label = NULL,
                                observed = "n_observed",
                                conservative = "n_conservative",
                                available = NULL,
                                colour_by = NULL,
                                log_y = TRUE,
                                title = NULL,
                                subtitle = NULL,
                                caption = NULL,
                                x_lab = NA,
                                y_lab = NULL) {
  df <- .cr_plot_df(sizes, "sizes", slots = c("sizes", "sample_size"))
  if (is.null(label)) {
    label <- .cr_first_col(df, c("group", "compound", "treatment", "label"))
  }
  if (is.null(label)) {
    cli::cli_abort(c(
      "Could not work out which column labels the groups.",
      "i" = "Pass {.arg label}; columns present are {.val {names(df)}}."
    ))
  }
  .cr_need_cols(df, list(label, observed, conservative, available, colour_by),
                "sizes")

  kinds <- c("powered on observed effect",
             "powered on interval bound nearer the null")
  keep <- unique(c(label, colour_by))
  long <- dplyr::bind_rows(
    dplyr::mutate(df[, keep, drop = FALSE], kind = kinds[[1L]],
                  n = df[[observed]]),
    dplyr::mutate(df[, keep, drop = FALSE], kind = kinds[[2L]],
                  n = df[[conservative]])
  )
  long <- long[is.finite(long$n), , drop = FALSE]
  if (!nrow(long)) {
    cli::cli_abort(c(
      "No finite sample sizes to plot.",
      "i" = "Both {.field {observed}} and {.field {conservative}} are \\
             missing for every group."
    ))
  }
  long$kind <- factor(long$kind, levels = kinds)
  long[[label]] <- factor(as.character(long[[label]]),
                          levels = unique(as.character(df[[label]])))

  dodge <- ggplot2::position_dodge(width = 0.7)
  p <- ggplot2::ggplot(
    long,
    ggplot2::aes(x = .data[[label]], y = .data$n, alpha = .data$kind)
  )
  if (is.null(colour_by)) {
    p <- p + ggplot2::geom_col(position = dodge, width = 0.62,
                               fill = unname(cr_palette(1L)),
                               colour = "grey25", linewidth = 0.2)
  } else {
    p <- p + ggplot2::geom_col(ggplot2::aes(fill = .data[[colour_by]]),
                               position = dodge, width = 0.62,
                               colour = "grey25", linewidth = 0.2) +
      cr_scale_group("fill", name = colour_by)
  }

  p <- p +
    ggplot2::geom_text(
      ggplot2::aes(label = scales::label_comma(accuracy = 1)(.data$n)),
      position = dodge, vjust = -0.45, size = 2.7, colour = "grey15",
      alpha = 1, show.legend = FALSE
    ) +
    ggplot2::scale_alpha_manual(
      values = stats::setNames(c(0.45, 1), kinds), name = NULL,
      drop = FALSE
    )

  if (!is.null(available)) {
    axis_lab <- stats::setNames(
      sprintf("%s\n(%s)", as.character(df[[label]]), df[[available]]),
      as.character(df[[label]])
    )
    p <- p + ggplot2::scale_x_discrete(labels = axis_lab)
  }
  if (log_y) {
    p <- p + ggplot2::scale_y_log10(
      labels = scales::label_comma(),
      expand = ggplot2::expansion(mult = c(0.04, 0.22))
    )
  } else {
    p <- p + ggplot2::scale_y_continuous(
      labels = scales::label_comma(),
      expand = ggplot2::expansion(mult = c(0.04, 0.22))
    )
  }

  n_cons <- sum(is.finite(df[[conservative]]))
  if (is.null(caption)) {
    caption <- sprintf(
      paste0("A conservative n exists only where the interval excludes the ",
             "null: %d of %d group%s.\nWhere it does not, the pale bar is ",
             "the only figure available, and it is not a design basis."),
      n_cons, nrow(df), if (nrow(df) == 1L) "" else "s"
    )
  }
  p +
    ggplot2::labs(
      x = .cr_lab(x_lab),
      y = .cr_lab(
        y_lab,
        if (log_y) "units per group (log scale)" else "units per group"
      ),
      title = .cr_lab(title),
      subtitle = .cr_lab(subtitle),
      caption = .cr_lab(caption)
    ) +
    cr_theme() +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      legend.box = "vertical"
    )
}

#' Specificity control plot
#'
#' Draws the arms of the specificity control side by side: the assay with the
#' detection reagent present against the same exposure with the reagent
#' omitted. No amount of batch standardisation can show that a readout is
#' reagent-dependent rather than background autofluorescence, which is what
#' makes this the strongest validation a method-establishment result has.
#'
#' Accepts either cell-level data (one row per cell, drawn as violins with the
#' arm medians annotated) or an already-summarised table (one row per arm,
#' drawn as columns).
#'
#' @param spec Cell-level or per-arm data: a data frame, or a list carrying
#'   one in a `spec` or `specificity` element.
#' @param arm Name of the column identifying the arm (default `"arm"`).
#' @param value Name of the value column. `NULL` (default) auto-detects:
#'   `median_signal` for a summarised table, otherwise `value`.
#' @param arm_levels Optional character vector fixing the order of the arms.
#' @param colour_by Column mapped to fill, or `NULL` to fill by arm.
#' @param log_y Draw the signal axis on a log scale (default `TRUE`).
#' @param ratio_arms Optional length-2 character vector naming the arms whose
#'   median ratio is reported in the subtitle, as
#'   `c(numerator, denominator)`. When `spec` carries a
#'   `signal_to_background` attribute that value is used instead.
#' @param title,subtitle,x_lab,y_lab Plot labels. `NULL` uses a computed
#'   default; `NA` omits the label.
#' @return A `ggplot` object.
#' @family screen figures
#' @export
#' @examples
#' set.seed(1)
#' spec <- data.frame(
#'   arm = rep(c("reagent omitted\n+ vehicle", "reagent omitted\n+ exposed",
#'               "reagent present\n+ vehicle", "reagent present\n+ exposed"),
#'             each = 60),
#'   value = c(rlnorm(60, 3, 0.3), rlnorm(60, 3.05, 0.3),
#'             rlnorm(60, 4.5, 0.3), rlnorm(60, 6.2, 0.3))
#' )
#' cr_plot_specificity(spec)
cr_plot_specificity <- function(spec,
                                arm = "arm",
                                value = NULL,
                                arm_levels = NULL,
                                colour_by = NULL,
                                log_y = TRUE,
                                ratio_arms = NULL,
                                title = NULL,
                                subtitle = NULL,
                                x_lab = NA,
                                y_lab = NULL) {
  ratio_attr <- attr(spec, "signal_to_background")
  df <- .cr_plot_df(spec, "spec", slots = c("spec", "specificity", "arms"))
  .cr_need_cols(df, list(arm, colour_by), "spec")

  summarised <- FALSE
  if (is.null(value)) {
    value <- .cr_first_col(df, c("value", "median_signal", "median",
                                 "signal"))
    if (is.null(value)) {
      cli::cli_abort(c(
        "Could not work out which column holds the signal.",
        "i" = "Pass {.arg value}; columns present are {.val {names(df)}}."
      ))
    }
  }
  .cr_need_cols(df, value, "spec")
  if (!anyDuplicated(as.character(df[[arm]]))) summarised <- TRUE

  lev <- if (is.null(arm_levels)) {
    unique(as.character(df[[arm]]))
  } else {
    arm_levels
  }
  df[[arm]] <- factor(as.character(df[[arm]]), levels = lev)
  df <- df[!is.na(df[[arm]]) & is.finite(df[[value]]), , drop = FALSE]
  if (log_y) df <- df[df[[value]] > 0, , drop = FALSE]
  if (!nrow(df)) {
    cli::cli_abort("No finite values left to plot.")
  }

  meds <- dplyr::summarise(
    dplyr::group_by(df, .data[[arm]]),
    med = stats::median(.data[[value]], na.rm = TRUE),
    .groups = "drop"
  )

  p <- ggplot2::ggplot(df, ggplot2::aes(x = .data[[arm]],
                                        y = .data[[value]]))
  fill_var <- if (is.null(colour_by)) arm else colour_by
  if (summarised) {
    p <- p + ggplot2::geom_col(ggplot2::aes(fill = .data[[fill_var]]),
                               width = 0.65, colour = "grey25",
                               linewidth = 0.2, alpha = 0.9)
  } else {
    p <- p + ggplot2::geom_violin(ggplot2::aes(fill = .data[[fill_var]]),
                                  scale = "width", trim = TRUE, alpha = 0.85,
                                  linewidth = 0.25, colour = "grey25") +
      ggplot2::geom_text(
        data = meds, inherit.aes = FALSE,
        mapping = ggplot2::aes(x = .data[[arm]], y = .data$med,
                               label = scales::label_comma(accuracy = 1)(
                                 .data$med
                               )),
        nudge_x = 0.34, size = 3, colour = "grey15"
      )
  }
  p <- p + cr_scale_group("fill", name = if (is.null(colour_by)) NULL else
    colour_by, guide_for = if (is.null(colour_by)) "none" else "fill")

  if (log_y) p <- p + ggplot2::scale_y_log10(labels = scales::label_comma())

  ratio <- ratio_attr
  if (is.null(ratio) && !is.null(ratio_arms)) {
    if (length(ratio_arms) != 2L) {
      cli::cli_abort("{.arg ratio_arms} must name exactly two arms.")
    }
    num <- meds$med[match(ratio_arms[[1L]], as.character(meds[[arm]]))]
    den <- meds$med[match(ratio_arms[[2L]], as.character(meds[[arm]]))]
    if (length(num) && length(den) && is.finite(num) && is.finite(den) &&
        den != 0) {
      ratio <- num / den
    }
  }
  if (is.null(subtitle) && !is.null(ratio) && is.finite(ratio)) {
    subtitle <- sprintf(
      "signal-to-background: the reagent-present arm reads %.1f times higher",
      ratio
    )
  }

  p +
    ggplot2::labs(
      x = .cr_lab(x_lab),
      y = .cr_lab(y_lab, value),
      title = .cr_lab(title),
      subtitle = .cr_lab(subtitle)
    ) +
    cr_theme()
}

# Version 0.1.0
