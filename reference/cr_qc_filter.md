# Filter cells by morphology

Removes debris and artifacts by thresholding morphological measurements.
Any parameter left at `NA` is not applied.

## Usage

``` r
cr_qc_filter(
  experiment,
  min_area = NA,
  max_area = NA,
  min_circularity = NA,
  max_circularity = NA
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- min_area, max_area:

  Numeric area thresholds. Cells outside the inclusive interval are
  removed.

- min_circularity, max_circularity:

  Circularity thresholds (range 0-1).

## Value

A modified `cr_experiment` with fewer cells and a QC log entry.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 50)
exp2 <- cr_qc_filter(exp, min_area = 100, max_area = 2000)
cr_n_cells(exp2)
#> [1] 4516
```
