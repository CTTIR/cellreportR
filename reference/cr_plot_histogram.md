# Histogram of channel intensity

Histogram of channel intensity

## Usage

``` r
cr_plot_histogram(
  experiment,
  channel,
  group_by = "treatment",
  facet_by = NULL,
  log_x = TRUE
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- group_by:

  Design column used for colour.

- facet_by:

  Design column used for facetting (or `NULL`).

- log_x:

  Log-transform the x-axis.

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_histogram(exp, "marker_1")
```
