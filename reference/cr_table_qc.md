# Tabulate the quality-control record

Normalizes the several shapes a QC record can take — an experiment's QC
log, a gate object, or a plain data frame — into one tibble suitable for
a supplement.

## Usage

``` r
cr_table_qc(x)
```

## Arguments

- x:

  A `cr_experiment`, a `cr_report`, a data frame, or a list holding data
  frames (for example a gate object with a `units` element).

## Value

A tibble. For a list of several data frames the elements are stacked and
identified by a `component` column.

## See also

[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md).

Other reporting:
[`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md),
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md),
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md),
[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
exp <- cr_filter_cells(exp, area > 100)
cr_table_qc(exp)
#> # A tibble: 1 × 7
#>   step         parameters cells_before cells_after cells_removed percent_removed
#>   <chr>        <chr>             <int>       <int>         <int>           <dbl>
#> 1 cr_filter_c… list(area…         1961        1828           133            6.78
#> # ℹ 1 more variable: timestamp <dttm>
```
