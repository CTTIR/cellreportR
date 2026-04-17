# Spatial scatter of cells in a well

Spatial scatter of cells in a well

## Usage

``` r
cr_plot_spatial(experiment, channel, well = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel used for colouring points.

- well:

  Spatial unit (well or slide ID) to plot. If `NULL`, the first well is
  chosen.

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_spatial(exp, "marker_1")
```
