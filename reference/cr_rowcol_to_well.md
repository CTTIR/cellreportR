# Convert row and column indices to well IDs

Convert row and column indices to well IDs

## Usage

``` r
cr_rowcol_to_well(row, col, pad = 2)
```

## Arguments

- row:

  Integer vector of row numbers (1 = A, 2 = B, ...).

- col:

  Integer vector of column numbers.

- pad:

  Number of digits to pad the column number to (default 2, yielding
  `"A01"` rather than `"A1"`).

## Value

A character vector of well IDs.

## Examples

``` r
cr_rowcol_to_well(c(1, 2, 8), c(1, 5, 12))
#> [1] "A01" "B05" "H12"
```
