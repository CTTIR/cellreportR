# QC dashboard

Combines cell count per well, area distributions and intensity
distributions into a single multi-panel figure.

## Usage

``` r
cr_plot_qc(experiment, channel = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name used for the intensity panel.

## Value

A ggplot2 object (facetted).

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_qc(exp, channel = "marker_1")
```
