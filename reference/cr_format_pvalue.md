# Format p-values without displaying calculated zero

Format p-values without displaying calculated zero

## Usage

``` r
cr_format_pvalue(x, digits = 3)
```

## Arguments

- x:

  Numeric p-values.

- digits:

  Decimal places determining the reporting threshold.

## Value

A character vector; values below the reporting threshold are shown as
`p < ...` and invalid inputs as `NA`.

## Examples

``` r
cr_format_pvalue(c(0.2, 0.0004, NA))
#> [1] "p = 0.200" "p < 0.001" NA         
```
