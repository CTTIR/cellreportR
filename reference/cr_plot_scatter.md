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

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_scatter(exp, "DAPI", "marker_1")
```
