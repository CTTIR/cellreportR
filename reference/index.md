# Package index

## Ingest

Read segmented single-cell exports and recover the experimental design
from the directory tree and the file naming convention.

- [`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md)
  : Read segmented cell data from file
- [`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md)
  : Read experimental design from CSV or Excel
- [`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md)
  : Read one segmented single-cell export
- [`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md)
  : Read a directory tree of segmented single-cell exports
- [`cr_read_cellprofiler()`](https://cttir.github.io/cellreportR/reference/cr_read_cellprofiler.md)
  : Read a CellProfiler object export
- [`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md)
  : Read a QuPath measurement export
- [`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md)
  : Read a segmantR result
- [`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
  [`print(`*`<cr_column_map>`*`)`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
  : Declare a column contract for vendor exports
- [`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md)
  [`print(`*`<cr_path_spec>`*`)`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md)
  : Bundle a directory and file-name specification
- [`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md)
  : Parse design facts out of export paths
- [`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md)
  [`print(`*`<cr_filename_grammar>`*`)`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md)
  : Declare the token grammar of an export file name
- [`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md)
  : Declare how parenthetical file-name markers are interpreted
- [`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md)
  : Extract file-name markers into typed flags

## Experiment object

Build, validate and inspect the container that carries cells, design,
channels, batch keys and provenance.

- [`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md)
  :

  Build a `cr_experiment` object

- [`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md)
  :

  Validate a `cr_experiment`

- [`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md)
  [`print(`*`<cr_dataset>`*`)`](https://cttir.github.io/cellreportR/reference/cr_dataset.md)
  [`summary(`*`<cr_dataset>`*`)`](https://cttir.github.io/cellreportR/reference/cr_dataset.md)
  : Build an ingested data set

- [`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md)
  [`print(`*`<cr_design>`*`)`](https://cttir.github.io/cellreportR/reference/cr_design.md)
  : Build an experimental design object

- [`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md)
  : Construct a batch key

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

## Units and balancing

Resolve acquisitions into the analysis unit of replication, then
equalise the cell contribution of each unit.

- [`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md)
  [`print(`*`<cr_merge_rules>`*`)`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md)
  : Declare how files are merged into analysis units
- [`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md)
  : Assign cells to analysis units
- [`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)
  : Map source files to analysis units
- [`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md)
  : Centroid overlap between two candidate units
- [`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md)
  : Exclude sub-threshold objects with a data-derived cut-off
- [`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md)
  : Balance the number of cells per analysis unit

## Quality control

Threshold filters, the biological gate against each unit’s own control,
and the leverage of what the gate removed.

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
- [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md)
  : Gate analysis units against their own in-batch control
- [`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md)
  : Quantify the leverage of gate exclusions
- [`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md)
  : Apply a QC gate to an experiment
- [`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md)
  : Report every analysis unit with its QC verdict

## Normalization and batch standardization

Rescale each cell against the control condition of its own batch.

- [`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md)
  : Normalize intensity data
- [`cr_background_subtract()`](https://cttir.github.io/cellreportR/reference/cr_background_subtract.md)
  : Subtract background from a channel
- [`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md)
  : Correct batch effects
- [`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md)
  : Per-batch control reference statistics
- [`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)
  : Standardize a channel against the control of each cell's own batch

## Quantification

Collapse cells to units and derive per-unit quantities.

- [`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md)
  : Summarize cell-level data to the analysis unit
- [`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md)
  : Compute fold change relative to a control group
- [`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md)
  : Compute per-unit summary metrics

## Effect sizes and testing

Estimate effects with confidence intervals at unit and at cell level,
and quantify the distance between the two.

- [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)
  : Hypothesis test comparing treatment to control
- [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md)
  : Test all treatments against a control group
- [`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md)
  : Compute effect sizes between two samples
- [`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md)
  : Effect sizes for a whole grid of contrasts
- [`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md)
  : Compare unit-level and cell-level effect estimates
- [`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md)
  : Block-stratified sensitivity fit
- [`cr_unit_variability()`](https://cttir.github.io/cellreportR/reference/cr_unit_variability.md)
  : Between-unit variability within a condition

## Sample size

Solve the design for the observed estimate and for the confidence bound
nearer the null.

- [`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md)
  : Effect size at the confidence bound nearer the null
- [`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md)
  : Sample size for a future study, sized twice
- [`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md)
  : Sample sizes for a whole effect grid
- [`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md)
  : Post-hoc power for a hierarchical cell-based assay

## Discriminability

Logistic models, ROC curves and classification summaries.

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

## Dose-response

Concentration-response curve fitting and potency estimates.

- [`cr_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_dose_response.md)
  : Fit a dose-response curve
- [`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md)
  : Extract IC50 / EC50 from a dose-response fit

## Visualization

Publication figures and the shared plot design contract.

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
- [`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md)
  : Forest plot of effect sizes with confidence intervals
- [`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md)
  : Distribution figure with the unit of replication overlaid
- [`cr_plot_sample_size()`](https://cttir.github.io/cellreportR/reference/cr_plot_sample_size.md)
  : Sample-size comparison plot
- [`cr_plot_specificity()`](https://cttir.github.io/cellreportR/reference/cr_plot_specificity.md)
  : Specificity control plot
- [`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md)
  : QC dashboard
- [`cr_plot_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc_gate.md)
  : Quality-control gate diagnostic plot
- [`cr_plot_roc()`](https://cttir.github.io/cellreportR/reference/cr_plot_roc.md)
  : ROC curve plot
- [`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md)
  : Dose-response plot
- [`cr_plot_spatial()`](https://cttir.github.io/cellreportR/reference/cr_plot_spatial.md)
  : Spatial scatter of cells in a well
- [`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md)
  : Comparison panel (box, fold change, p-value) for a single result
- [`cr_plot_heatmap()`](https://cttir.github.io/cellreportR/reference/cr_plot_heatmap.md)
  : Heatmap of channel medians across groups
- [`cr_plot_timeline()`](https://cttir.github.io/cellreportR/reference/cr_plot_timeline.md)
  : Time-course line plot
- [`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md)
  : Publication theme
- [`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md)
  : Colour-vision-safe palette
- [`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md)
  : Redundant shape encoding
- [`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md)
  : Grouping scales with redundant encoding
- [`cr_save_plot()`](https://cttir.github.io/cellreportR/reference/cr_save_plot.md)
  : Save a figure at publication settings

## Tables and reporting

Emit every reported count and table from the analysis objects rather
than by hand.

- [`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)
  : Collect the tables of an analysis
- [`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md)
  : Tabulate how many units and cells entered the analysis
- [`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md)
  : Tabulate the quality-control record
- [`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md)
  : Export a set of tables to CSV or Excel
- [`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md)
  : Export results to CSV, Excel or RDS
- [`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md)
  : Export plots to PNG, PDF or SVG in batch
- [`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md)
  : Assemble a structured analysis report
- [`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md)
  : Render a report to HTML or PDF

## Generated numbers

Write every quoted number and computed enumeration into a single
generated include file.

- [`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md)
  : Emit named values as a generated include file
- [`cr_macros_from()`](https://cttir.github.io/cellreportR/reference/cr_macros_from.md)
  : Derive generated numbers from a report or a results table
- [`cr_macro_name()`](https://cttir.github.io/cellreportR/reference/cr_macro_name.md)
  : Build a macro-safe name
- [`cr_format_number()`](https://cttir.github.io/cellreportR/reference/cr_format_number.md)
  : Format a number for a generated document
- [`cr_enumerate()`](https://cttir.github.io/cellreportR/reference/cr_enumerate.md)
  : Write a vector out as an English list

## Example data

Synthetic inputs that exercise the whole pipeline.

- [`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)
  : Generate a synthetic multi-compound screen

- [`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md)
  :

  Generate a synthetic `cr_experiment`

- [`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md)
  : Generate an example experimental design

- [`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md)
  : Write a synthetic export tree

- [`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md)
  : Write example files in several on-disk formats

- [`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md)
  : Locate the example files shipped with the package

## Plate utilities

Coordinate helpers for plate layouts.

- [`cr_well_to_rowcol()`](https://cttir.github.io/cellreportR/reference/cr_well_to_rowcol.md)
  : Convert well IDs to row and column indices
- [`cr_rowcol_to_well()`](https://cttir.github.io/cellreportR/reference/cr_rowcol_to_well.md)
  : Convert row and column indices to well IDs

## Interactive front-end

Guided analysis, exploration and report export in the browser.

- [`cr_run_app()`](https://cttir.github.io/cellreportR/reference/cr_run_app.md)
  : Launch the cellreportR Shiny application

## Methods

Print and summarise the objects the pipeline returns.

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

- [`print(`*`<cr_qc_gate>`*`)`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)
  : Print a QC gate

## Package

- [`cellreportR-package`](https://cttir.github.io/cellreportR/reference/cellreportR-package.md)
  [`cellreportR`](https://cttir.github.io/cellreportR/reference/cellreportR-package.md)
  : cellreportR: Cell Culture Microscopy Assay Analysis and Reporting
