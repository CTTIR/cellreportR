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

A `ggplot` object.

## See also

Other visualisation:
[`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md),
[`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md),
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
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
               test = "mann_whitney", level = "replicate")
cr_plot_comparison(res, exp)
```
