# Manually exclude wells or cells

Removes entire wells/slides and/or specific cell IDs (for example
contaminated wells or cells with focus issues).

## Usage

``` r
cr_qc_manual(experiment, well = NULL, cell_ids = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- well:

  Character vector of well / slide identifiers to remove. Default
  `NULL`.

- cell_ids:

  Character vector of cell IDs to remove.

## Value

A modified `cr_experiment`.

## See also

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
cr_qc_manual(exp, well = c("A01", "H12"))
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 1914 across 94 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
