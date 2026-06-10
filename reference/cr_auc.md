# Compute AUC with confidence interval from a `cr_result`

Compute AUC with confidence interval from a `cr_result`

## Usage

``` r
cr_auc(result, ci_method = c("delong", "bootstrap"), n_boot = 1000)
```

## Arguments

- result:

  A `cr_result` from
  [`cr_logistic()`](https://cttir.github.io/cellreportR/reference/cr_logistic.md).

- ci_method:

  `"delong"` (default) or `"bootstrap"`.

- n_boot:

  Number of bootstrap resamples for `"bootstrap"`.

## Value

A tibble with `auc`, `ci_low`, `ci_high`, `method`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
cr_auc(res)
#> # A tibble: 1 × 4
#>     auc ci_low ci_high method
#>   <dbl>  <dbl>   <dbl> <chr> 
#> 1 0.982  0.974   0.989 delong
```
