# Changelog

## cellreportR 0.2.0

Rescopes the package from a single-plate assay helper to a full
screening pipeline. The unit of replication is now a first-class notion
throughout: acquisitions are resolved into units, cells are standardized
against the control condition of their own batch, and every effect is
reported at both unit and cell level so the difference between the two
is visible rather than assumed. Existing 0.1.0 functions are unchanged
and continue to work.

### Ingest

- [`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md)
  and
  [`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md)
  read one, or a whole recursive tree of, segmented single-cell exports
  (`.csv` / `.xlsx`), keeping `source_file` and `source_path` on every
  row. Base names repeat across plates, so the path – not the file name
  – identifies an acquisition.
- [`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
  declares a tolerant vendor-header contract: absent names are skipped
  silently rather than raising, and headers that embed unit glyphs are
  matched by prefix. A strict renamer was what previously forced a
  second, near-duplicate ingest path to exist.
- [`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md)
  and
  [`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md)
  recover design facts that live in the directory tree rather than
  inside the files, and
  [`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md)
  states the token grammar a file name must match. An unmatched name is
  an error, never a default: absence of a token is itself meaningful, so
  one typo would otherwise reclassify a treated unit as a control and
  pull it into its own batch’s denominator.
- [`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md)
  and
  [`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md)
  turn parenthetical name markers into typed flags. A half-acquisition
  marker on a file and the same word on a directory mean different
  things and are kept apart; unrecognised markers are captured verbatim
  rather than guessed at.

### Units and balancing

- [`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md),
  [`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md)
  and
  [`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)
  resolve files into analysis units. A second-half acquisition merges
  into its unit, a re-acquisition merges into its plain sibling, and a
  look-alike suffix that denotes a physically different unit does not
  merge. The map reports which units were assembled from more than one
  file.
- [`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md)
  is the evidence test behind that last rule: two files that share
  essentially no object centroids are not the same unit.
- [`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md)
  drops objects below a quantile of the pooled area distribution – a
  data-derived threshold, with the realised absolute value recorded in
  the quality-control log.
- [`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md)
  caps each unit’s cell contribution under an explicit seed, so a unit
  acquired in two halves cannot weight the shared control denominator
  twice. Order matters: exclusion first, then balancing, or the
  threshold is computed on a differently weighted pool.

### Batch standardization

- [`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md),
  [`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md)
  and
  [`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)
  standardize every cell against the control condition of its own batch,
  where a batch is a combination of design columns rather than a single
  variable. Both centres are retained deliberately: the fold change
  keeps the mean denominator while the gate compares medians, because
  the signal is right-skewed and mixing the two makes the gate quietly
  stricter than the rule it states.

### Quality control

- [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md)
  implements the biological gate – a treated unit must exceed the
  control of its own batch – and reports which verdicts depend on the
  centre chosen instead of hiding the choice.
- [`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md)
  re-estimates every affected contrast with and without each excluded
  unit, so “one unit changes the verdict” carries a number. This matters
  most when the excluded unit sits in the reference arm.
- [`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md)
  and
  [`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md)
  apply the gate and record what it removed.

### Effect sizes

- [`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md)
  computes the mean shift, Cohen’s d, Hedges’ g and Cliff’s delta with
  analytic confidence intervals across the whole compound-by-contrast
  grid, at unit or at cell level.
- [`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md)
  contrasts the two levels directly. Cell-level intervals are typically
  several-fold narrower on the same data; that is pseudo-replication,
  not precision, and is why the unit level carries the interpretation.
- Multiplicity adjustments are reported alongside the unadjusted
  p-value, never in place of it: effect sizes with intervals are the
  reportable quantity for an exploratory screen.
- [`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md)
  refits each contrast within block, since units on one plate share a
  preparation, a session and a single control denominator.
- [`cr_unit_variability()`](https://cttir.github.io/cellreportR/reference/cr_unit_variability.md)
  reports unit-to-unit spread and fold range. This is explicitly not
  within-unit technical repeatability, which this class of design cannot
  estimate at all.

### Sample size

- [`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md),
  [`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md)
  and
  [`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md)
  solve the two-sample design twice: once for the observed estimate and
  once for the confidence bound nearer the null, returning `NA` where
  the interval spans the null. The conservative figure is the reportable
  one – powering a screen’s top hit on its own point estimate is
  circular, because that candidate is largest only by virtue of having
  been selected for being largest.

### Visualization

