# Continuous diverging scale

Continuous diverging scale

## Usage

``` r
cr_scale_diverging(
  midpoint = 0,
  aesthetics = c("colour", "fill"),
  mode = c("colour", "grayscale"),
  ...
)
```

## Arguments

- midpoint:

  Explicit neutral midpoint.

- aesthetics:

  `"colour"` or `"fill"`.

- mode:

  Colour mode.

- ...:

  Passed to the gradient scale.

## Value

A `ggplot2` continuous scale object.

## Examples

``` r
d <- expand.grid(x = 1:5, y = 1:5)
d$z <- d$x - d$y
ggplot2::ggplot(d, ggplot2::aes(x, y, fill = z)) +
  ggplot2::geom_tile() +
  cr_scale_diverging(aesthetics = "fill")
```
