# Stable line types for categorical figures

Stable line types for categorical figures

## Usage

``` r
cr_linetypes(n = NULL, names = NULL)
```

## Arguments

- n:

  Number required, at most six.

- names:

  Optional category names.

## Value

A character vector of `ggplot2` line-type names, named when `names` is
supplied.

## Examples

``` r
cr_linetypes(3, names = c("Vehicle", "Low", "High"))
#>   Vehicle       Low      High 
#>   "solid"  "dashed" "dotdash" 
```
