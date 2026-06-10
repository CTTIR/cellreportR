# Package index

## Import & Build

- [`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md)
  : Read segmented cell data from file

- [`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md)
  : Read experimental design from CSV or Excel

- [`cr_read_cellprofiler()`](https://cttir.github.io/cellreportR/reference/cr_read_cellprofiler.md)
  : Read CellProfiler output

- [`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md)
  : Read QuPath measurement export

- [`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md)
  : Read segmantR output

- [`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md)
  :

  Build a `cr_experiment` object

- [`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md)
  :

  Validate a `cr_experiment`

## Quality Control

- [`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md)
  : Filter cells by morphology
- [`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md)
  : Flag or remove doublets
- [`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md)
  : Gate cells by intensity
- [`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md)
  : Manually exclude wells or cells
- [`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md)
  : Summarise QC steps applied to an experiment

## Normalization

- [`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md)
  : Normalize intensity data
- [`cr_background_subtract()`](https://cttir.github.io/cellreportR/reference/cr_background_subtract.md)
  : Subtract background from a channel
- [`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md)
  : Correct batch effects

## Quantification

- [`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md)
  : Summarize cell-level data to the well / slide level
- [`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md)
  : Compute fold change relative to a control group
- [`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md)
  : Compute per-well summary metrics

## Statistical Analysis

- [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)
  : Hypothesis test comparing treatment to control
- [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md)
  : Test all treatments against a control group
- [`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md)
  : Compute effect sizes between two samples
- [`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md)
  : Post-hoc power for a hierarchical cell-based assay

## Discriminability

- [`cr_logistic()`](https://cttir.github.io/cellreportR/reference/cr_logistic.md)
  : Univariate logistic regression of treatment vs. control

- [`cr_roc()`](https://cttir.github.io/cellreportR/reference/cr_roc.md)
  :

  Extract or compute an ROC curve from a `cr_result`

- [`cr_auc()`](https://cttir.github.io/cellreportR/reference/cr_auc.md)
  :

  Compute AUC with confidence interval from a `cr_result`

- [`cr_confusion_matrix()`](https://cttir.github.io/cellreportR/reference/cr_confusion_matrix.md)
  :

  Confusion matrix for a logistic `cr_result`

## Dose-Response

- [`cr_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_dose_response.md)
  : Fit a dose-response curve
- [`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md)
  : Extract IC50 / EC50 from a dose-response fit

## Visualization

- [`cr_plot_plate()`](https://cttir.github.io/cellreportR/reference/cr_plot_plate.md)
  : Plate-layout heatmap
- [`cr_plot_intensity()`](https://cttir.github.io/cellreportR/reference/cr_plot_intensity.md)
  : Intensity distributions by group
- [`cr_plot_scatter()`](https://cttir.github.io/cellreportR/reference/cr_plot_scatter.md)
  : Biaxial scatter plot of two channels
- [`cr_plot_histogram()`](https://cttir.github.io/cellreportR/reference/cr_plot_histogram.md)
  : Histogram of channel intensity
- [`cr_plot_foldchange()`](https://cttir.github.io/cellreportR/reference/cr_plot_foldchange.md)
  : Fold-change forest plot
- [`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md)
  : Forest plot of effect sizes
- [`cr_plot_roc()`](https://cttir.github.io/cellreportR/reference/cr_plot_roc.md)
  : ROC curve plot
- [`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md)
  : Dose-response plot
- [`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md)
  : QC dashboard
- [`cr_plot_spatial()`](https://cttir.github.io/cellreportR/reference/cr_plot_spatial.md)
  : Spatial scatter of cells in a well
- [`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md)
  : Comparison panel (box, fold change, p-value) for a single result
- [`cr_plot_heatmap()`](https://cttir.github.io/cellreportR/reference/cr_plot_heatmap.md)
  : Heatmap of channel medians across groups
- [`cr_plot_timeline()`](https://cttir.github.io/cellreportR/reference/cr_plot_timeline.md)
  : Time-course line plot

## Reporting

- [`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md)
  : Generate a structured analysis report
- [`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md)
  : Export results to CSV, Excel or RDS
- [`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md)
  : Export plots to PNG, PDF or SVG in batch

## Shiny App

- [`cr_run_app()`](https://cttir.github.io/cellreportR/reference/cr_run_app.md)
  : Launch the cellreportR Shiny application

## Example Data

- [`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md)
  :

  Generate a synthetic `cr_experiment`

- [`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md)
  : Generate an example experimental design

- [`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md)
  : Write example files in multiple formats to a directory

## Utilities

- [`cr_well_to_rowcol()`](https://cttir.github.io/cellreportR/reference/cr_well_to_rowcol.md)
  : Convert well IDs to row and column indices

- [`cr_rowcol_to_well()`](https://cttir.github.io/cellreportR/reference/cr_rowcol_to_well.md)
  : Convert row and column indices to well IDs

- [`cr_channels()`](https://cttir.github.io/cellreportR/reference/cr_channels.md)
  :

  List channels in a `cr_experiment`

- [`cr_n_cells()`](https://cttir.github.io/cellreportR/reference/cr_n_cells.md)
  :

  Count cells in a `cr_experiment`

- [`cr_filter_cells()`](https://cttir.github.io/cellreportR/reference/cr_filter_cells.md)
  :

  Filter cells in a `cr_experiment`

- [`cr_merge_experiments()`](https://cttir.github.io/cellreportR/reference/cr_merge_experiments.md)
  : Merge multiple experiments

## S3 methods

- [`print(`*`<cr_experiment>`*`)`](https://cttir.github.io/cellreportR/reference/print.cr_experiment.md)
  :

  Print method for `cr_experiment`

- [`summary(`*`<cr_experiment>`*`)`](https://cttir.github.io/cellreportR/reference/summary.cr_experiment.md)
  :

  Summary method for `cr_experiment`

- [`print(`*`<cr_result>`*`)`](https://cttir.github.io/cellreportR/reference/print.cr_result.md)
  :

  Print method for `cr_result`

- [`summary(`*`<cr_result>`*`)`](https://cttir.github.io/cellreportR/reference/summary.cr_result.md)
  :

  Summary method for `cr_result`

- [`print(`*`<cr_report>`*`)`](https://cttir.github.io/cellreportR/reference/print.cr_report.md)
  :

  Print method for `cr_report`

- [`summary(`*`<cr_report>`*`)`](https://cttir.github.io/cellreportR/reference/summary.cr_report.md)
  :

  Summary method for `cr_report`
