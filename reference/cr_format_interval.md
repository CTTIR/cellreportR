# Format an estimate and confidence interval

Format an estimate and confidence interval

## Usage

``` r
cr_format_interval(estimate, lower, upper, digits = 2)
```

## Arguments

- estimate, lower, upper:

  Numeric vectors.

- digits:

  Decimal places.

## Value

A character vector of the form `estimate [lower, upper]`.

## Examples

``` r
cr_format_interval(1.234, 0.9, 1.6)
#> [1] "1.23 [0.90, 1.60]"
```
