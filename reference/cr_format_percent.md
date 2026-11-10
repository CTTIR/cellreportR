# Format proportions as percentages

Format proportions as percentages

## Usage

``` r
cr_format_percent(x, digits = 1)
```

## Arguments

- x:

  Numeric proportions.

- digits:

  Decimal places.

## Value

A character vector of percentages; `NA` inputs stay `NA`.

## Examples

``` r
cr_format_percent(c(0.125, 0.5, NA))
#> [1] "12.5%" "50.0%" NA     
```
