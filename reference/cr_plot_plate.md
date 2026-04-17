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

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_plate(exp, channel = "marker_1", metric = "median")
```
