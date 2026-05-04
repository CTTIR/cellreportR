# cellreportR 0.1.0

## Initial release

cellreportR provides an end-to-end analysis and reporting pipeline
for cell-culture microscopy assays, picking up where cell
segmentation (e.g. `segmantR`, CellProfiler, QuPath) leaves off.

### Core features

* **Import**: `cr_read_cells()`, `cr_read_design()`,
  `cr_read_cellprofiler()`, `cr_read_qupath()`,
  `cr_read_segmantr()`, `cr_build_experiment()`,
  `cr_validate_experiment()`.
* **Quality control**: `cr_qc_filter()`, `cr_qc_doublets()`,
  `cr_qc_intensity()`, `cr_qc_manual()`, `cr_qc_summary()`.
* **Normalization**: `cr_normalize()`, `cr_background_subtract()`,
  `cr_correct_batch()`.
* **Quantification**: `cr_summarize_wells()`, `cr_fold_change()`,
  `cr_compute_metrics()`.
* **Statistical testing**: `cr_test()`, `cr_test_all()`,
  `cr_effect_size()`, `cr_power_analysis()` — hierarchical tests at
  cell or replicate level with effect sizes.
* **Discriminability**: `cr_logistic()`, `cr_roc()`, `cr_auc()`,
  `cr_confusion_matrix()`.
* **Dose-response**: `cr_dose_response()` (4PL / 3PL / linear),
  `cr_ic50()`.
* **Visualization**: thirteen `cr_plot_*` functions covering plate
  layouts, distributions, scatter plots, fold-change and effect-size
  forest plots, ROC curves, dose-response, QC dashboards, spatial
  plots, heatmaps and time courses.
* **Reporting**: `cr_report()`, `cr_export_results()`,
  `cr_export_plots()`.
* **Interactive**: `cr_run_app()` launches a seven-tab Shiny
  application.
* **Example data**: `cr_example_experiment()`,
  `cr_example_design()`, `cr_example_files()`.
* **Utilities**: `cr_well_to_rowcol()`, `cr_rowcol_to_well()`,
  `cr_channels()`, `cr_n_cells()`, `cr_filter_cells()`,
  `cr_merge_experiments()`.
