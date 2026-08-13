# Colour-vision-safe palette

Returns hex colours from the palette every `cr_plot_*` function uses for
discrete groupings. The qualitative set is Okabe-Ito, the standard
colour-vision-safe qualitative palette; it deliberately contains no
red/green pair, so hue never encodes an opposition that a large minority
of readers cannot separate.

## Usage

``` r
cr_palette(
  n = NULL,
  type = c("qualitative", "sequential", "diverging"),
  names = NULL
)
```

## Arguments

- n:

  Number of colours to return. `NULL` (default) returns the whole
  palette: 8 colours for `"qualitative"`, 256 for the continuous types.
  Requesting more than 8 qualitative colours interpolates between the
  anchors and warns, because the result is no longer guaranteed to be
  colour-vision-safe; prefer facetting over more than 8 hues.

- type:

  One of `"qualitative"` (discrete groups), `"sequential"`
  (one-directional magnitude) or `"diverging"` (signed magnitude around
  a meaningful zero, ramped blue-to-vermillion rather than
  blue-to-red-green).

- names:

  Optional character vector of names to attach to the returned colours,
  for use as the `values` argument of a manual scale. Must have the same
  length as the result.

## Value

A character vector of hex colour strings, named when `names` is supplied
or when the whole qualitative palette is returned.

## Details

Hue alone is not treated as a sufficient encoding: use
[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md)
(or
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md),
which wires both at once) so that every grouping is carried by shape as
well as colour.

## See also

[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md),
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md),
[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md)

Other plot design:
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md),
[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md),
[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md)

## Examples

``` r
cr_palette()
#>           blue     vermillion   bluish_green         orange reddish_purple 
#>      "#0072B2"      "#D55E00"      "#009E73"      "#E69F00"      "#CC79A7" 
#>       sky_blue         yellow           grey 
#>      "#56B4E9"      "#F0E442"      "#999999" 
cr_palette(3)
#>         blue   vermillion bluish_green 
#>    "#0072B2"    "#D55E00"    "#009E73" 
cr_palette(5, names = c("a", "b", "c", "d", "e"))
#>         a         b         c         d         e 
#> "#0072B2" "#D55E00" "#009E73" "#E69F00" "#CC79A7" 
cr_palette(7, type = "diverging")
#> [1] "#0072B2" "#70A8CF" "#B5D5E6" "#F7F7F7" "#F8C0A8" "#EC8D5C" "#D55E00"
```
