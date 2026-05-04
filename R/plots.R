#' Plate-layout heatmap
#'
#' Draws a plate-layout heatmap for a 96 or 384-well plate, showing
#' a summary metric (median intensity, cell count, etc.) per well.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name for the metric computation.
#' @param metric One of `"median"`, `"mean"`, `"cv"`, `"n_cells"`.
#' @return A ggplot2 object.
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
    ggplot2::scale_fill_viridis_c(option = "plasma", na.value = "grey90") +
    ggplot2::labs(x = NULL, y = NULL, fill = metric,
                  title = paste0("Plate view: ", channel)) +
    ggplot2::theme_minimal() +
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
#' @return A ggplot2 object.
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
  p <- p + ggplot2::scale_fill_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = NULL, y = channel, fill = group_by) +
    ggplot2::theme_minimal() +
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
#' @return A ggplot2 object.
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
                                            colour = .data[[color_by]])) +
    ggplot2::geom_point(alpha = 0.4, size = 0.5) +
    ggplot2::scale_colour_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = channel_x, y = channel_y, colour = color_by) +
    ggplot2::theme_minimal()
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
#' @return A ggplot2 object.
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
    ggplot2::scale_fill_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = channel, y = "cell count", fill = group_by) +
    ggplot2::theme_minimal()
  if (log_x) p <- p + ggplot2::scale_x_log10()
  if (!is.null(facet_by)) {
    p <- p + ggplot2::facet_wrap(stats::as.formula(paste("~", facet_by)))
  }
  p
}

#' Fold-change forest plot
#'
#' @param result A `cr_result`, a list of `cr_result`s (from
#'   [cr_test_all()]), or a precomputed data frame with columns
#'   `treatment`, `median_log2_fc`.
#' @return A ggplot2 object.
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
#' cr_plot_foldchange(res)
#' }
cr_plot_foldchange <- function(result) {
  df <- .cr_fc_dataframe(result)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$median_log2_fc,
                                   y = stats::reorder(.data$treatment,
                                                      .data$median_log2_fc))) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey50", linetype = 2) +
    ggplot2::geom_col(fill = "#7B2D8E", alpha = 0.8) +
    ggplot2::labs(x = "log2 fold change", y = NULL,
                  title = "Fold change vs. control") +
    ggplot2::theme_minimal()
}

.cr_fc_dataframe <- function(result) {
  if (is.data.frame(result)) return(result)
  if (inherits(result, "cr_result")) return(result$fold_change)
  if (is.list(result)) {
    s <- attr(result, "summary")
    if (!is.null(s) && "log2_fc" %in% names(s)) {
      return(tibble::tibble(treatment = s$treatment,
                            median_log2_fc = s$log2_fc))
    }
    parts <- lapply(result, function(r) r$fold_change)
    return(dplyr::distinct(dplyr::bind_rows(parts)))
  }
  cli::cli_abort("Unsupported result type for {.fn cr_plot_foldchange}.")
}

#' Forest plot of effect sizes
#'
#' @param results A single `cr_result`, a list of `cr_result`s (from
#'   [cr_test_all()]) or a precomputed tibble with columns
#'   `treatment`, `method`, `estimate`, `ci_low`, `ci_high`.
#' @param method Effect-size method to plot (default `"cohens_d"`).
#' @return A ggplot2 object.
#' @export
#' @examples
#' \donttest{
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
#' cr_plot_effect_sizes(all_res)
#' }
cr_plot_effect_sizes <- function(results, method = "cohens_d") {
  df <- .cr_effect_sizes_df(results, method)
  ggplot2::ggplot(df, ggplot2::aes(x = .data$estimate,
                                   y = stats::reorder(.data$treatment,
                                                      .data$estimate))) +
    ggplot2::geom_vline(xintercept = 0, colour = "grey50", linetype = 2) +
    ggplot2::geom_point(size = 3, colour = "#7B2D8E") +
    ggplot2::geom_linerange(ggplot2::aes(xmin = .data$ci_low,
                                         xmax = .data$ci_high),
                            colour = "#7B2D8E", linewidth = 0.8) +
    ggplot2::labs(x = paste("Effect size (", method, ")"),
                  y = NULL) +
    ggplot2::theme_minimal()
}

