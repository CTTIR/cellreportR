# Tabulate how many units and cells entered the analysis

Counts of analysis units and cells, overall and per arm. The reported
counts of an assay are themselves an analysis output: once they are
generated from the object that was analyzed, a count in the write-up
cannot drift away from the data it describes.

## Usage

``` r
cr_table_disposition(experiment, by = NULL, unit = NULL, total = TRUE)
```

## Arguments

- experiment:

  A `cr_experiment`.

- by:

  Character vector of grouping columns from `design` or `cells`.
  Defaults to `"treatment"` when that column exists, and to no grouping
  otherwise.

- unit:

  Optional name of the column that identifies the analysis unit. May be
  a column of `cells` or of `design`. If `NULL` (default) the
  experiment's `unit_var` slot is used when present, and the spatial
  unit otherwise.

- total:

  Whether to append a row holding the overall counts. The grouping
  columns of that row carry the label `"(total)"`.

## Value

A tibble with the grouping columns (as character), `n_units`, `n_cells`
and `median_cells_per_unit`.

## See also

[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md),
[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md).

Other quantification:
[`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md),
[`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md),
[`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
cr_table_disposition(exp)
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
cr_table_disposition(exp, by = "group")
#> # A tibble: 5 × 4
#>   group       n_units n_cells median_cells_per_unit
#>   <chr>         <int>   <int>                 <dbl>
#> 1 combination      32     685                  21.5
#> 2 control          16     308                  19  
#> 3 positive         16     303                  19  
#> 4 treated          32     665                  20.5
#> 5 (total)          96    1961                  20  
```
