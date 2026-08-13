# Effect size at the confidence bound nearer the null

Returns the end of a confidence interval that lies closer to zero, which
is the conservative effect a follow-up study should be powered on. When
the interval spans the null there is nothing to power on and `NA` is
returned.

## Usage

``` r
cr_conservative_effect(ci_low, ci_high)
```

## Arguments

- ci_low:

  Numeric vector of lower interval bounds.

- ci_high:

  Numeric vector of upper interval bounds.

## Value

A numeric vector the length of the recycled inputs.

## See also

[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md),
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

Other power:
[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md),
[`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md),
[`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md)

## Examples

``` r
cr_conservative_effect(c(-1.8, -0.4), c(-0.6, 0.9))
#> [1] -0.6   NA
```
