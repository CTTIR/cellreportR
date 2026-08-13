# Forest plot of effect sizes

Convenience wrapper around
[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md)
for the result objects produced by
[`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md)
and
[`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md).
Use
[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md)
directly for an effect-size table with its own labelling, facetting or
colouring.

## Usage

``` r
cr_plot_effect_sizes(results, method = "cohens_d", ...)
```

## Arguments

- results:

  A single `cr_result`, a list of `cr_result`s (from
  [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md))
  or a precomputed tibble with columns `treatment`, `method`,
  `estimate`, `ci_low`, `ci_high`.

- method:

  Effect-size method to plot (default `"cohens_d"`).

- ...:

  Further arguments passed to
  [`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md),
  for example `facet_by`, `colour_by` or `descending`.

## Value

A `ggplot` object.

## See also

[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md)

Other visualisation:
[`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md),
[`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md),
[`cr_plot_foldchange()`](https://cttir.github.io/cellreportR/reference/cr_plot_foldchange.md),
[`cr_plot_heatmap()`](https://cttir.github.io/cellreportR/reference/cr_plot_heatmap.md),
[`cr_plot_histogram()`](https://cttir.github.io/cellreportR/reference/cr_plot_histogram.md),
[`cr_plot_intensity()`](https://cttir.github.io/cellreportR/reference/cr_plot_intensity.md),
[`cr_plot_plate()`](https://cttir.github.io/cellreportR/reference/cr_plot_plate.md),
[`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md),
[`cr_plot_roc()`](https://cttir.github.io/cellreportR/reference/cr_plot_roc.md),
[`cr_plot_scatter()`](https://cttir.github.io/cellreportR/reference/cr_plot_scatter.md),
[`cr_plot_spatial()`](https://cttir.github.io/cellreportR/reference/cr_plot_spatial.md),
[`cr_plot_timeline()`](https://cttir.github.io/cellreportR/reference/cr_plot_timeline.md)

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
cr_plot_effect_sizes(all_res)

# }
```
