# Quality-control and output helpers -----------------------------------------
#
# The gate diagnostic - which units the quality-control gate excluded, and
# whether the verdict survives a change of centre - plus the figure writer
# that carries the publication defaults.

#' Quality-control gate diagnostic plot
#'
#' Plots each unit's statistic against the statistic of the control it is
#' gated on, with the line of equality. Points above the line pass a
#' `"greater"` gate; points below it fail and are excluded.
#'
#' Where the input carries a verdict under both centres, median and mean, the
#' units whose verdict *depends* on which centre was used are drawn as their
#' own class. That distinction matters because a right-skewed signal has
#' a mean above its median, so gating a raw median against a control mean is
#' silently stricter than the stated rule, and a gate that can only drop low
#' units manufactures apparent effects when it is too strict.
#'
#' @param gate A `cr_qc_gate` object, a list carrying a `units` data frame, or
#'   a data frame with one row per unit.
#' @param statistic Name of the unit statistic column. `NULL` (default)
#'   auto-detects.
#' @param reference Name of the control statistic column. `NULL` (default)
#'   auto-detects.
#' @param fails_median,fails_mean Names of the logical verdict columns under
#'   the two centres. `NULL` (default) auto-detects; when neither is present
#'   the verdict is computed from `statistic`, `reference` and `direction`.
#' @param direction `"greater"` (default) when a unit must exceed its control
#'   to pass, `"less"` when it must fall below.
#' @param log_scale Draw both axes on a log scale when every value is
#'   positive (default `TRUE`).
#' @param label Optional column whose values annotate the failing units.
#' @param title,subtitle,x_lab,y_lab Plot labels. `NULL` uses a computed
#'   default; `NA` omits the label.
#' @return A `ggplot` object.
#' @seealso [cr_plot_qc()] for the distribution dashboard.
#' @family screen figures
#' @export
#' @examples
#' set.seed(1)
#' units <- data.frame(
#'   well_id = paste0("W", 1:24),
#'   unit_median = c(rlnorm(20, 5, 0.3), rlnorm(4, 3.9, 0.2)),
#'   ctrl_median = rlnorm(24, 4.2, 0.1)
#' )
#' cr_plot_qc_gate(units, label = "well_id")
cr_plot_qc_gate <- function(gate,
                            statistic = NULL,
                            reference = NULL,
                            fails_median = NULL,
                            fails_mean = NULL,
                            direction = c("greater", "less"),
                            log_scale = TRUE,
                            label = NULL,
                            title = NULL,
                            subtitle = NULL,
                            x_lab = NULL,
                            y_lab = NULL) {
  direction <- match.arg(direction)
  df <- .cr_plot_df(gate, "gate", slots = c("units", "gate"))

  if (is.null(statistic)) {
    statistic <- .cr_first_col(df, c("unit_median", "unit_mean", "statistic",
                                     "unit_stat", "median", "value"))
  }
  if (is.null(reference)) {
    reference <- .cr_first_col(df, c("ctrl_median", "ctrl_mean",
                                     "control_median", "control_mean",
                                     "reference"))
  }
  if (is.null(statistic) || is.null(reference)) {
    cli::cli_abort(c(
      "Could not work out the unit and control statistic columns.",
      "i" = "Pass {.arg statistic} and {.arg reference}; columns present \\
             are {.val {names(df)}}."
    ))
  }
  .cr_need_cols(df, list(statistic, reference, label), "gate")
  if (is.null(fails_median)) {
    fails_median <- .cr_first_col(df, c("fails_vs_median", "fails_median"))
  }
  if (is.null(fails_mean)) {
    fails_mean <- .cr_first_col(df, c("fails_vs_mean", "fails_mean"))
  }

  levels_verdict <- c("passes", "depends on centre", "excluded")
  if (!is.null(fails_median) && !is.null(fails_mean)) {
    fm <- as.logical(df[[fails_median]])
    fa <- as.logical(df[[fails_mean]])
    verdict <- ifelse(fm != fa, levels_verdict[[2L]],
                      ifelse(fm, levels_verdict[[3L]], levels_verdict[[1L]]))
  } else {
    one <- if (!is.null(fails_median)) {
      as.logical(df[[fails_median]])
    } else if (!is.null(fails_mean)) {
      as.logical(df[[fails_mean]])
    } else if (direction == "greater") {
      df[[statistic]] <= df[[reference]]
    } else {
      df[[statistic]] >= df[[reference]]
    }
    verdict <- ifelse(one, levels_verdict[[3L]], levels_verdict[[1L]])
  }
  df$.verdict <- factor(verdict, levels = levels_verdict)
  df <- df[is.finite(df[[statistic]]) & is.finite(df[[reference]]), ,
           drop = FALSE]
  if (!nrow(df)) cli::cli_abort("No finite unit statistics to plot.")

  # Blue / orange / vermillion: no red-green pair carries meaning here.
  cols <- stats::setNames(
    unname(cr_palette()[c("blue", "orange", "vermillion")]), levels_verdict
  )
  shapes <- stats::setNames(c(21L, 24L, 25L), levels_verdict)

  use_log <- log_scale && all(df[[statistic]] > 0) && all(df[[reference]] > 0)

  p <- ggplot2::ggplot(
    df,
    ggplot2::aes(x = .data[[reference]], y = .data[[statistic]])
  ) +
    ggplot2::geom_abline(slope = 1, intercept = 0, linetype = 2,
                         colour = "grey40", linewidth = 0.4) +
    ggplot2::geom_point(
      ggplot2::aes(fill = .data$.verdict, shape = .data$.verdict),
      size = 2.6, stroke = 0.35, colour = "grey15", alpha = 0.95
    ) +
    ggplot2::scale_fill_manual(values = cols, name = NULL, drop = FALSE) +
    ggplot2::scale_shape_manual(values = shapes, name = NULL, drop = FALSE)

  if (!is.null(label)) {
    failing <- df[df$.verdict != levels_verdict[[1L]], , drop = FALSE]
    if (nrow(failing)) {
      p <- p + ggplot2::geom_text(
        data = failing, inherit.aes = FALSE,
        mapping = ggplot2::aes(x = .data[[reference]],
                               y = .data[[statistic]],
                               label = .data[[label]]),
        nudge_y = 0, hjust = -0.25, size = 2.6, colour = "grey25"
      )
    }
  }
  if (use_log) {
    p <- p +
      ggplot2::scale_x_log10(labels = scales::label_comma()) +
      ggplot2::scale_y_log10(labels = scales::label_comma())
  }

  n_units <- nrow(df)
  n_excl <- sum(df$.verdict == levels_verdict[[3L]])
  n_disp <- sum(df$.verdict == levels_verdict[[2L]])
  if (is.null(subtitle)) {
    subtitle <- sprintf(
      "%d unit%s; %d excluded; %d verdict%s depend on the centre used",
      n_units, if (n_units == 1L) "" else "s", n_excl, n_disp,
      if (n_disp == 1L) "" else "s"
    )
  }
  p +
    ggplot2::labs(
      x = .cr_lab(x_lab, paste("control", reference)),
      y = .cr_lab(y_lab, paste("unit", statistic)),
      title = .cr_lab(title),
      subtitle = .cr_lab(subtitle)
    ) +
    cr_theme()
}

