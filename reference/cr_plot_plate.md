# Plate-layout heatmap

Draws a plate-layout heatmap for a 96 or 384-well plate, showing a
summary metric (median intensity, cell count, etc.) per well.

## Usage

``` r
cr_plot_plate(
  experiment,
  channel,
  metric = c("median", "mean", "cv", "n_cells")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name for the metric computation.

- metric:

  One of `"median"`, `"mean"`, `"cv"`, `"n_cells"`.

## Value

A `ggplot` object.

## See also

[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md),
[`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md)

Other visualisation:
[`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md),
[`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md),
[`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md),
[`cr_plot_foldchange()`](https://cttir.github.io/cellreportR/reference/cr_plot_foldchange.md),
[`cr_plot_heatmap()`](https://cttir.github.io/cellreportR/reference/cr_plot_heatmap.md),
[`cr_plot_histogram()`](https://cttir.github.io/cellreportR/reference/cr_plot_histogram.md),
[`cr_plot_intensity()`](https://cttir.github.io/cellreportR/reference/cr_plot_intensity.md),
[`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md),
[`cr_plot_roc()`](https://cttir.github.io/cellreportR/reference/cr_plot_roc.md),
[`cr_plot_scatter()`](https://cttir.github.io/cellreportR/reference/cr_plot_scatter.md),
[`cr_plot_spatial()`](https://cttir.github.io/cellreportR/reference/cr_plot_spatial.md),
[`cr_plot_timeline()`](https://cttir.github.io/cellreportR/reference/cr_plot_timeline.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_plate(exp, channel = "marker_1", metric = "median")
```
