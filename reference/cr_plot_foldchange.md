# Fold-change forest plot

Fold-change forest plot

## Usage

``` r
cr_plot_foldchange(result)
```

## Arguments

- result:

  A `cr_result`, a list of `cr_result`s (from
  [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md)),
  or a precomputed data frame with columns `treatment`,
  `median_log2_fc`.

## Value

A ggplot2 object.

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
cr_plot_foldchange(res)

# }
```
