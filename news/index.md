# Changelog

## cellreportR 0.1.0

### Initial release

cellreportR provides an end-to-end analysis and reporting pipeline for
cell-culture microscopy assays, picking up where cell segmentation
(e.g. `segmantR`, CellProfiler, QuPath) leaves off.

#### Core features

- **Import**:
  [`cr_read_cells()`](https://r-heller.github.io/cellreportR/reference/cr_read_cells.md),
  [`cr_read_design()`](https://r-heller.github.io/cellreportR/reference/cr_read_design.md),
  [`cr_read_cellprofiler()`](https://r-heller.github.io/cellreportR/reference/cr_read_cellprofiler.md),
  [`cr_read_qupath()`](https://r-heller.github.io/cellreportR/reference/cr_read_qupath.md),
  [`cr_read_segmantr()`](https://r-heller.github.io/cellreportR/reference/cr_read_segmantr.md),
  [`cr_build_experiment()`](https://r-heller.github.io/cellreportR/reference/cr_build_experiment.md),
  [`cr_validate_experiment()`](https://r-heller.github.io/cellreportR/reference/cr_validate_experiment.md).
- **Quality control**:
  [`cr_qc_filter()`](https://r-heller.github.io/cellreportR/reference/cr_qc_filter.md),
  [`cr_qc_doublets()`](https://r-heller.github.io/cellreportR/reference/cr_qc_doublets.md),
  [`cr_qc_intensity()`](https://r-heller.github.io/cellreportR/reference/cr_qc_intensity.md),
  [`cr_qc_manual()`](https://r-heller.github.io/cellreportR/reference/cr_qc_manual.md),
  [`cr_qc_summary()`](https://r-heller.github.io/cellreportR/reference/cr_qc_summary.md).
- **Normalization**:
  [`cr_normalize()`](https://r-heller.github.io/cellreportR/reference/cr_normalize.md),
  [`cr_background_subtract()`](https://r-heller.github.io/cellreportR/reference/cr_background_subtract.md),
  [`cr_correct_batch()`](https://r-heller.github.io/cellreportR/reference/cr_correct_batch.md).
- **Quantification**:
  [`cr_summarize_wells()`](https://r-heller.github.io/cellreportR/reference/cr_summarize_wells.md),
  [`cr_fold_change()`](https://r-heller.github.io/cellreportR/reference/cr_fold_change.md),
  [`cr_compute_metrics()`](https://r-heller.github.io/cellreportR/reference/cr_compute_metrics.md).
- **Statistical testing**:
  [`cr_test()`](https://r-heller.github.io/cellreportR/reference/cr_test.md),
  [`cr_test_all()`](https://r-heller.github.io/cellreportR/reference/cr_test_all.md),
  [`cr_effect_size()`](https://r-heller.github.io/cellreportR/reference/cr_effect_size.md),
  [`cr_power_analysis()`](https://r-heller.github.io/cellreportR/reference/cr_power_analysis.md)
  — hierarchical tests at cell or replicate level with effect sizes.
- **Discriminability**:
  [`cr_logistic()`](https://r-heller.github.io/cellreportR/reference/cr_logistic.md),
  [`cr_roc()`](https://r-heller.github.io/cellreportR/reference/cr_roc.md),
  [`cr_auc()`](https://r-heller.github.io/cellreportR/reference/cr_auc.md),
  [`cr_confusion_matrix()`](https://r-heller.github.io/cellreportR/reference/cr_confusion_matrix.md).
- **Dose-response**:
  [`cr_dose_response()`](https://r-heller.github.io/cellreportR/reference/cr_dose_response.md)
  (4PL / 3PL / linear),
  [`cr_ic50()`](https://r-heller.github.io/cellreportR/reference/cr_ic50.md).
- **Visualization**: thirteen `cr_plot_*` functions covering plate
  layouts, distributions, scatter plots, fold-change and effect-size
  forest plots, ROC curves, dose-response, QC dashboards, spatial plots,
  heatmaps and time courses.
- **Reporting**:
  [`cr_report()`](https://r-heller.github.io/cellreportR/reference/cr_report.md),
  [`cr_export_results()`](https://r-heller.github.io/cellreportR/reference/cr_export_results.md),
  [`cr_export_plots()`](https://r-heller.github.io/cellreportR/reference/cr_export_plots.md).
- **Interactive**:
  [`cr_run_app()`](https://r-heller.github.io/cellreportR/reference/cr_run_app.md)
  launches a seven-tab Shiny application.
- **Example data**:
  [`cr_example_experiment()`](https://r-heller.github.io/cellreportR/reference/cr_example_experiment.md),
  [`cr_example_design()`](https://r-heller.github.io/cellreportR/reference/cr_example_design.md),
  [`cr_example_files()`](https://r-heller.github.io/cellreportR/reference/cr_example_files.md).
- **Utilities**:
  [`cr_well_to_rowcol()`](https://r-heller.github.io/cellreportR/reference/cr_well_to_rowcol.md),
  [`cr_rowcol_to_well()`](https://r-heller.github.io/cellreportR/reference/cr_rowcol_to_well.md),
  [`cr_channels()`](https://r-heller.github.io/cellreportR/reference/cr_channels.md),
  [`cr_n_cells()`](https://r-heller.github.io/cellreportR/reference/cr_n_cells.md),
  [`cr_filter_cells()`](https://r-heller.github.io/cellreportR/reference/cr_filter_cells.md),
  [`cr_merge_experiments()`](https://r-heller.github.io/cellreportR/reference/cr_merge_experiments.md).
