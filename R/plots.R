#' Plate-layout heatmap
#'
#' Draws a plate-layout heatmap for a 96 or 384-well plate, showing
#' a summary metric (median intensity, cell count, etc.) per well.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name for the metric computation.
#' @param metric One of `"median"`, `"mean"`, `"cv"`, `"n_cells"`.
#' @return A `ggplot` object.
#' @seealso [cr_theme()], [cr_palette()]
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_plate(exp, channel = "marker_1", metric = "median")
cr_plot_plate <- function(experiment, channel,
                          metric = c("median", "mean", "cv", "n_cells")) {
  metric <- match.arg(metric)
  m <- cr_compute_metrics(experiment, channel)
  val <- switch(metric,
                median = m$median,
                mean = m$mean,
                cv = m$cv,
                n_cells = m$n_cells)
  rc <- cr_well_to_rowcol(m[[experiment$spatial_unit]])
  df <- tibble::tibble(row = rc$row, col = rc$col, value = val)
  df <- df[!is.na(df$row) & !is.na(df$col), , drop = FALSE]

  ggplot2::ggplot(df, ggplot2::aes(x = .data$col, y = .data$row,
                                   fill = .data$value)) +
    ggplot2::geom_tile(colour = "white", linewidth = 0.3) +
    ggplot2::scale_y_reverse(breaks = seq_len(max(df$row, na.rm = TRUE)),
                             labels = LETTERS[seq_len(max(df$row, na.rm = TRUE))]) +
    ggplot2::scale_x_continuous(breaks = seq_len(max(df$col, na.rm = TRUE)),
                                position = "top") +
    ggplot2::scale_fill_gradientn(
      colours = cr_palette(type = "sequential"), na.value = "grey90"
    ) +
    ggplot2::labs(x = NULL, y = NULL, fill = metric,
                  title = paste0("Plate view: ", channel)) +
    cr_theme(grid = FALSE, legend_position = "right") +
    ggplot2::theme(panel.grid = ggplot2::element_blank())
}

#' Intensity distributions by group
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param group_by Design column to colour / facet on. Default
#'   `"treatment"`.
#' @param geom `"violin"`, `"boxplot"` or `"both"`.
#' @param log_y Log-transform the y-axis (default `TRUE`).
#' @return A `ggplot` object.
#' @seealso [cr_plot_screen()] to overlay the unit of replication.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_intensity(exp, channel = "marker_1")
cr_plot_intensity <- function(experiment, channel,
                              group_by = "treatment",
                              geom = c("violin", "boxplot", "both"),
                              log_y = TRUE) {
  geom <- match.arg(geom)
  joined <- .cr_join_design(experiment)
  if (!group_by %in% names(joined)) {
    cli::cli_abort("`{group_by}` not found.")
  }
  p <- ggplot2::ggplot(joined, ggplot2::aes(x = .data[[group_by]],
                                            y = .data[[channel]],
                                            fill = .data[[group_by]]))
  if (geom %in% c("violin", "both")) {
    p <- p + ggplot2::geom_violin(alpha = 0.6, scale = "width", trim = FALSE)
  }
  if (geom %in% c("boxplot", "both")) {
    p <- p + ggplot2::geom_boxplot(width = 0.2, outlier.size = 0.5,
                                   alpha = if (geom == "both") 0.7 else 0.6)
  }
  if (log_y) p <- p + ggplot2::scale_y_log10(labels = scales::label_number())
  p <- p + cr_scale_group("fill", name = group_by, guide_for = "none") +
    ggplot2::labs(x = NULL, y = channel, fill = group_by) +
    cr_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
                   legend.position = "none")
  p
}

#' Biaxial scatter plot of two channels
#'
#' @param experiment A `cr_experiment`.
#' @param channel_x X-axis channel.
#' @param channel_y Y-axis channel.
#' @param color_by Design column used for colour. Default
#'   `"treatment"`.
#' @param log_x,log_y Log-transform the respective axis.
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_scatter(exp, "DAPI", "marker_1")
cr_plot_scatter <- function(experiment, channel_x, channel_y,
                            color_by = "treatment",
                            log_x = TRUE, log_y = TRUE) {
  joined <- .cr_join_design(experiment)
  p <- ggplot2::ggplot(joined, ggplot2::aes(x = .data[[channel_x]],
                                            y = .data[[channel_y]],
                                            colour = .data[[color_by]],
                                            shape = .data[[color_by]])) +
    ggplot2::geom_point(alpha = 0.4, size = 0.7) +
    cr_scale_group(c("colour", "shape"), name = color_by,
                   guide_for = "all") +
    ggplot2::labs(x = channel_x, y = channel_y, colour = color_by) +
    cr_theme()
  if (log_x) p <- p + ggplot2::scale_x_log10()
  if (log_y) p <- p + ggplot2::scale_y_log10()
  p
}

