# Compute effect sizes between two samples

Standardized effect sizes for a comparison of two independent samples,
each with a confidence interval. Confidence intervals are analytic by
default (deterministic and cheap on large samples); a bootstrap interval
is available for cases where the analytic approximation is not wanted.

## Usage

``` r
cr_effect_size(
  x,
  y,
  method = c("cohens_d", "hedges_g", "cliffs_delta", "rank_biserial", "glass_delta"),
  ci = 0.95,
  ci_method = c("analytic", "bootstrap"),
  n_boot = 200,
  seed = NULL
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

  Confidence level for the interval (default 0.95). Set `NULL` to skip
  interval estimation.

- ci_method:

  `"analytic"` (default) or `"bootstrap"`.

- n_boot:

  Number of bootstrap resamples used when `ci_method = "bootstrap"`.

- seed:

  Optional integer seed for the bootstrap. The global random number
  stream is restored on exit.

## Value

A tibble with columns `method`, `estimate`, `ci_low`, `ci_high` and
`magnitude`.

## Details

Cohen's *d* uses the pooled standard deviation without small-sample
correction and its interval is the large-sample (Hedges-Olkin)
approximation with a *t* quantile on `n_x + n_y - 2` degrees of freedom.
Hedges' *g* applies the bias correction \\J = 1 - 3 / (4 \cdot df - 1)\\
to both estimate and interval. Glass's delta standardizes by the
standard deviation of `y` only. Cliff's delta uses the consistent
variance estimator with the interval on the transformed scale, so the
bounds always lie inside \\\[-1, 1\]\\. The rank-biserial correlation of
two independent samples equals Cliff's delta and is reported on the same
scale.

## See also

[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md)
for a whole grid of contrasts,
[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md)
for the sample size implied by an effect size.

Other effect sizes:
[`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md),
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md)

## Examples

``` r
set.seed(1)
cr_effect_size(stats::rnorm(100, 1), stats::rnorm(100, 0))
#> # A tibble: 5 × 5
#>   method        estimate ci_low ci_high magnitude
#>   <chr>            <dbl>  <dbl>   <dbl> <chr>    
#> 1 cohens_d         1.23   0.930   1.54  large    
#> 2 hedges_g         1.23   0.927   1.53  large    
#> 3 cliffs_delta     0.616  0.481   0.723 large    
#> 4 rank_biserial    0.616  0.481   0.723 large    
#> 5 glass_delta      1.20   0.872   1.52  large    

# bootstrap interval with a reproducible seed
cr_effect_size(stats::rnorm(50, 1), stats::rnorm(50, 0),
               method = "cliffs_delta",
               ci_method = "bootstrap", n_boot = 50, seed = 42)
#> # A tibble: 1 × 5
#>   method       estimate ci_low ci_high magnitude
#>   <chr>           <dbl>  <dbl>   <dbl> <chr>    
#> 1 cliffs_delta    0.470  0.319   0.648 medium   
```
