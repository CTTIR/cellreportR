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

A `ggplot` object.

## See also

[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md)
for effect sizes with confidence intervals.

Other visualisation:
[`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md),
[`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md),
[`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md),
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
res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
cr_plot_foldchange(res)

# }
```
