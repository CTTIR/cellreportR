# Manual colour scale from the cellreportR visual system

Manual colour scale from the cellreportR visual system

## Usage

``` r
cr_scale_colour(values = NULL, mode = c("colour", "grayscale"), ...)

cr_scale_fill(values = NULL, mode = c("colour", "grayscale"), ...)

cr_shape_scale(values = NULL, ...)

cr_linetype_scale(values = NULL, ...)
```

## Arguments

- values:

  Optional named values.

- mode:

  Colour mode.

- ...:

  Passed to
  [`ggplot2::scale_colour_manual()`](https://ggplot2.tidyverse.org/reference/scale_manual.html).
