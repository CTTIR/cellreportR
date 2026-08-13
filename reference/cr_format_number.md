# Format a number for a generated document

Fixed-decimal formatting with the conventions a manuscript needs: a
placeholder rather than `NaN` for non-finite values, an optional
explicit sign — never printed on an exact zero, where a sign would claim
a direction the data does not support — and thousands separators for
counts.

## Usage

``` r
cr_format_number(x, digits = 3, signed = FALSE, big_mark = ",", na = "--")
```

## Arguments

- x:

  Numeric vector.

- digits:

  Decimal places.

- signed:

  Whether to print a leading `+` on positive values.

- big_mark:

  Thousands separator.

- na:

  Placeholder for `NA`, `NaN` and infinite values.

## Value

A character vector of the same length as `x`.

## See also

[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md),
[`cr_enumerate()`](https://cttir.github.io/cellreportR/reference/cr_enumerate.md).

Other macros:
[`cr_enumerate()`](https://cttir.github.io/cellreportR/reference/cr_enumerate.md),
[`cr_macro_name()`](https://cttir.github.io/cellreportR/reference/cr_macro_name.md),
[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md),
[`cr_macros_from()`](https://cttir.github.io/cellreportR/reference/cr_macros_from.md)

## Examples

``` r
cr_format_number(c(1.2345, -0.5, 0, NA))
#> [1] "1.234"  "-0.500" "0.000"  "--"    
cr_format_number(c(1.2345, -0.5, 0), signed = TRUE)
#> [1] "+1.234" "-0.500" "0.000" 
cr_format_number(128400, digits = 0)
#> [1] "128,400"
```
