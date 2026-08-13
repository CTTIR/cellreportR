# Apply a QC gate to an experiment

Removes the cells of every unit the gate excluded, records the step in
the QC log and stores the gate on the experiment so the decision remains
auditable after the data have been trimmed.

## Usage

``` r
cr_apply_gate(experiment, gate, units = NULL, drop_disputed = FALSE)
```

## Arguments

- experiment:

  A `cr_experiment`.

- gate:

  A `cr_qc_gate` from
  [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md).

- units:

  Optional character vector of unit identifiers to remove instead of
  `gate$excluded`, for a reviewed exclusion list.

- drop_disputed:

  Also drop the units whose verdict depends on which control centre is
  used. Default `FALSE`.

## Value

A modified `cr_experiment`. The gate is stored in `metadata$qc_gate`.

## See also

[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md).

Other quality control:
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
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
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
exp2 <- cr_apply_gate(exp, gate)
cr_qc_summary(exp2)
#> # A tibble: 1 × 7
#>   step         parameters cells_before cells_after cells_removed percent_removed
#>   <chr>        <chr>             <int>       <int>         <int>           <dbl>
#> 1 cr_apply_ga… unit=well…         3852        3781            71            1.84
#> # ℹ 1 more variable: timestamp <dttm>
```
