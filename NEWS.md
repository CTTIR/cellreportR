# cellreportR 0.2.0

Rescopes the package from a single-plate assay helper to a full screening
pipeline. The unit of replication is now a first-class notion throughout:
acquisitions are resolved into units, cells are standardized against the
control condition of their own batch, and every effect is reported at both
unit and cell level so the difference between the two is visible rather
than assumed. Existing 0.1.0 functions are unchanged and continue to work.

## Ingest

* `cr_read_export()` and `cr_read_exports()` read one, or a whole recursive
  tree of, segmented single-cell exports (`.csv` / `.xlsx`), keeping
  `source_file` and `source_path` on every row. Base names repeat across
  plates, so the path -- not the file name -- identifies an acquisition.
* `cr_column_map()` declares a tolerant vendor-header contract: absent
  names are skipped silently rather than raising, and headers that embed
  unit glyphs are matched by prefix. A strict renamer was what previously
  forced a second, near-duplicate ingest path to exist.
* `cr_path_spec()` and `cr_parse_paths()` recover design facts that live in
  the directory tree rather than inside the files, and
  `cr_filename_grammar()` states the token grammar a file name must match.
  An unmatched name is an error, never a default: absence of a token is
  itself meaningful, so one typo would otherwise reclassify a treated unit
  as a control and pull it into its own batch's denominator.
* `cr_marker_rules()` and `cr_extract_markers()` turn parenthetical name
  markers into typed flags. A half-acquisition marker on a file and the
  same word on a directory mean different things and are kept apart;
  unrecognised markers are captured verbatim rather than guessed at.

## Units and balancing

* `cr_merge_rules()`, `cr_assign_units()` and `cr_unit_map()` resolve files
  into analysis units. A second-half acquisition merges into its unit, a
  re-acquisition merges into its plain sibling, and a look-alike suffix
  that denotes a physically different unit does not merge. The map reports
  which units were assembled from more than one file.
* `cr_centroid_overlap()` is the evidence test behind that last rule: two
  files that share essentially no object centroids are not the same unit.
* `cr_exclude_small()` drops objects below a quantile of the pooled area
  distribution -- a data-derived threshold, with the realised absolute
  value recorded in the quality-control log.
* `cr_balance_cells()` caps each unit's cell contribution under an explicit
  seed, so a unit acquired in two halves cannot weight the shared control
  denominator twice. Order matters: exclusion first, then balancing, or the
  threshold is computed on a differently weighted pool.

## Batch standardization

* `cr_batch_key()`, `cr_batch_reference()` and `cr_standardize_batch()`
  standardize every cell against the control condition of its own batch,
  where a batch is a combination of design columns rather than a single
  variable. Both centres are retained deliberately: the fold change keeps
  the mean denominator while the gate compares medians, because the signal
  is right-skewed and mixing the two makes the gate quietly stricter than
  the rule it states.

## Quality control

* `cr_qc_gate()` implements the biological gate -- a treated unit must
  exceed the control of its own batch -- and reports which verdicts depend
  on the centre chosen instead of hiding the choice.
* `cr_qc_gate_impact()` re-estimates every affected contrast with and
  without each excluded unit, so "one unit changes the verdict" carries a
  number. This matters most when the excluded unit sits in the reference
  arm.
* `cr_apply_gate()` and `cr_qc_report()` apply the gate and record what it
  removed.

## Effect sizes

* `cr_effect_grid()` computes the mean shift, Cohen's d, Hedges' g and
  Cliff's delta with analytic confidence intervals across the whole
  compound-by-contrast grid, at unit or at cell level.
* `cr_compare_levels()` contrasts the two levels directly. Cell-level
  intervals are typically several-fold narrower on the same data; that is
  pseudo-replication, not precision, and is why the unit level carries the
  interpretation.
* Multiplicity adjustments are reported alongside the unadjusted p-value,
  never in place of it: effect sizes with intervals are the reportable
  quantity for an exploratory screen.
* `cr_blocked_effect()` refits each contrast within block, since units on
  one plate share a preparation, a session and a single control
  denominator.
* `cr_unit_variability()` reports unit-to-unit spread and fold range. This
  is explicitly not within-unit technical repeatability, which this class
  of design cannot estimate at all.

