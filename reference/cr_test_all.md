# Test all treatments against a control group

Runs
[`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)
pairwise for every treatment versus the control and adjusts the p-values
across the whole family of comparisons. Both a Bonferroni and a
Benjamini-Hochberg adjustment are reported next to the unadjusted
p-value, never in place of it.

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

  Test to run (see
  [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)).
  Only the first element is used; the argument is a vector for backwards
  compatibility.

- p_adjust:

  P-value adjustment method used for the `p_adj` column (see
  [stats::p.adjust](https://rdrr.io/r/stats/p.adjust.html)). The
  dedicated `p_bonferroni` and `p_BH` columns are always added as well.

- level:

  `"cell"`, `"replicate"` or `"both"`.

## Value

A named list of `cr_result` objects, one per treatment, carrying the
attributes `summary` (a tibble with `treatment`, `log2_fc`, `p_value`,
`cohens_d`, `p_adj`, `p_bonferroni`, `p_BH` and `interpretation`),
`control_group`, `channel` and `level`.

## See also

[`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md),
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

Other statistics:
[`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
all_res <- cr_test_all(exp, channel = "marker_1",
                       control_group = "Untreated",
                       level = "replicate")
attr(all_res, "summary")
#> # A tibble: 5 × 8
#>   treatment log2_fc p_value cohens_d   p_adj p_bonferroni    p_BH interpretation
#>   <chr>       <dbl>   <dbl>    <dbl>   <dbl>        <dbl>   <dbl> <chr>         
#> 1 PosContr…   3.40  1.54e-6   2.12   4.66e-6   0.00000772 4.66e-6 strong        
#> 2 Compound…   1.07  3.12e-5   0.469  5.20e-5   0.000156   5.20e-5 weak          
#> 3 Compound…   3.05  1.86e-6   2.08   4.66e-6   0.00000932 4.66e-6 strong        
#> 4 CompoundB   0.495 2.73e-3   0.0445 2.73e-3   0.0137     2.73e-3 weak          
#> 5 CompoundC   0.923 8.20e-5   0.487  1.02e-4   0.000410   1.02e-4 weak          
# }
```
