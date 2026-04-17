# Heatmap of channel medians across groups

Heatmap of channel medians across groups

## Usage

``` r
cr_plot_heatmap(
  experiment,
  channels,
  group_by = "treatment",
  scale = c("none", "row", "column")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channels:

  Character vector of channel names.

- group_by:

  Design column defining rows. Default `"treatment"`.

- scale:

  One of `"none"`, `"row"`, `"column"`.

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_plot_heatmap(exp, c("DAPI", "marker_1", "marker_2"))
```
