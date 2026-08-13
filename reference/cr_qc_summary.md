# Summarise QC steps applied to an experiment

Summarise QC steps applied to an experiment

## Usage

``` r
cr_qc_summary(experiment)
```

## Arguments

- experiment:

  A `cr_experiment`.

## Value

A tibble with one row per QC step: `step`, `parameters`, `cells_before`,
`cells_after`, `cells_removed`, `percent_removed` and `timestamp`.

## See also

[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md)
for a per-unit rather than per-step view.

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
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
exp <- cr_qc_filter(exp, min_area = 50)
cr_qc_summary(exp)
#> # A tibble: 1 × 7
#>   step         parameters cells_before cells_after cells_removed percent_removed
#>   <chr>        <chr>             <int>       <int>         <int>           <dbl>
#> 1 cr_qc_filter min_area=…         2911        2754           157            5.39
#> # ℹ 1 more variable: timestamp <dttm>
```
