# Time-course line plot

Time-course line plot

## Usage

``` r
cr_plot_timeline(experiment, timepoint_var, channel, group_by = "treatment")
```

## Arguments

- experiment:

  A `cr_experiment`. Design table must have a time variable column.

- timepoint_var:

  Name of the time variable column.

- channel:

  Channel to plot.

- group_by:

  Grouping variable (colour).

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
exp$design$timepoint <- rep(c(0, 6, 12, 24), length.out = nrow(exp$design))
cr_plot_timeline(exp, "timepoint", "marker_1")
```
