# Flag or remove doublets

Flags cells whose size or DNA content is far above the population
median, which in microscopy typically indicates segmented doublets. The
cells are removed and recorded in the QC log.

## Usage

``` r
cr_qc_doublets(
  experiment,
  channel = NULL,
  threshold_method = c("area", "channel"),
  k = 2.5
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Name of the channel column used when `threshold_method = "channel"`
  (for example a nuclear stain whose integrated intensity scales with
  DNA content). Ignored for `threshold_method = "area"`.

- threshold_method:

  `"area"` (default) thresholds the segmentation area; `"channel"`
  thresholds `channel`.

- k:

  Multiplicative threshold: cells whose value exceeds `k * median` are
  removed. Default `2.5`.

## Value

A modified `cr_experiment`.

## See also

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_qc_doublets(exp, threshold_method = "area")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2910 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
cr_qc_doublets(exp, channel = "DAPI", threshold_method = "channel")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2893 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
