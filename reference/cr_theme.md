# Publication theme

The single `ggplot2` theme every `cr_plot_*` function applies, so that
figures assembled from different functions sit together without
re-styling: a classic axis-line frame, a faint major grid, a bold title,
a muted subtitle and a bottom legend.

## Usage

``` r
cr_theme(
  base_size = 11,
  base_family = "",
  grid = TRUE,
  legend_position = "bottom"
)
```

## Arguments

- base_size:

  Base font size in points (default `11`).

- base_family:

  Base font family. Default `""` (the device default), which keeps
  figures reproducible across machines.

- grid:

  Draw the faint major grid (default `TRUE`).

- legend_position:

  Passed to
  [`ggplot2::theme()`](https://ggplot2.tidyverse.org/reference/theme.html).
  Default `"bottom"`.

## Value

A `ggplot2` theme object, usable with `+` like any other theme.

## See also

[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md)

Other plot design:
[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md),
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md),
[`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md)

## Examples

``` r
df <- data.frame(g = rep(c("a", "b"), each = 20), y = rnorm(40))
ggplot2::ggplot(df, ggplot2::aes(g, y)) +
  ggplot2::geom_boxplot() +
  cr_theme()
```
