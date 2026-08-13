# Compute per-unit summary metrics

Returns a rich set of per-unit summary statistics for a single channel:
mean, median, SD, MAD, CV, cell count and percent positive above a
threshold. Useful as input for QC dashboards and as the between-unit
variability input of a screen.

## Usage

``` r
cr_compute_metrics(experiment, channel, positive_threshold = NULL, unit = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name (a column of `experiment$cells`).

- positive_threshold:

  Optional numeric threshold. Cells above it are counted as "positive";
  without it `pct_positive` is `NA`.

- unit:

  Optional name of the column that identifies the analysis unit. May be
  a column of `cells` or of `design`. If `NULL` (default) the
  experiment's `unit_var` slot is used when present, and the spatial
  unit otherwise.

## Value

A tibble with one row per analysis unit and the design columns appended.

## See also

[`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md),
[`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md).

Other quantification:
[`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md),
[`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md),
[`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_compute_metrics(exp, channel = "marker_1")
#> # A tibble: 96 × 16
#>    well  n_cells  mean median    sd   mad    cv pct_positive treatment      dose
#>    <chr>   <int> <dbl>  <dbl> <dbl> <dbl> <dbl>        <dbl> <chr>         <dbl>
#>  1 A01        26 2833.  2525. 1194. 1410. 0.422           NA Untreated         0
#>  2 A02        16  524.   458.  288.  207. 0.550           NA Untreated         0
#>  3 A03        26 5509.  5385. 2590. 2212. 0.470           NA PosControl      100
#>  4 A04        26 5783.  5378. 2874. 3116. 0.497           NA PosControl      100
#>  5 A05        29 1223.  1038.  723.  595. 0.591           NA CompoundA_low    50
#>  6 A06        33 1139.  1023.  458.  464. 0.402           NA CompoundA_low    50
#>  7 A07        29 6379.  4885. 3569. 1686. 0.560           NA CompoundA_hi…   500
#>  8 A08        27 3972.  3488. 2118. 2272. 0.533           NA CompoundA_hi…   500
#>  9 A09        22  869.   739.  491.  377. 0.565           NA CompoundB        50
#> 10 A10        26  823.   761.  409.  360. 0.497           NA CompoundB        50
#> # ℹ 86 more rows
#> # ℹ 6 more variables: dose_unit <chr>, group <chr>, replicate <int>,
#> #   plate <chr>, interval <chr>, timepoint <dbl>
cr_compute_metrics(exp, channel = "marker_1", positive_threshold = 800)
#> # A tibble: 96 × 16
#>    well  n_cells  mean median    sd   mad    cv pct_positive treatment      dose
#>    <chr>   <int> <dbl>  <dbl> <dbl> <dbl> <dbl>        <dbl> <chr>         <dbl>
#>  1 A01        26 2833.  2525. 1194. 1410. 0.422        100   Untreated         0
#>  2 A02        16  524.   458.  288.  207. 0.550         12.5 Untreated         0
#>  3 A03        26 5509.  5385. 2590. 2212. 0.470        100   PosControl      100
#>  4 A04        26 5783.  5378. 2874. 3116. 0.497        100   PosControl      100
#>  5 A05        29 1223.  1038.  723.  595. 0.591         72.4 CompoundA_low    50
#>  6 A06        33 1139.  1023.  458.  464. 0.402         72.7 CompoundA_low    50
#>  7 A07        29 6379.  4885. 3569. 1686. 0.560        100   CompoundA_hi…   500
#>  8 A08        27 3972.  3488. 2118. 2272. 0.533        100   CompoundA_hi…   500
#>  9 A09        22  869.   739.  491.  377. 0.565         40.9 CompoundB        50
#> 10 A10        26  823.   761.  409.  360. 0.497         38.5 CompoundB        50
#> # ℹ 86 more rows
#> # ℹ 6 more variables: dose_unit <chr>, group <chr>, replicate <int>,
#> #   plate <chr>, interval <chr>, timepoint <dbl>
```
