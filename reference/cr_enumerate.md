# Write a vector out as an English list

Renders a character vector as `"a"`, `"a and b"` or `"a, b and c"`, with
a fixed placeholder for the empty case. Sentences that enumerate results
— which contrasts cleared a threshold, which arms were excluded — should
be generated for the same reason the numbers are: the hand-written
version is right until the analysis changes.

## Usage

``` r
cr_enumerate(x, conjunction = "and", empty = "none", oxford = FALSE)
```

## Arguments

- x:

  Character vector. `NA` and empty strings are dropped.

- conjunction:

  Word joining the last two elements.

- empty:

  Text returned when nothing is left.

- oxford:

  Whether to place a comma before the conjunction.

## Value

A single string.

## See also

[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md),
[`cr_format_number()`](https://cttir.github.io/cellreportR/reference/cr_format_number.md).

Other macros:
[`cr_format_number()`](https://cttir.github.io/cellreportR/reference/cr_format_number.md),
[`cr_macro_name()`](https://cttir.github.io/cellreportR/reference/cr_macro_name.md),
[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md),
[`cr_macros_from()`](https://cttir.github.io/cellreportR/reference/cr_macros_from.md)

## Examples

``` r
cr_enumerate(c("CompoundA", "CompoundB", "CompoundC"))
#> [1] "CompoundA, CompoundB and CompoundC"
cr_enumerate(c("CompoundA", "CompoundB"), conjunction = "or")
#> [1] "CompoundA or CompoundB"
cr_enumerate(character())
#> [1] "none"
```
