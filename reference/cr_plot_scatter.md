# Biaxial scatter plot of two channels

Biaxial scatter plot of two channels

## Usage

``` r
cr_plot_scatter(
  experiment,
  channel_x,
  channel_y,
  color_by = "treatment",
  log_x = TRUE,
  log_y = TRUE
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel_x:

  X-axis channel.

- channel_y:

  Y-axis channel.

- color_by:

  Design column used for colour. Default `"treatment"`.

- log_x, log_y:

  Log-transform the respective axis.

## Value

A `ggplot` object.

## See also

Other visualisation:
[`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md),
[`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md),
[`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md),
[`cr_plot_foldchange()`](https://cttir.github.io/cellreportR/reference/cr_plot_foldchange.md),
[`cr_plot_heatmap()`](https://cttir.github.io/cellreportR/reference/cr_plot_heatmap.md),
[`cr_plot_histogram()`](https://cttir.github.io/cellreportR/reference/cr_plot_histogram.md),
[`cr_plot_intensity()`](https://cttir.github.io/cellreportR/reference/cr_plot_intensity.md),
[`cr_plot_plate()`](https://cttir.github.io/cellreportR/reference/cr_plot_plate.md),
[`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md),
[`cr_plot_roc()`](https://cttir.github.io/cellreportR/reference/cr_plot_roc.md),
[`cr_plot_spatial()`](https://cttir.github.io/cellreportR/reference/cr_plot_spatial.md),
[`cr_plot_timeline()`](https://cttir.github.io/cellreportR/reference/cr_plot_timeline.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_scatter(exp, "DAPI", "marker_1")
```