#' Histogram of channel intensity
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name.
#' @param group_by Design column used for colour.
#' @param facet_by Design column used for facetting (or `NULL`).
#' @param log_x Log-transform the x-axis.
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_histogram(exp, "marker_1")
cr_plot_histogram <- function(experiment, channel,
                              group_by = "treatment",
                              facet_by = NULL,
                              log_x = TRUE) {
  joined <- .cr_join_design(experiment)
  p <- ggplot2::ggplot(joined, ggplot2::aes(x = .data[[channel]],
                                            fill = .data[[group_by]])) +
    ggplot2::geom_histogram(alpha = 0.6, bins = 40, position = "identity") +
    cr_scale_group("fill", name = group_by) +
    ggplot2::labs(x = channel, y = "cell count", fill = group_by) +
    cr_theme()
  if (log_x) p <- p + ggplot2::scale_x_log10()
  if (!is.null(facet_by)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", facet_by)))
  }
  p
}

#' QC dashboard
#'
#' Combines cell count per well, area distributions and intensity
#' distributions into a single multi-panel figure.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name used for the intensity panel.
#' @return A `ggplot` object (facetted).
#' @seealso [cr_plot_qc_gate()] for the gate against each unit's own control.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_qc(exp, channel = "marker_1")
cr_plot_qc <- function(experiment, channel = NULL) {
  cells <- experiment$cells
  spatial <- experiment$spatial_unit
  if (is.null(channel)) channel <- cr_channels(experiment)[1]

  counts <- tibble::tibble(
    metric = "n_cells",
    unit = names(table(cells[[spatial]])),
    value = as.numeric(table(cells[[spatial]]))
  )
  area <- tibble::tibble(
    metric = "area",
    unit = as.character(cells[[spatial]]),
    value = cells$area
  )
  inten <- tibble::tibble(
    metric = channel,
    unit = as.character(cells[[spatial]]),
    value = cells[[channel]]
  )
  df <- dplyr::bind_rows(counts, area, inten)
  df$metric <- factor(df$metric,
                      levels = c("n_cells", "area", channel))

  ggplot2::ggplot(df, ggplot2::aes(y = .data$value)) +
    ggplot2::geom_violin(ggplot2::aes(x = "", fill = .data$metric),
                         scale = "width", trim = FALSE, alpha = 0.7) +
    ggplot2::geom_boxplot(ggplot2::aes(x = ""), width = 0.15,
                          outlier.size = 0.3) +
    ggplot2::facet_wrap(~ metric, scales = "free_y") +
    ggplot2::scale_y_log10() +
    cr_scale_group("fill", guide_for = "none") +
    ggplot2::labs(x = NULL, y = NULL, title = "QC dashboard") +
    cr_theme() +
    ggplot2::theme(legend.position = "none",
                   axis.text.x = ggplot2::element_blank(),
                   axis.ticks.x = ggplot2::element_blank())
}

#' Spatial scatter of cells in a well
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel used for colouring points.
#' @param well Spatial unit (well or slide ID) to plot. If `NULL`,
#'   the first well is chosen.
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_spatial(exp, "marker_1")
cr_plot_spatial <- function(experiment, channel, well = NULL) {
  cells <- experiment$cells
  spatial <- experiment$spatial_unit
  if (is.null(well)) well <- as.character(cells[[spatial]])[1]
  sub <- cells[cells[[spatial]] == well, , drop = FALSE]
  if (!nrow(sub)) cli::cli_abort("Well {.val {well}} not found.")
  ggplot2::ggplot(sub, ggplot2::aes(x = .data$x, y = .data$y,
                                    colour = .data[[channel]])) +
    ggplot2::geom_point(size = 1.5, alpha = 0.8) +
    ggplot2::scale_colour_gradientn(
      colours = cr_palette(type = "sequential"),
      transform = "log10", na.value = "grey85"
    ) +
    ggplot2::coord_equal() +
    ggplot2::labs(title = paste("Well:", well),
                  colour = channel) +
    cr_theme(legend_position = "right")
}

