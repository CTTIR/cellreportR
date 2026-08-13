# Sample sizes for a whole effect grid

Applies
[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md)
to every row of an effect grid produced by
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md)
and binds the sizing columns onto it, so the observed and the
conservative sample size travel with the contrast they belong to.

## Usage

``` r
cr_power_grid(
  effects,
  estimate = "cohens_d",
  ci_low = NULL,
  ci_high = NULL,
  available = NULL,
  power = 0.8,
  sig_level = 0.05,
  type = c("two.sample", "one.sample", "paired"),
  alternative = c("two.sided", "one.sided")
)
```

## Arguments

- effects:

  An effect grid from
  [`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md),
  or any data frame with an estimate column and its two interval
  columns.

- estimate:

  Name of the effect size column. The interval columns default to
  `<estimate>_ci_low` and `<estimate>_ci_high`.

- ci_low, ci_high:

  Optional explicit names of the interval columns.

- available:

  Units already available per arm, used to flag which contrasts are
  already large enough. Either a column name in `effects` or a numeric
  vector. Defaults to `pmin(n_ref, n_cmp)` when those columns are
  present.

- power:

  Target power (default 0.8).

- sig_level:

  Significance level (default 0.05).

- type:

  Design passed to
  [`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md).

- alternative:

  Alternative passed to
  [`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md).

## Value

`effects` with the columns `d_conservative`, `n_observed`,
`n_conservative` and `basis` appended, plus `n_available` and
`sufficient` when availability is known.

## See also

[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md),
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

Other power:
[`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md),
[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md),
[`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md)

## Examples

``` r
set.seed(1)
units <- data.frame(
  compound = rep(c("CompoundA", "CompoundB"), each = 12),
  arm = rep(rep(c("reference", "interval_short"), each = 6), 2),
  log2_fc = c(stats::rnorm(6, 0, 0.3), stats::rnorm(6, -1.4, 0.3),
              stats::rnorm(6, 0, 0.3), stats::rnorm(6, -0.1, 0.3))
)
eff <- cr_effect_grid(units, "log2_fc", "arm", "reference",
                      by = "compound")
sizes <- cr_power_grid(eff)
sizes[, c("compound", "n_observed", "n_conservative", "basis")]
#> # A tibble: 2 × 4
#>   compound  n_observed n_conservative basis                               
#>   <chr>          <dbl>          <dbl> <chr>                               
#> 1 CompoundA          3              5 confidence bound nearer the null    
#> 2 CompoundB     864794             NA interval spans the null; not sizable
```
