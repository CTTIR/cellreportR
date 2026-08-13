# Intensity distributions by group

Intensity distributions by group

## Usage

``` r
cr_plot_intensity(
  experiment,
  channel,
  group_by = "treatment",
  geom = c("violin", "boxplot", "both"),
  log_y = TRUE
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- group_by:

  Design column to colour / facet on. Default `"treatment"`.

- geom:

  `"violin"`, `"boxplot"` or `"both"`.

- log_y:

  Log-transform the y-axis (default `TRUE`).

## Value

A `ggplot` object.

## See also

[`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md)
to overlay the unit of replication.

Other visualisation:
[`cr_plot_comparison()`](https://cttir.github.io/cellreportR/reference/cr_plot_comparison.md),
[`cr_plot_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_plot_dose_response.md),
[`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md),
[`cr_plot_foldchange()`](https://cttir.github.io/cellreportR/reference/cr_plot_foldchange.md),
[`cr_plot_heatmap()`](https://cttir.github.io/cellreportR/reference/cr_plot_heatmap.md),
[`cr_plot_histogram()`](https://cttir.github.io/cellreportR/reference/cr_plot_histogram.md),
[`cr_plot_plate()`](https://cttir.github.io/cellreportR/reference/cr_plot_plate.md),
[`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md),
[`cr_plot_roc()`](https://cttir.github.io/cellreportR/reference/cr_plot_roc.md),
[`cr_plot_scatter()`](https://cttir.github.io/cellreportR/reference/cr_plot_scatter.md),
[`cr_plot_spatial()`](https://cttir.github.io/cellreportR/reference/cr_plot_spatial.md),
[`cr_plot_timeline()`](https://cttir.github.io/cellreportR/reference/cr_plot_timeline.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_intensity(exp, channel = "marker_1")
```