- [`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md),
  [`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md),
  [`cr_plot_sample_size()`](https://cttir.github.io/cellreportR/reference/cr_plot_sample_size.md),
  [`cr_plot_specificity()`](https://cttir.github.io/cellreportR/reference/cr_plot_specificity.md)
  and
  [`cr_plot_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc_gate.md)
  cover the screen figure set, with row order and interval statements
  computed from the data rather than typed.
- [`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md),
  [`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
  [`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md)
  and
  [`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md)
  own the design contract once: a colour-vision-safe palette, no
  red/green pair ever carrying meaning, redundant shape encoding
  wherever hue encodes a grouping, and duplicate-aesthetic guides
  suppressed so a composite emits one legend.
- [`cr_save_plot()`](https://cttir.github.io/cellreportR/reference/cr_save_plot.md)
  writes raster and vector output from one call.

### Tables and generated numbers

- [`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md),
  [`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md),
  [`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md)
  and
  [`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md)
  emit reported counts and supplementary tables from the analysis
  objects. The one hand-maintained table in earlier work was where a
  point estimate from one run got spliced beside an interval from
  another.
- [`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md),
  [`cr_macros_from()`](https://cttir.github.io/cellreportR/reference/cr_macros_from.md),
  [`cr_macro_name()`](https://cttir.github.io/cellreportR/reference/cr_macro_name.md),
  [`cr_format_number()`](https://cttir.github.io/cellreportR/reference/cr_format_number.md)
  and
  [`cr_enumerate()`](https://cttir.github.io/cellreportR/reference/cr_enumerate.md)
  write every quoted number into a single generated include file, so a
  stale number becomes impossible rather than a proofreading miss.
  Enumerations are computed too, since those sentences were hardcoded
  once and were wrong.
- [`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md)
  renders the parameterised report template.

### Infrastructure

- Added `inst/CITATION`, a `.lintr` configuration, and a `lint` workflow
  alongside R-CMD-check, pkgdown and test-coverage.
- The pkgdown reference index is grouped by pipeline stage.
- Coverage reporting is informational and no longer fails continuous
  integration when an optional dependency or a browser is unavailable on
  a runner.

## cellreportR 0.1.0

First release. End-to-end analysis and reporting for cell culture
microscopy assays, picking up where segmentation leaves off.

### Import

- [`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md),
  [`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md),
  [`cr_read_cellprofiler()`](https://cttir.github.io/cellreportR/reference/cr_read_cellprofiler.md),
  [`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md),
  [`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md),
  [`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md)
  and
  [`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md)
  build and check the experiment container.

### Quality control

- [`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
  [`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
  [`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
  [`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md)
  and
  [`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md)
  apply threshold filters and summarise what they removed.

### Normalization

- [`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md),
  [`cr_background_subtract()`](https://cttir.github.io/cellreportR/reference/cr_background_subtract.md)
  and
  [`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md).

### Quantification

- [`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md),
  [`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md)
  and
  [`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md).

### Statistical analysis

- [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md),
  [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md),
  [`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md)
  and
  [`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md)
  provide tests at cell or replicate level with effect sizes.

### Discriminability

- [`cr_logistic()`](https://cttir.github.io/cellreportR/reference/cr_logistic.md),
  [`cr_roc()`](https://cttir.github.io/cellreportR/reference/cr_roc.md),
  [`cr_auc()`](https://cttir.github.io/cellreportR/reference/cr_auc.md)
  and
  [`cr_confusion_matrix()`](https://cttir.github.io/cellreportR/reference/cr_confusion_matrix.md).

### Dose-response

- [`cr_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_dose_response.md)
  (4PL / 3PL / linear) and
  [`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md).

### Visualization

- Thirteen `cr_plot_*` functions covering plate layouts, distributions,
  scatter plots, fold-change and effect-size forest plots, ROC curves,
  dose-response, quality-control dashboards, spatial plots, heatmaps and
  time courses.

### Reporting

- [`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
  [`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md)
  and
  [`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md).

### Interactive front-end

- [`cr_run_app()`](https://cttir.github.io/cellreportR/reference/cr_run_app.md)
  launches a guided multi-tab application covering import, quality
  control, normalization, analysis, dose-response fitting, visualisation
  and report export.

### Helpers

- [`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
  [`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
  [`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md),
  [`cr_well_to_rowcol()`](https://cttir.github.io/cellreportR/reference/cr_well_to_rowcol.md),
  [`cr_rowcol_to_well()`](https://cttir.github.io/cellreportR/reference/cr_rowcol_to_well.md),
  [`cr_channels()`](https://cttir.github.io/cellreportR/reference/cr_channels.md),
  [`cr_n_cells()`](https://cttir.github.io/cellreportR/reference/cr_n_cells.md),
  [`cr_filter_cells()`](https://cttir.github.io/cellreportR/reference/cr_filter_cells.md)
  and
  [`cr_merge_experiments()`](https://cttir.github.io/cellreportR/reference/cr_merge_experiments.md).
