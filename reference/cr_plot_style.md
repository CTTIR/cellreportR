# Construct a reusable plot style

Construct a reusable plot style

## Usage

``` r
cr_plot_style(
  mode = c("colour", "grayscale"),
  variant = c("publication", "report"),
  base_size = 9,
  base_family = "sans",
  palette = NULL,
  shapes = NULL,
  linetypes = NULL,
  legend_position = "bottom"
)
```

## Arguments

- mode:

  `"colour"` or `"grayscale"`.

- variant:

  `"publication"` or compact `"report"`.

- base_size:

  Font size in points; values below 8 are rejected.

- base_family:

  System-safe font family.

- palette:

  Optional named qualitative palette.

- shapes:

  Optional named shape mapping.

- linetypes:

  Optional named line-type mapping.

- legend_position:

  Legend position.

## Value

A `cr_plot_style` object: a list with the colour mode, variant, base
font settings, palette, shapes, line types and legend position.

## Examples

``` r
style <- cr_plot_style(mode = "grayscale", variant = "report")
names(style)
#> [1] "mode"            "variant"         "base_size"       "base_family"    
#> [5] "palette"         "shapes"          "linetypes"       "legend_position"
```
