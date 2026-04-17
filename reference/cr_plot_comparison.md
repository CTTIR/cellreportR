# Comparison panel (box, fold change, p-value) for a single result

Comparison panel (box, fold change, p-value) for a single result

## Usage

``` r
cr_plot_comparison(result, experiment)
```

## Arguments

- result:

  A `cr_result`.

- experiment:

  A `cr_experiment` (required to reconstruct the underlying intensity
  data).

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
               test = "mann_whitney", level = "replicate")
cr_plot_comparison(res, exp)
```
