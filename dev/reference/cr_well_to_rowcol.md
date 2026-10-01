# Convert well IDs to row and column indices

Splits well identifiers of the form `"A01"` into the letter row and
numeric column.

## Usage

``` r
cr_well_to_rowcol(well)
```

## Arguments

- well:

  A character vector of well IDs (e.g. `"A01"`, `"H12"`, `"P24"`).

## Value

A tibble with columns `well`, `row` (integer, 1 = A) and `col`
(integer).

## Examples

``` r
cr_well_to_rowcol(c("A01", "B05", "H12"))
#> # A tibble: 3 × 3
#>   well    row   col
#>   <chr> <int> <int>
#> 1 A01       1     1
#> 2 B05       2     5
#> 3 H12       8    12
```
