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

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_intensity(exp, channel = "marker_1")
```