## Sample size

* `cr_conservative_effect()`, `cr_power()` and `cr_power_grid()` solve the
  two-sample design twice: once for the observed estimate and once for the
  confidence bound nearer the null, returning `NA` where the interval spans
  the null. The conservative figure is the reportable one -- powering a
  screen's top hit on its own point estimate is circular, because that
  candidate is largest only by virtue of having been selected for being
  largest.

## Visualization

* `cr_plot_screen()`, `cr_plot_forest()`, `cr_plot_sample_size()`,
  `cr_plot_specificity()` and `cr_plot_qc_gate()` cover the screen figure
  set, with row order and interval statements computed from the data rather
  than typed.
* `cr_theme()`, `cr_palette()`, `cr_shapes()` and `cr_scale_group()` own the
  design contract once: a colour-vision-safe palette, no red/green pair
  ever carrying meaning, redundant shape encoding wherever hue encodes a
  grouping, and duplicate-aesthetic guides suppressed so a composite emits
  one legend.
* `cr_save_plot()` writes raster and vector output from one call.

## Tables and generated numbers

* `cr_tables()`, `cr_table_disposition()`, `cr_table_qc()` and
  `cr_export_tables()` emit reported counts and supplementary tables from
  the analysis objects. The one hand-maintained table in earlier work was
  where a point estimate from one run got spliced beside an interval from
  another.
* `cr_macros()`, `cr_macros_from()`, `cr_macro_name()`,
  `cr_format_number()` and `cr_enumerate()` write every quoted number into
  a single generated include file, so a stale number becomes impossible
  rather than a proofreading miss. Enumerations are computed too, since
  those sentences were hardcoded once and were wrong.
* `cr_render_report()` renders the parameterised report template.

## Infrastructure

* Added `inst/CITATION`, a `.lintr` configuration, and a `lint` workflow
  alongside R-CMD-check, pkgdown and test-coverage.
* The pkgdown reference index is grouped by pipeline stage.
* Coverage reporting is informational and no longer fails continuous
  integration when an optional dependency or a browser is unavailable on a
  runner.

# cellreportR 0.1.0

First release. End-to-end analysis and reporting for cell culture
microscopy assays, picking up where segmentation leaves off.

## Import

* `cr_read_cells()`, `cr_read_design()`, `cr_read_cellprofiler()`,
  `cr_read_qupath()`, `cr_read_segmantr()`, `cr_build_experiment()` and
  `cr_validate_experiment()` build and check the experiment container.

## Quality control

* `cr_qc_filter()`, `cr_qc_doublets()`, `cr_qc_intensity()`,
  `cr_qc_manual()` and `cr_qc_summary()` apply threshold filters and
  summarise what they removed.

## Normalization

* `cr_normalize()`, `cr_background_subtract()` and `cr_correct_batch()`.

## Quantification

* `cr_summarize_wells()`, `cr_fold_change()` and `cr_compute_metrics()`.

## Statistical analysis

* `cr_test()`, `cr_test_all()`, `cr_effect_size()` and
  `cr_power_analysis()` provide tests at cell or replicate level with
  effect sizes.

## Discriminability

* `cr_logistic()`, `cr_roc()`, `cr_auc()` and `cr_confusion_matrix()`.

## Dose-response

* `cr_dose_response()` (4PL / 3PL / linear) and `cr_ic50()`.

## Visualization

* Thirteen `cr_plot_*` functions covering plate layouts, distributions,
  scatter plots, fold-change and effect-size forest plots, ROC curves,
  dose-response, quality-control dashboards, spatial plots, heatmaps and
  time courses.

## Reporting

* `cr_report()`, `cr_export_results()` and `cr_export_plots()`.

## Interactive front-end

* `cr_run_app()` launches a guided multi-tab application covering import,
  quality control, normalization, analysis, dose-response fitting,
  visualisation and report export.

## Helpers

* `cr_example_experiment()`, `cr_example_design()`, `cr_example_files()`,
  `cr_well_to_rowcol()`, `cr_rowcol_to_well()`, `cr_channels()`,
  `cr_n_cells()`, `cr_filter_cells()` and `cr_merge_experiments()`.
