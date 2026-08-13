# Filter cells by morphology

Removes debris and artifacts by thresholding morphological measurements.
Any parameter left at `NA` is not applied.

## Usage

``` r
cr_qc_filter(
  experiment,
  min_area = NA,
  max_area = NA,
  min_circularity = NA,
  max_circularity = NA
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- min_area, max_area:

  Numeric area thresholds. Cells outside the inclusive interval are
  removed.

- min_circularity, max_circularity:

  Circularity thresholds (range 0-1).

## Value

A modified `cr_experiment` with fewer cells and a QC log entry.

## See also

[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md)
for a data-derived (quantile) area threshold, and
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md)
for the log.

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 50)
exp2 <- cr_qc_filter(exp, min_area = 100, max_area = 2000)
cr_n_cells(exp2)
#> [1] 4516
```
