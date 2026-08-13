# Gate cells by intensity

Removes cells whose intensity on a given channel is outside the interval
`[min_intensity, max_intensity]`.

## Usage

``` r
cr_qc_intensity(experiment, channel, min_intensity = NA, max_intensity = NA)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Name of the channel column in `cells`.

- min_intensity, max_intensity:

  Lower and upper bounds. Leave `NA` to skip either.

## Value

A modified `cr_experiment`.

## See also

[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md)
for a gate against each unit's own in-batch control rather than an
absolute bound.

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_qc_intensity(exp, channel = "DAPI", min_intensity = 50)
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2838 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
