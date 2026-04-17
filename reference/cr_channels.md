# List channels in a `cr_experiment`

List channels in a `cr_experiment`

## Usage

``` r
cr_channels(experiment)
```

## Arguments

- experiment:

  A `cr_experiment`.

## Value

A character vector of channel names.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
cr_channels(exp)
#> [1] "DAPI"     "marker_1" "marker_2" "marker_3"
```
