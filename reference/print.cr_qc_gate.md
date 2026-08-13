# Print a QC gate

Print a QC gate

## Usage

``` r
# S3 method for class 'cr_qc_gate'
print(x, ...)
```

## Arguments

- x:

  A `cr_qc_gate` from
  [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md).

- ...:

  Ignored.

## Value

`x`, invisibly.

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
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
print(gate)
#> 
#> ── QC gate ─────────────────────────────────────────────────────────────────────
#> Signal marker_1 vs "Untreated" of the same batch
#> Rule: unit median must be greater than the control median
#> • 96 units, 80 gated
#> • 5 fail vs the control median
#> • 16 fail vs the control mean
#> • 5 excluded under the chosen rule
#> ! 11 verdicts depend on which control centre is used.
```
