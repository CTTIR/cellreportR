# Summarize cell-level data to the analysis unit

Aggregates the per-cell values of one channel to a single number per
analysis unit. By default the analysis unit is the spatial unit of the
experiment (`well` or `slide`), which is the unit of replication for
most plate-based assays. Pass `unit` to aggregate to a merged analysis
unit instead — for example when one physical unit was acquired as
several files and the acquisitions were assigned a common identifier.

## Usage

``` r
cr_summarize_wells(experiment, channel, fun = stats::median, unit = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name (a column of `experiment$cells`).

- fun:

  Aggregation function. Default
  [`stats::median`](https://rdrr.io/r/stats/median.html). The function
  is called with `na.rm = TRUE` when it accepts that argument (directly
  or through `...`), and with the values only otherwise. It must return
  a single number.

- unit:

  Optional name of the column that identifies the analysis unit. May be
  a column of `cells` or of `design`. If `NULL` (default) the
  experiment's `unit_var` slot is used when present, and the spatial
  unit otherwise.

## Value

A tibble with one row per analysis unit containing the unit identifier,
`n_cells`, the aggregated `value`, and the design columns. Design
columns that are not constant within a unit are returned as `NA`.

## See also

[`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md)
for a richer per-unit summary and
[`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md)
for unit and cell counts per arm.

Other quantification:
[`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md),
[`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md),
[`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_summarize_wells(exp, channel = "marker_1")
#> # A tibble: 96 × 11
#>    well  n_cells value treatment   dose dose_unit group replicate plate interval
#>    <chr>   <int> <dbl> <chr>      <dbl> <chr>     <chr>     <int> <chr> <chr>   
#>  1 A01        26 2525. Untreated      0 uM        cont…         1 Plat… 15min   
#>  2 A02        16  458. Untreated      0 uM        cont…         3 Plat… 60min   
#>  3 A03        26 5385. PosControl   100 uM        posi…         1 Plat… 15min   
#>  4 A04        26 5378. PosControl   100 uM        posi…         3 Plat… 60min   
#>  5 A05        29 1038. CompoundA…    50 uM        trea…         1 Plat… 15min   
#>  6 A06        33 1023. CompoundA…    50 uM        trea…         3 Plat… 60min   
#>  7 A07        29 4885. CompoundA…   500 uM        trea…         1 Plat… 15min   
#>  8 A08        27 3488. CompoundA…   500 uM        trea…         3 Plat… 60min   
#>  9 A09        22  739. CompoundB     50 uM        comb…         1 Plat… 15min   
#> 10 A10        26  761. CompoundB     50 uM        comb…         3 Plat… 60min   
#> # ℹ 86 more rows
#> # ℹ 1 more variable: timepoint <dbl>

# aggregate with a different estimator
cr_summarize_wells(exp, channel = "marker_1", fun = mean)
#> # A tibble: 96 × 11
#>    well  n_cells value treatment   dose dose_unit group replicate plate interval
#>    <chr>   <int> <dbl> <chr>      <dbl> <chr>     <chr>     <int> <chr> <chr>   
#>  1 A01        26 2833. Untreated      0 uM        cont…         1 Plat… 15min   
#>  2 A02        16  524. Untreated      0 uM        cont…         3 Plat… 60min   
#>  3 A03        26 5509. PosControl   100 uM        posi…         1 Plat… 15min   
#>  4 A04        26 5783. PosControl   100 uM        posi…         3 Plat… 60min   
#>  5 A05        29 1223. CompoundA…    50 uM        trea…         1 Plat… 15min   
#>  6 A06        33 1139. CompoundA…    50 uM        trea…         3 Plat… 60min   
#>  7 A07        29 6379. CompoundA…   500 uM        trea…         1 Plat… 15min   
#>  8 A08        27 3972. CompoundA…   500 uM        trea…         3 Plat… 60min   
#>  9 A09        22  869. CompoundB     50 uM        comb…         1 Plat… 15min   
#> 10 A10        26  823. CompoundB     50 uM        comb…         3 Plat… 60min   
#> # ℹ 86 more rows
#> # ℹ 1 more variable: timepoint <dbl>
```