#' Heatmap of channel medians across groups
#'
#' @param experiment A `cr_experiment`.
#' @param channels Character vector of channel names.
#' @param group_by Design column defining rows. Default
#'   `"treatment"`.
#' @param scale One of `"none"`, `"row"`, `"column"`. Scaling centres the
#'   values, so the fill switches from the sequential to the diverging
#'   palette.
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' cr_plot_heatmap(exp, c("DAPI", "marker_1", "marker_2"))
cr_plot_heatmap <- function(experiment, channels,
                            group_by = "treatment",
                            scale = c("none", "row", "column")) {
  scale <- match.arg(scale)
  joined <- .cr_join_design(experiment)
  if (!group_by %in% names(joined)) {
    cli::cli_abort("`{group_by}` not found.")
  }
  missing_chs <- setdiff(channels, names(joined))
  if (length(missing_chs)) {
    cli::cli_abort("Channels not found: {.val {missing_chs}}")
  }
  long <- tidyr::pivot_longer(joined[, c(group_by, channels)],
                              cols = dplyr::all_of(channels),
                              names_to = "channel",
                              values_to = "value")
  agg <- dplyr::summarise(
    dplyr::group_by(long, .data[[group_by]], .data$channel),
    value = stats::median(.data$value, na.rm = TRUE),
    .groups = "drop"
  )
  if (scale == "row") {
    agg <- dplyr::group_by(agg, .data[[group_by]]) |>
      dplyr::mutate(value = (.data$value - mean(.data$value)) /
                      stats::sd(.data$value)) |>
      dplyr::ungroup()
  } else if (scale == "column") {
    agg <- dplyr::group_by(agg, .data$channel) |>
      dplyr::mutate(value = (.data$value - mean(.data$value)) /
                      stats::sd(.data$value)) |>
      dplyr::ungroup()
  }
  ggplot2::ggplot(agg, ggplot2::aes(x = .data$channel,
                                    y = .data[[group_by]],
                                    fill = .data$value)) +
    ggplot2::geom_tile(colour = "white") +
    ggplot2::scale_fill_gradientn(
      colours = cr_palette(
        type = if (scale == "none") "sequential" else "diverging"
      ),
      na.value = "grey90",
      rescaler = if (scale == "none") {
        scales::rescale
      } else {
        function(x, to = c(0, 1), from = range(x, na.rm = TRUE)) {
          scales::rescale_mid(x, to = to, from = from, mid = 0)
        }
      }
    ) +
    ggplot2::labs(x = NULL, y = NULL, fill = "intensity") +
    cr_theme(legend_position = "right")
}

#' Time-course line plot
#'
#' @param experiment A `cr_experiment`. Design table must have a
#'   time variable column.
#' @param timepoint_var Name of the time variable column.
#' @param channel Channel to plot.
#' @param group_by Grouping variable (colour).
#' @return A `ggplot` object.
#' @family visualisation
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' exp$design$timepoint <- rep(c(0, 6, 12, 24), length.out = nrow(exp$design))
#' cr_plot_timeline(exp, "timepoint", "marker_1")
cr_plot_timeline <- function(experiment, timepoint_var, channel,
                             group_by = "treatment") {
  if (!timepoint_var %in% names(experiment$design)) {
    cli::cli_abort("`{timepoint_var}` not in design.")
  }
  joined <- .cr_join_design(experiment)
  agg <- joined |>
    dplyr::group_by(.data[[group_by]], .data[[timepoint_var]]) |>
    dplyr::summarise(
      value = stats::median(.data[[channel]], na.rm = TRUE),
      sd_val = stats::sd(.data[[channel]], na.rm = TRUE),
      .groups = "drop"
    )
  ggplot2::ggplot(agg, ggplot2::aes(x = .data[[timepoint_var]],
                                    y = .data$value,
                                    colour = .data[[group_by]],
                                    group = .data[[group_by]])) +
    ggplot2::geom_line(linewidth = 1) +
    ggplot2::geom_point(ggplot2::aes(shape = .data[[group_by]]), size = 2.4) +
    cr_scale_group(c("colour", "shape"), name = group_by,
                   guide_for = "all") +
    ggplot2::labs(x = timepoint_var, y = channel) +
    cr_theme()
}

# Version 0.1.0
