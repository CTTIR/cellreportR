# Collect the tables of an analysis

Gathers every tabular artifact of an experiment or report into one named
list, ready for
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md).
Empty tables are dropped, so the result reflects what actually exists.

## Usage

``` r
cr_tables(x, results = NULL, which = NULL)
```

## Arguments

- x:

  A `cr_report` or a `cr_experiment`.

- results:

  Optional results to summarize when `x` is a `cr_experiment`. Ignored
  for a `cr_report`, which carries its own.

- which:

  Optional character vector selecting a subset of tables by name.
  Unknown names are an error that lists what is available.

## Value

A named list of tibbles.

## See also

[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md).

Other reporting:
[`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md),
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md),
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md),
[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
tabs <- cr_tables(exp)
names(tabs)
#> [1] "disposition" "design"      "channels"   
tabs$disposition
#> # A tibble: 7 × 4
#>   treatment      n_units n_cells median_cells_per_unit
#>   <chr>            <int>   <int>                 <dbl>
#> 1 CompoundA_high      16     324                  20.5
#> 2 CompoundA_low       16     341                  21  
#> 3 CompoundB           16     350                  23  
#> 4 CompoundC           16     335                  20  
#> 5 PosControl          16     303                  19  
#> 6 Untreated           16     308                  19  
#> 7 (total)             96    1961                  20  
```
