# Gate cells by intensity

Removes cells whose intensity on a given channel is outside the interval
`[min_intensity, max_intensity]`.

## Usage

``` r
cr_qc_intensity(experiment, channel, min_intensity = NA, max_intensity = NA)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Name of the channel column in `cells`.

- min_intensity, max_intensity:

  Lower and upper bounds. Leave `NA` to skip either.

## Value

A modified `cr_experiment`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_qc_intensity(exp, channel = "DAPI", min_intensity = 50)
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2838 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