.cr_effect_sizes_df <- function(results, method) {
  if (is.data.frame(results)) {
    return(results[results$method == method, , drop = FALSE])
  }
  if (inherits(results, "cr_result")) {
    df <- results$effect_sizes[results$effect_sizes$method == method, ]
    df$treatment <- results$comparison$treatment
    return(df)
  }
  if (is.list(results)) {
    parts <- lapply(names(results), function(nm) {
      r <- results[[nm]]
      row <- r$effect_sizes[r$effect_sizes$method == method, , drop = FALSE]
      if (nrow(row)) row$treatment <- r$comparison$treatment %||% nm
      row
    })
    return(dplyr::bind_rows(parts))
  }
  cli::cli_abort("Unsupported input to {.fn cr_plot_effect_sizes}.")
}

#' ROC curve plot
#'
#' @param result A single `cr_result` or a list of such results.
#' @return A ggplot2 object.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
#' cr_plot_roc(res)
cr_plot_roc <- function(result) {
  df <- .cr_roc_df(result)
  label_df <- unique(df[, c("name", "auc")])
  ggplot2::ggplot(df, ggplot2::aes(x = .data$fpr, y = .data$tpr,
                                   colour = .data$name)) +
    ggplot2::geom_abline(slope = 1, intercept = 0, colour = "grey60",
                         linetype = 2) +
    ggplot2::geom_path(linewidth = 1) +
    ggplot2::scale_colour_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = "False Positive Rate",
                  y = "True Positive Rate",
                  colour = NULL,
                  title = sprintf(
                    "ROC (AUC %s)",
                    paste(
                      sprintf("%s: %.3f", label_df$name, label_df$auc),
                      collapse = " / "
                    ))) +
    ggplot2::theme_minimal()
}

.cr_roc_df <- function(result) {
  if (inherits(result, "cr_result")) {
    tbl <- cr_roc(result)
    tbl$name <- result$comparison$treatment %||% "comparison"
    tbl$auc <- result$roc$auc
    return(tbl)
  }
  if (is.list(result)) {
    parts <- lapply(names(result), function(nm) {
      r <- result[[nm]]
      if (!inherits(r, "cr_result") || is.null(r$roc)) return(NULL)
      tbl <- cr_roc(r)
      tbl$name <- r$comparison$treatment %||% nm
      tbl$auc <- r$roc$auc
      tbl
    })
    return(dplyr::bind_rows(parts))
  }
  cli::cli_abort("Unsupported input to {.fn cr_plot_roc}.")
}

#' Dose-response plot
#'
#' @param fit A `cr_dose_response`.
#' @return A ggplot2 object.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
#'                           500, exp$design$dose)
#' fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
#' cr_plot_dose_response(fit)
cr_plot_dose_response <- function(fit) {
  if (!inherits(fit, "cr_dose_response")) {
    cli::cli_abort("`fit` must be a {.cls cr_dose_response}.")
  }
  ic50 <- cr_ic50(fit)
  data <- fit$data[, c("dose", "value", "treatment")]
  p <- ggplot2::ggplot(data, ggplot2::aes(x = .data$dose,
                                          y = .data$value)) +
    ggplot2::geom_point(ggplot2::aes(colour = .data$treatment),
                        alpha = 0.8, size = 2) +
    ggplot2::geom_line(data = fit$curve,
                       ggplot2::aes(x = .data$dose, y = .data$y),
                       colour = "#7B2D8E", linewidth = 1) +
    ggplot2::scale_colour_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = "dose", y = fit$channel,
                  title = "Dose-response",
                  subtitle = if (!is.na(ic50$estimate)) {
                    sprintf("IC50 / EC50 = %.3g %s",
                            ic50$estimate,
                            ic50$units %||% "")
                  } else NULL) +
    ggplot2::theme_minimal()
  if (fit$log_dose) p <- p + ggplot2::scale_x_log10()
  p
}

