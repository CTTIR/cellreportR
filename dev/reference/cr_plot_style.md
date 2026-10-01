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
