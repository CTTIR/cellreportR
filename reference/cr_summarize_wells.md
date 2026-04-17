# Summarize cell-level data to the well / slide level

Aggregates the per-cell values for a channel to a single number per
spatial unit.

## Usage

``` r
cr_summarize_wells(experiment, channel, fun = stats::median)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- fun:

  Aggregation function. Default
  [`stats::median`](https://rdrr.io/r/stats/median.html).

## Value

A tibble with one row per spatial unit containing `well` (or `slide`),
`n_cells`, the aggregated `value`, and the treatment columns from
`design`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_summarize_wells(exp, channel = "marker_1")
#> # A tibble: 96 × 9
#>    well  n_cells value treatment        dose dose_unit group replicate timepoint
#>    <chr>   <int> <dbl> <chr>           <dbl> <chr>     <chr>     <int>     <dbl>
#>  1 A01        26 2525. Untreated           0 uM        cont…         1        24
#>  2 A02        16  458. Untreated           0 uM        cont…         3        24
#>  3 A03        26 5385. PosControl        100 uM        posi…         1        24
#>  4 A04        26 5378. PosControl        100 uM        posi…         3        24
#>  5 A05        29 1038. CompoundA_low      50 uM        trea…         1        24
#>  6 A06        33 1023. CompoundA_low      50 uM        trea…         3        24
#>  7 A07        29 4885. CompoundA_high    500 uM        trea…         1        24
#>  8 A08        27 3488. CompoundA_high    500 uM        trea…         3        24
#>  9 A09        22  739. CompoundA_ScavX    50 uM        resc…         1        24
#> 10 A10        26  761. CompoundA_ScavX    50 uM        resc…         3        24
#> # ℹ 86 more rows
```
