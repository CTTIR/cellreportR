# Forest plot of effect sizes

Forest plot of effect sizes

## Usage

``` r
cr_plot_effect_sizes(results, method = "cohens_d")
```

## Arguments

- results:

  A single `cr_result`, a list of `cr_result`s (from
  [`cr_test_all()`](https://r-heller.github.io/cellreportR/reference/cr_test_all.md))
  or a precomputed tibble with columns `treatment`, `method`,
  `estimate`, `ci_low`, `ci_high`.

- method:

  Effect-size method to plot (default `"cohens_d"`).

## Value

A ggplot2 object.

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
cr_plot_effect_sizes(all_res)

# }
```
