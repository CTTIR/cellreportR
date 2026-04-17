# ROC curve plot

ROC curve plot

## Usage

``` r
cr_plot_roc(result)
```

## Arguments

- result:

  A single `cr_result` or a list of such results.

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
cr_plot_roc(res)
```
