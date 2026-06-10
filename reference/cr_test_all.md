# Test all treatments against a control group

Runs
[`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)
pairwise for every treatment versus the control and adjusts p-values
across comparisons.

## Usage

``` r
cr_test_all(
  experiment,
  channel,
  control_group,
  tests = "mann_whitney",
  p_adjust = "BH",
  level = c("replicate", "cell", "both")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- control_group:

  Control group.

- tests:

  Tests to run (see
  [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)).
  First one is used for the summary p-value.

- p_adjust:

  P-value adjustment method (see
  [stats::p.adjust](https://rdrr.io/r/stats/p.adjust.html)).

- level:

  `"cell"` or `"replicate"` or `"both"`.

## Value

A list of `cr_result` objects plus an attribute `summary` holding a
single overview tibble.

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
all_res <- cr_test_all(exp, channel = "marker_1",
                       control_group = "Untreated",
                       level = "replicate")
attr(all_res, "summary")
#> # A tibble: 5 × 6
#>   treatment       log2_fc    p_value cohens_d      p_adj interpretation
#>   <chr>             <dbl>      <dbl>    <dbl>      <dbl> <chr>         
#> 1 PosControl        3.40  0.00000154   2.12   0.00000466 strong        
#> 2 CompoundA_low     1.07  0.0000312    0.469  0.0000520  weak          
#> 3 CompoundA_high    3.05  0.00000186   2.08   0.00000466 strong        
#> 4 CompoundA_ScavX   0.495 0.00273      0.0445 0.00273    weak          
#> 5 CompoundA_ScavY   0.923 0.0000820    0.487  0.000102   weak          
# }
```
