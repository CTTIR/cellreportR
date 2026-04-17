# Dose-response plot

Dose-response plot

## Usage

``` r
cr_plot_dose_response(fit)
```

## Arguments

- fit:

  A `cr_dose_response`.

## Value

A ggplot2 object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
                          500, exp$design$dose)
fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
cr_plot_dose_response(fit)
```
