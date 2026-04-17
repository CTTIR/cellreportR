# Compute effect sizes between two samples

Compute effect sizes between two samples

## Usage

``` r
cr_effect_size(
  x,
  y,
  method = c("cohens_d", "hedges_g", "cliffs_delta", "rank_biserial"),
  ci = 0.95,
  n_boot = 200
)
```

## Arguments

- x:

  Numeric vector (treatment group).

- y:

  Numeric vector (control / reference group).

- method:

  Character vector of methods to compute. Allowed: `"cohens_d"`,
  `"hedges_g"`, `"cliffs_delta"`, `"rank_biserial"`, `"glass_delta"`.

- ci:

  Confidence level for bootstrap CI (default 0.95). Set `NULL` to skip.

- n_boot:

  Number of bootstrap resamples used for the CI.

## Value

A tibble with columns `method`, `estimate`, `ci_low`, `ci_high`,
`magnitude`.

## Examples

``` r
set.seed(1)
cr_effect_size(stats::rnorm(100, 1), stats::rnorm(100, 0))
#> # A tibble: 4 × 5
#>   method        estimate ci_low ci_high magnitude
#>   <chr>            <dbl>  <dbl>   <dbl> <chr>    
#> 1 cohens_d         1.23   0.959   1.62  large    
#> 2 hedges_g         1.23   0.892   1.61  large    
#> 3 cliffs_delta     0.616  0.474   0.731 large    
#> 4 rank_biserial   -0.616 -0.730  -0.490 large    
```
