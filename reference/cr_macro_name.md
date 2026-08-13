# Build a macro-safe name

Turns a label into an identifier that a LaTeX control sequence accepts:
letters only, with digits spelled out and every other character dropped.
`"CompoundA_5min"` becomes `"CompoundAfivemin"`.

## Usage

``` r
cr_macro_name(x, prefix = NULL)
```

## Arguments

- x:

  Character vector of labels.

- prefix:

  Optional prefix, transliterated the same way.

## Value

A character vector of the same length as `x`.

## See also

[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md).

Other macros:
[`cr_enumerate()`](https://cttir.github.io/cellreportR/reference/cr_enumerate.md),
[`cr_format_number()`](https://cttir.github.io/cellreportR/reference/cr_format_number.md),
[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md),
[`cr_macros_from()`](https://cttir.github.io/cellreportR/reference/cr_macros_from.md)

## Examples

``` r
cr_macro_name(c("CompoundA_5min", "interval-2", "n cells"))
#> [1] "CompoundAfivemin" "intervaltwo"      "ncells"          
cr_macro_name("estimate", prefix = "screen")
#> [1] "screenestimate"
```
