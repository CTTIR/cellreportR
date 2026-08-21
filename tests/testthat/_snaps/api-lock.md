# exported API surface is unchanged

    Code
      cat(sigs, sep = "\n")
    Output
      cr_apply_gate(experiment, gate, units = NULL, drop_disputed = FALSE)
      cr_assign_units(x, key_vars, replicate_var = "replicate", rules = cr_merge_rules(), id_col = "well_id", sep = "|", call = rlang::caller_env())
      cr_auc(result, ci_method = c("delong", "bootstrap"), n_boot = 1000)
      cr_background_subtract(experiment, channel, method = c("percentile", "modal", "empty_wells"), q = 0.05, empty_wells = NULL)
      cr_balance_cells(experiment, unit = NULL, n_max = NULL, n = NULL, seed = NULL)
      cr_batch_key(x, batch_vars, sep = " | ", na_label = "<NA>")
      cr_batch_reference(experiment, channel, control_level, batch_vars, control_var = "treatment", sd_floor = 1e-08)
      cr_blocked_effect(data, value, group_var, reference_level, comparison_levels = NULL, block_var, by = NULL, unit = NULL, conf_level = 0.95, min_blocks = 2)
      cr_build_experiment(cells, design = NULL, channels = NULL, plate_info = list(), metadata = list(), unit_var = NULL, batch_vars = NULL, provenance = NULL, set_aside = NULL, call = rlang::caller_env())
      cr_centroid_overlap(x, unit_a, unit_b, coords = c("x", "y"), tol = 1, id_col = "well_id", call = rlang::caller_env())
      cr_channels(experiment)
      cr_classify_result(value, negative_upper, positive_lower, labels = c(negative = "NEGATIVE", indeterminate = "INDETERMINATE", positive = "POSITIVE"))
      cr_column_map(exact = NULL, prefix = NULL, keep = NULL)
      cr_compare_levels(unit_effects, cell_effects, by = NULL, estimate = "cohens_d")
      cr_compute_metrics(experiment, channel, positive_threshold = NULL, unit = NULL)
      cr_confusion_matrix(result, threshold = 0.5)
      cr_conservative_effect(ci_low, ci_high)
      cr_correct_batch(experiment, batch_var, channel, method = c("median_center", "combat"))
      cr_dataset(cells, design = NULL, unit_var = NULL, provenance = NULL, file_col = "source_path", metadata = list(), call = rlang::caller_env())
      cr_design(data, unit = NULL, treatment = "treatment", control_level = NULL, batch_vars = NULL, levels = list(), keep = NULL, call = rlang::caller_env())
      cr_dose_response(experiment, channel, treatment = NULL, model = c("4pl", "3pl", "linear"), log_dose = TRUE)
      cr_effect_grid(data, value, group_var, reference_level, comparison_levels = NULL, by = NULL, unit = NULL, methods = c("cohens_d", "hedges_g", "cliffs_delta"), conf_level = 0.95, min_n = 3, test = c("t", "wilcox", "none"), p_adjust = c("bonferroni", "BH"), level = NULL)
      cr_effect_size(x, y, method = c("cohens_d", "hedges_g", "cliffs_delta", "rank_biserial", "glass_delta"), ci = 0.95, ci_method = c("analytic", "bootstrap"), n_boot = 200, seed = NULL)
      cr_enumerate(x, conjunction = "and", empty = "none", oxford = FALSE)
      cr_example_design(plate_format = 96, n_wells_per_replicate = 4)
      cr_example_experiment(seed = 42, n_cells_per_well = 150, n_wells_per_replicate = 4)
      cr_example_exports(dir = tempdir(), seed = 42, n_cells = 20, format = c("csv", "xlsx"))
      cr_example_files(dir = tempdir(), seed = 42)
      cr_example_path(file = NULL)
      cr_example_screen(seed = 42, n_compounds = 10, n_cells_per_well = 40, n_units_per_arm = 3, n_experiments = 2)
      cr_exclude_small(experiment, var = "area", probs = 0.1, threshold = NULL, scope = c("pooled", "batch"), batch_vars = NULL)
      cr_export_plots(plots, path, format = c("png", "pdf", "svg"), width = 6, height = 4, dpi = 300, ...)
      cr_export_report_audit(report, path, output_file = NULL)
      cr_export_report_spec(spec, path, pretty = TRUE)
      cr_export_results(results, path, format = NULL)
      cr_export_tables(tables, path, format = c("csv", "xlsx"), one_file = TRUE)
      cr_extract_markers(x, name_col = "source_file", container_col = NULL, rules = cr_marker_rules(), stem_col = NULL, strip_ext = TRUE, call = rlang::caller_env())
      cr_figure_caption(title = NULL, description = NULL, n = NULL, unit = NULL, qc_note = NULL)
      cr_figure_size(size = c("single", "double", "report", "square"), units = c("mm", "in"))
      cr_filename_grammar(tokens = list(), defaults = list(), core_patterns = character(), typo_fixes = character(), prefix_strip = character(), replicate = "[0-9]+(?:\\.[0-9]+)?", sep = "_", normalise_space = TRUE)
      cr_filter_cells(experiment, ...)
      cr_finalize_result(classification, qc_status, failed_statuses = "FAIL", invalid_label = "INVALID", invalidate = TRUE)
      cr_fold_change(experiment, channel, control_group, method = c("median", "mean"), eps = 0, unit = NULL)
      cr_format_interval(estimate, lower, upper, digits = 2)
      cr_format_number(x, digits = 3, signed = FALSE, big_mark = ",", na = "--")
      cr_format_percent(x, digits = 1)
      cr_format_pvalue(x, digits = 3)
      cr_ic50(fit, level = 0.95)
      cr_import_report_spec(path, validate = TRUE)
      cr_interpretation_lookup(classification, dictionary, default = NA_character_)
      cr_lab_report(experiment = NULL, spec = cr_report_spec(), qc = NULL, result_graphic = FALSE, include_audit_appendix = NULL, strict = TRUE, style = NULL, profile = NULL)
      cr_linetype_scale(values = NULL, ...)
      cr_linetypes(n = NULL, names = NULL)
      cr_logistic(experiment, channel, treatment, control, level = c("cell", "replicate"))
      cr_macro_name(x, prefix = NULL)
      cr_macros(values, file, format = c("tex", "json", "yaml"), prefix = NULL, header = NULL, digits = 3, big_mark = ",", na = "--")
      cr_macros_from(x, file, label_cols = NULL, ci = c("ci_low", "ci_high"), ...)
      cr_marker_rules(merge_unit = NULL, partial_plate = NULL, omitted_reagent = NULL, reacquisition = NULL, lot = NULL, capture_unknown = TRUE, ignore_case = TRUE)
      cr_merge_experiments(...)
      cr_merge_rules(merge_suffix = "\\.1$", merge_marker = "merge_unit", keep_separate = "\\.2$", reacquisition = "reacquisition", merge_reacquisition = TRUE, separate_suffix = "re")
      cr_n_cells(experiment, by = NULL)
      cr_normalize(experiment, channel, method = c("background", "control", "zscore", "robust_zscore", "quantile"), control_group = NULL, ...)
      cr_palette(n = NULL, type = c("qualitative", "sequential", "diverging"), names = NULL, mode = c("colour", "grayscale"))
      cr_parse_paths(paths, root = NULL, levels = NULL, grammar = NULL, markers = NULL, strict = TRUE, spec = NULL, call = rlang::caller_env())
      cr_path_spec(levels = NULL, grammar = NULL, markers = NULL, strict = TRUE)
      cr_plot_comparison(result, experiment)
      cr_plot_dose_response(fit)
      cr_plot_effect_sizes(results, method = "cohens_d", ...)
      cr_plot_estimates(data, estimate = "estimate", lower = "conf_low", upper = "conf_high", label = "group", group = NULL, reference = 0, order_by = c("design", "estimate", "name"), colour_mode = c("colour", "grayscale"), style = NULL)
      cr_plot_foldchange(result)
      cr_plot_forest(effects, estimate = "estimate", ci_low = "ci_low", ci_high = "ci_high", label = NULL, facet_by = NULL, colour_by = NULL, method = "cohens_d", reference = 0, order_by_estimate = TRUE, descending = FALSE, title = NULL, subtitle = NULL, x_lab = NULL, y_lab = NA)
      cr_plot_heatmap(experiment, channels, group_by = "treatment", scale = c("none", "row", "column"))
      cr_plot_histogram(experiment, channel, group_by = "treatment", facet_by = NULL, log_x = TRUE)
      cr_plot_intensity(experiment, channel, group_by = "treatment", geom = c("violin", "boxplot", "both"), log_y = TRUE)
      cr_plot_plate(experiment, channel, metric = c("median", "mean", "cv", "n_cells"))
      cr_plot_qc(experiment, channel = NULL)
      cr_plot_qc_gate(gate, statistic = NULL, reference = NULL, fails_median = NULL, fails_mean = NULL, direction = c("greater", "less"), log_scale = TRUE, label = NULL, title = NULL, subtitle = NULL, x_lab = NULL, y_lab = NULL)
      cr_plot_qc_summary(qc, mode = c("colour", "grayscale"))
      cr_plot_result_position(value, thresholds, labels = NULL, xlim = NULL, unit = NULL, classification = NULL, show_value = TRUE, mode = c("colour", "grayscale"), style = NULL)
      cr_plot_roc(result)
      cr_plot_sample_size(sizes, label = NULL, observed = "n_observed", conservative = "n_conservative", available = NULL, colour_by = NULL, log_y = TRUE, title = NULL, subtitle = NULL, caption = NULL, x_lab = NA, y_lab = NULL)
      cr_plot_scatter(experiment, channel_x, channel_y, color_by = "treatment", log_x = TRUE, log_y = TRUE)
      cr_plot_screen(cells, value = "log2_fc", group_var = "treatment", units = NULL, unit_value = NULL, facet_by = NULL, colour_by = NULL, reference = 0, seed = NULL, title = NULL, subtitle = NULL, x_lab = NA, y_lab = NULL)
      cr_plot_spatial(experiment, channel, well = NULL)
      cr_plot_specificity(spec, arm = "arm", value = NULL, arm_levels = NULL, colour_by = NULL, log_y = TRUE, ratio_arms = NULL, title = NULL, subtitle = NULL, x_lab = NA, y_lab = NULL)
      cr_plot_style(mode = c("colour", "grayscale"), variant = c("publication", "report"), base_size = 9, base_family = "sans", palette = NULL, shapes = NULL, linetypes = NULL, legend_position = "bottom")
      cr_plot_timeline(experiment, timepoint_var, channel, group_by = "treatment")
      cr_power(effect_size = NULL, ci_low = NULL, ci_high = NULL, power = 0.8, sig_level = 0.05, type = c("two.sample", "one.sample", "paired"), alternative = c("two.sided", "one.sided"))
      cr_power_analysis(effect_size, n_replicates, n_cells_per_rep, alpha = 0.05, test = "t_test", n_sim = 500, seed = NULL)
      cr_power_grid(effects, estimate = "cohens_d", ci_low = NULL, ci_high = NULL, available = NULL, power = 0.8, sig_level = 0.05, type = c("two.sample", "one.sample", "paired"), alternative = c("two.sided", "one.sided"))
      cr_print_report_spec(x, ...)
      cr_qc_doublets(experiment, channel = NULL, threshold_method = c("area", "channel"), k = 2.5)
      cr_qc_filter(experiment, min_area = NA, max_area = NA, min_circularity = NA, max_circularity = NA)
      cr_qc_gate(experiment, channel, control_level, batch_vars = NULL, unit = NULL, control_var = "treatment", statistic = c("median", "mean"), reference = c("median", "mean"), direction = c("greater", "less"), gate_controls = FALSE, min_cells = 1L)
      cr_qc_gate_impact(experiment, gate, value = "log2_fc", group_var, reference_level, comparison_levels = NULL, by = NULL, unit = NULL, min_units = 3, affected_only = TRUE)
      cr_qc_intensity(experiment, channel, min_intensity = NA, max_intensity = NA)
      cr_qc_manual(experiment, well = NULL, cell_ids = NULL)
      cr_qc_report(experiment, gate = NULL, unit = NULL, vars = NULL)
      cr_qc_summary(experiment)
      cr_read_cellprofiler(path)
      cr_read_cells(path, format = NULL)
      cr_read_design(path)
      cr_read_export(path, column_map = NULL, drop_empty_rows = TRUE, col_types = NULL, sheet = 1L, call = rlang::caller_env())
      cr_read_exports(root, pattern = "\\.(csv|tsv|xls|xlsx)$", column_map = NULL, spec = NULL, parser = NULL, recursive = TRUE, drop_empty_rows = TRUE, col_types = NULL, progress = TRUE, call = rlang::caller_env())
      cr_read_qupath(path)
      cr_read_segmantr(path)
      cr_render_lab_report(report, output_file, template = NULL, quiet = TRUE, audit_file = NULL, overwrite = FALSE, keep_tex = FALSE)
      cr_render_report(report, output_dir = tempdir(), format = c("html", "pdf", "docx"), template = NULL, title = NULL, author = NULL, quiet = TRUE)
      cr_report(experiment, results = NULL, qc = NULL, effects = NULL, sizes = NULL, tables = NULL, plots = NULL, title = "cellreportR analysis report", author = "", metadata = list(), render = NULL, template = NULL, output_dir = NULL, format = c("html", "pdf", "docx"))
      cr_report_data(report)
      cr_report_display_data(report)
      cr_report_hash(x, algorithm = "sha256")
      cr_report_profile(laboratory = list(), style = cr_report_style(), labels = character(), footer_statement = NULL, default_title = NULL, required_fields = character())
      cr_report_provenance(experiment = NULL, report_spec, output_file = NULL, analysis_metadata = list())
      cr_report_qc(criterion = character(), observed = character(), acceptance = character(), status = character(), source = character())
      cr_report_qc_from_log(x)
      cr_report_spec(report = list(), laboratory = list(), subject = list(), specimen = list(), examination = list(), result = list(), interpretation = list(), limitations = character(), authorization = list(), custom_fields = list(), custom_sections = list(), required_fields = character(), field_labels = character(), schema_version = "1.0")
      cr_report_style(paper = "A4", mode = c("colour", "grayscale"), density = c("standard", "compact"), locale = c("en", "de"), logo = NULL, primary_colour = "#315A70", secondary_colour = "#65747C", date_format = NULL, date_time_format = NULL, labels = character(), footer_text = NULL, include_audit_appendix = FALSE, show_signature_lines = FALSE, draft_watermark = FALSE)
      cr_roc(result)
      cr_rowcol_to_well(row, col, pad = 2)
      cr_run_app(experiment = NULL, report_spec = NULL, report_profile = NULL, max_upload_mb = 512, launch_browser = interactive(), ...)
      cr_save_figure(plot, filename, size = c("single", "double", "report", "square"), dpi = 600, background = "white", metadata = NULL)
      cr_save_plot(plot, path, width = 12, height = NULL, dpi = 600, formats = c("png", "pdf"), units = "in", bg = "white", quiet = FALSE)
      cr_scale_colour(values = NULL, mode = c("colour", "grayscale"), ...)
      cr_scale_diverging(midpoint = 0, aesthetics = c("colour", "fill"), mode = c("colour", "grayscale"), ...)
      cr_scale_fill(values = NULL, mode = c("colour", "grayscale"), ...)
      cr_scale_group(aesthetics = c("colour", "fill", "shape"), name = NULL, guide_for = NULL, drop = TRUE, mode = c("colour", "grayscale"))
      cr_shape_scale(values = NULL, ...)
      cr_shapes(n = NULL, names = NULL)
      cr_standardize_batch(experiment, channel, control_level, batch_vars, control_var = "treatment", method = c("log2_fc", "zscore", "raw"), eps = 1, sd_floor = 1e-08, value_to = "value_std", on_missing_control = c("error", "warn", "drop"))
      cr_summarize_wells(experiment, channel, fun = stats::median, unit = NULL)
      cr_table_disposition(experiment, by = NULL, unit = NULL, total = TRUE)
      cr_table_qc(x)
      cr_tables(x, results = NULL, which = NULL)
      cr_test(experiment, channel, treatment, control, test = c("mann_whitney", "t_test", "welch", "wilcoxon_signed"), level = c("cell", "replicate", "both"))
      cr_test_all(experiment, channel, control_group, tests = "mann_whitney", p_adjust = "BH", level = c("replicate", "cell", "both"))
      cr_theme(base_size = 11, base_family = "sans", grid = TRUE, legend_position = "bottom", variant = c("publication", "report"), mode = c("colour", "grayscale"))
      cr_unit_map(x, id_col = "well_id", file_col = "source_path", call = rlang::caller_env())
      cr_unit_variability(data, value, by, unit = NULL, min_units = 2, log_base = 2)
      cr_validate_experiment(x, call = rlang::caller_env())
      cr_validate_report_qc(qc)
      cr_validate_report_spec(spec, strict = TRUE, return_issues = FALSE)
      cr_well_to_rowcol(well)

# registered S3 methods are unchanged

    Code
      cat(methods, sep = "\n")
    Output
      print.cr_column_map
      print.cr_dataset
      print.cr_design
      print.cr_experiment
      print.cr_filename_grammar
      print.cr_lab_report
      print.cr_merge_rules
      print.cr_path_spec
      print.cr_qc_gate
      print.cr_report
      print.cr_report_spec
      print.cr_report_style
      print.cr_result
      summary.cr_dataset
      summary.cr_experiment
      summary.cr_report
      summary.cr_result

# declared dependencies are unchanged

    Code
      cat(out, sep = "\n")
    Output
      Depends:
        R (>= 4.1.0)
      Imports:
        cli
        digest
        dplyr
        ggplot2
        jsonlite
        pROC
        readr
        readxl
        rlang
        scales
        shiny
        stats
        tibble
        tidyr
        tools
        utils

