# Build a descriptive figure caption

Build a descriptive figure caption

## Usage

``` r
cr_figure_caption(
  title = NULL,
  description = NULL,
  n = NULL,
  unit = NULL,
  qc_note = NULL
)
```

## Arguments

- title, description, qc_note:

  User-supplied descriptive text.

- n:

  Optional observation count.

- unit:

  Optional unit-of-replication label.

## Value

A single character string.

## Examples

``` r
cr_figure_caption("Figure 1.", "Fold change per compound.", n = 6, unit = "wells")
#> [1] "Figure 1. Fold change per compound. n = 6 wells"
```
