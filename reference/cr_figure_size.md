# Standard deterministic figure dimensions

Standard deterministic figure dimensions

## Usage

``` r
cr_figure_size(
  size = c("single", "double", "report", "square"),
  units = c("mm", "in")
)
```

## Arguments

- size:

  One of `single`, `double`, `report`, or `square`.

- units:

  `"mm"` or `"in"`.

## Value

A named list with `width` and `height`; the unit is stored in the
`units` attribute.

## Examples

``` r
cr_figure_size("double", units = "in")
#> $width
#> [1] 6.889764
#> 
#> $height
#> [1] 4.133858
#> 
#> attr(,"units")
#> [1] "in"
```
