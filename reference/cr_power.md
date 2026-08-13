# Sample size for a future study, sized twice

Solves the two-sample design for the number of units per arm needed to
reach `power` at `sig_level`, once for the observed effect and once for
the confidence bound nearer the null.

## Usage

``` r
cr_power(
  effect_size = NULL,
  ci_low = NULL,
  ci_high = NULL,
  power = 0.8,
  sig_level = 0.05,
  type = c("two.sample", "one.sample", "paired"),
  alternative = c("two.sided", "one.sided")
)
```

## Arguments

- effect_size:

  Numeric vector of observed standardized effects (Cohen's *d*). May be
  `NULL` when only interval bounds are given.

- ci_low, ci_high:

  Numeric vectors of interval bounds for the same effects. Optional.

- power:

  Target power (default 0.8).

- sig_level:

  Significance level (default 0.05).

- type:

  Design: `"two.sample"` (default), `"one.sample"` or `"paired"`.

- alternative:

  `"two.sided"` (default) or `"one.sided"`.

## Value

A tibble with one row per effect: `d_observed`, `n_observed`,
`d_conservative`, `n_conservative`, `basis`, `power` and `sig_level`.
Sample sizes are units per arm, rounded up.

## Details

The conservative figure is the reportable one. Powering a screen's
leading compound on its own point estimate is circular: that compound is
the largest of the set only by virtue of having been selected for being
largest, so a sample size derived from it can hardly fail to be met.
`n_conservative` is `NA` whenever the interval spans the null, because
an interval compatible with no effect cannot be sized.

The solver is
[`stats::power.t.test()`](https://rdrr.io/r/stats/power.t.test.html), so
the effect size is read as a standardized mean difference and `n` is per
group.

## See also

[`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md),
[`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md),
[`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md).

Other power:
[`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md),
[`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md),
[`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md)

## Examples

``` r
cr_power(effect_size = c(-1.31, -0.28),
         ci_low = c(-2.35, -1.20),
         ci_high = c(-0.27, 0.64))
#> # A tibble: 2 × 7
#>   d_observed n_observed d_conservative n_conservative basis      power sig_level
#>        <dbl>      <dbl>          <dbl>          <dbl> <chr>      <dbl>     <dbl>
#> 1      -1.31         11          -0.27            217 confidenc…   0.8      0.05
#> 2      -0.28        202          NA                NA interval …   0.8      0.05

# without an interval only the (circular) observed sizing is possible
cr_power(effect_size = 0.8)
#> # A tibble: 1 × 7
#>   d_observed n_observed d_conservative n_conservative basis      power sig_level
#>        <dbl>      <dbl>          <dbl>          <dbl> <chr>      <dbl>     <dbl>
#> 1        0.8         26             NA             NA observed …   0.8      0.05
```
