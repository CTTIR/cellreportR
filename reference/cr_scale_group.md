# Grouping scales with redundant encoding

Builds the discrete scales that carry a grouping variable: a
colour-vision-safe hue from
[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md)
plus a matching symbol from
[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md).
Add the result to a plot with `+`, exactly like a single scale.

## Usage

``` r
cr_scale_group(
  aesthetics = c("colour", "fill", "shape"),
  name = NULL,
  guide_for = NULL,
  drop = TRUE
)
```

## Arguments

- aesthetics:

  Character vector of aesthetics to scale. Any of `"colour"`, `"color"`,
  `"fill"`, `"shape"`.

- name:

  Legend title. `NULL` (default) keeps the mapped variable name.

- guide_for:

  Aesthetics that keep a visible guide. Use `"all"` when the aesthetics
  are drawn by the same layer and should merge into one key, `"none"` to
  suppress every guide. Defaults to the last of `aesthetics`, which is
  the one drawn on top.

- drop:

  Passed to the underlying scales: drop unused factor levels (default
  `TRUE`).

## Value

A list of `ggplot2` scales.

## Details

Because the same variable is mapped to several aesthetics, the guide is
emitted for one aesthetic only. A duplicate guide is what makes a
composed figure print the same legend twice, so `guide_for` names the
single aesthetic that keeps its legend and every other aesthetic is
suppressed.

## See also

[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md),
[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md)

Other plot design:
[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md),
[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md)

## Examples

``` r
df <- data.frame(g = rep(c("a", "b", "c"), each = 10), y = rnorm(30))
ggplot2::ggplot(df, ggplot2::aes(g, y, colour = g, shape = g)) +
  ggplot2::geom_point() +
  cr_scale_group(c("colour", "shape"), name = "group") +
  cr_theme()
```