#' Save a figure at publication settings
#'
#' Writes one plot to one or more formats with the package's publication
#' defaults: 600 dpi, a white background (so a transparent panel does not
#' render as black in a typeset document) and a golden-ratio height when none
#' is given.
#'
#' @param plot A `ggplot` object, or any object [ggplot2::ggsave()] accepts.
#' @param path Output path. Any extension is replaced by each entry of
#'   `formats`, so one call can write matching raster and vector files.
#' @param width Width in `units` (default `12`).
#' @param height Height in `units`. `NULL` (default) uses `width / 1.618`.
#' @param dpi Raster resolution (default `600`).
#' @param formats Character vector of file extensions to write (default
#'   `c("png", "pdf")`).
#' @param units Passed to [ggplot2::ggsave()] (default `"in"`).
#' @param bg Background colour (default `"white"`).
#' @param quiet Suppress the message naming the written files (default
#'   `FALSE`).
#' @return The written paths, invisibly, as a character vector.
#' @family screen figures
#' @export
#' @examples
#' p <- ggplot2::ggplot(data.frame(x = 1:5, y = 1:5),
#'                      ggplot2::aes(x, y)) +
#'   ggplot2::geom_point() +
#'   cr_theme()
#' out <- file.path(tempdir(), "figure-1")
#' paths <- cr_save_plot(p, out, width = 5, formats = "png")
#' basename(paths)
#' unlink(paths)
cr_save_plot <- function(plot, path, width = 12, height = NULL, dpi = 600,
                         formats = c("png", "pdf"), units = "in",
                         bg = "white", quiet = FALSE) {
  if (!length(formats)) {
    cli::cli_abort("{.arg formats} must name at least one file format.")
  }
  if (is.null(height)) height <- width / 1.618
  base <- sub("\\.[A-Za-z0-9]+$", "", path)
  dir <- dirname(base)
  if (!dir.exists(dir)) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
  }
  out <- vapply(formats, function(fmt) {
    file <- paste0(base, ".", sub("^\\.", "", fmt))
    ggplot2::ggsave(filename = file, plot = plot, width = width,
                    height = height, units = units, dpi = dpi, bg = bg)
    file
  }, character(1), USE.NAMES = FALSE)
  if (!quiet) {
    cli::cli_alert_success("Wrote {length(out)} file{?s} to {.path {dir}}.")
  }
  invisible(out)
}

# Version 0.1.0
