# Compute fold change relative to a control group

Returns log2 fold changes at the cell and replicate levels (relative to
the reference control).

## Usage

``` r
cr_fold_change(
  experiment,
  channel,
  control_group,
  method = c("median", "mean")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- control_group:

  Value in `design$treatment` that defines the reference.

- method:

  `"median"` (default) or `"mean"` — the estimator used to aggregate
  within a replicate before taking log2 ratios.

## Value

A list with components `cell` (tibble, one row per cell with `log2_fc`),
`well` (one row per spatial unit) and `summary` (per treatment, median
FC and 95 percent CI across replicates).

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_fold_change(exp, channel = "marker_1", control_group = "Untreated")
#> $cell
#> # A tibble: 2,911 × 5
#>    cell_id well  value treatment log2_fc
#>    <chr>   <chr> <dbl> <chr>       <dbl>
#>  1 c000001 A01   4019. Untreated   2.92 
#>  2 c000002 A01   1876. Untreated   1.82 
#>  3 c000003 A01    989. Untreated   0.897
#>  4 c000004 A01   1437. Untreated   1.44 
#>  5 c000005 A01   3347. Untreated   2.66 
#>  6 c000006 A01   3608. Untreated   2.76 
#>  7 c000007 A01   1571. Untreated   1.56 
#>  8 c000008 A01   2379. Untreated   2.16 
#>  9 c000009 A01   1481. Untreated   1.48 
#> 10 c000010 A01   3846. Untreated   2.86 
#> # ℹ 2,901 more rows
#> 
#> $well
#> # A tibble: 96 × 10
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
#> # ℹ 1 more variable: log2_fc <dbl>
#> 
#> $summary
#> # A tibble: 6 × 5
#>   treatment       n_wells median_log2_fc mean_log2_fc sd_log2_fc
#>   <chr>             <int>          <dbl>        <dbl>      <dbl>
#> 1 CompoundA_ScavX      16      0.306           0.228       0.299
#> 2 CompoundA_ScavY      16      0.810           0.892       0.607
#> 3 CompoundA_high       16      2.80            2.87        0.287
#> 4 CompoundA_low        16      0.945           0.916       0.362
#> 5 PosControl           16      3.34            3.28        0.398
#> 6 Untreated            16     -0.0000999       0.0986      0.642
#> 
```
