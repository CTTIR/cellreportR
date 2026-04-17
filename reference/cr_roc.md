# Extract or compute an ROC curve from a `cr_result`

Extract or compute an ROC curve from a `cr_result`

## Usage

``` r
cr_roc(result)
```

## Arguments

- result:

  A `cr_result` produced by
  [`cr_logistic()`](https://r-heller.github.io/cellreportR/reference/cr_logistic.md).

## Value

A tibble with `threshold`, `sensitivity`, `specificity`, `fpr` and
`tpr`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
head(cr_roc(res))
#> # A tibble: 6 × 5
#>   threshold sensitivity specificity   fpr   tpr
#>       <dbl>       <dbl>       <dbl> <dbl> <dbl>
#> 1 -Inf                1     0       1         1
#> 2    0.0186           1     0.00208 0.998     1
#> 3    0.0197           1     0.00417 0.996     1
#> 4    0.0198           1     0.00625 0.994     1
#> 5    0.0199           1     0.00833 0.992     1
#> 6    0.0200           1     0.0104  0.990     1
```