#' QC dashboard
#'
#' Combines cell count per well, area distributions and intensity
#' distributions into a single multi-panel figure.
#'
#' @param experiment A `cr_experiment`.
#' @param channel Channel name used for the intensity panel.
#' @return A ggplot2 object (facetted).
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
    ggplot2::scale_fill_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = NULL, y = NULL, title = "QC dashboard") +
    ggplot2::theme_minimal() +
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
#' @return A ggplot2 object.
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
    ggplot2::scale_colour_viridis_c(option = "plasma",
                                    trans = "log10") +
    ggplot2::coord_equal() +
    ggplot2::labs(title = paste("Well:", well),
                  colour = channel) +
    ggplot2::theme_minimal()
}

#' Comparison panel (box, fold change, p-value) for a single result
#'
#' @param result A `cr_result`.
#' @param experiment A `cr_experiment` (required to reconstruct the
#'   underlying intensity data).
#' @return A ggplot2 object.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
#' res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
#'                test = "mann_whitney", level = "replicate")
#' cr_plot_comparison(res, exp)
cr_plot_comparison <- function(result, experiment) {
  if (!inherits(result, "cr_result")) {
    cli::cli_abort("`result` must be a {.cls cr_result}.")
  }
  cr_validate_experiment(experiment)
  cmp <- result$comparison
  joined <- .cr_join_design(experiment)
  joined <- joined[joined$treatment %in% c(cmp$treatment, cmp$control), , drop = FALSE]
  p_val <- NA_real_
  if (nrow(result$rep_level)) p_val <- result$rep_level$p_value[1]
  else if (nrow(result$cell_level)) p_val <- result$cell_level$p_value[1]

  ggplot2::ggplot(joined, ggplot2::aes(x = .data$treatment,
                                       y = .data[[cmp$channel]],
                                       fill = .data$treatment)) +
    ggplot2::geom_violin(alpha = 0.6, trim = FALSE, scale = "width") +
    ggplot2::geom_boxplot(width = 0.15, outlier.size = 0.3, alpha = 0.8) +
    ggplot2::scale_y_log10() +
    ggplot2::scale_fill_viridis_d(option = "plasma", end = 0.8) +
    ggplot2::labs(x = NULL, y = cmp$channel,
                  title = sprintf("%s vs %s", cmp$treatment, cmp$control),
                  subtitle = if (!is.na(p_val)) {
                    sprintf("%s p = %.3g", cmp$test, p_val)
                  } else NULL) +
    ggplot2::theme_minimal() +
    ggplot2::theme(legend.position = "none")
}

#' Heatmap of channel medians across groups
#'
#' @param experiment A `cr_experiment`.
#' @param channels Character vector of channel names.
#' @param group_by Design column defining rows. Default
#'   `"treatment"`.
#' @param scale One of `"none"`, `"row"`, `"column"`.
#' @return A ggplot2 object.
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
    ggplot2::scale_fill_viridis_c(option = "plasma") +
    ggplot2::labs(x = NULL, y = NULL, fill = "intensity") +
    ggplot2::theme_minimal()
}

#' Time-course line plot
#'
#' @param experiment A `cr_experiment`. Design table must have a
#'   time variable column.
#' @param timepoint_var Name of the time variable column.
#' @param channel Channel to plot.
#' @param group_by Grouping variable (colour).
#' @return A ggplot2 object.
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
    ggplot2::geom_point(size = 2) +
    ggplot2::scale_colour_viridis_d(option = "plasma", end = 0.9) +
    ggplot2::labs(x = timepoint_var, y = channel) +
    ggplot2::theme_minimal()
}
