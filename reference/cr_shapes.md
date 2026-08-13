# Redundant shape encoding

Returns plotting symbols matched to
[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
so that a grouping encoded by hue is also encoded by shape. Filled
shapes (`21:25`, which take both a `colour` and a `fill`) come first,
then open shapes.

## Usage

``` r
cr_shapes(n = NULL, names = NULL)
```

## Arguments

- n:

  Number of shapes to return. `NULL` (default) returns all 10.
  Requesting more recycles and warns, because shape has then stopped
  separating the levels.

- names:

  Optional character vector of names to attach, for use as the `values`
  argument of
  [`ggplot2::scale_shape_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).

## Value

An integer vector of `ggplot2` shape codes.

## See also

[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md)

Other plot design:
[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md),
[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md)

## Examples

``` r
cr_shapes(4)
#> [1] 21 22 23 24
cr_shapes(3, names = c("low", "mid", "high"))
#>  low  mid high 
#>   21   22   23 
```
