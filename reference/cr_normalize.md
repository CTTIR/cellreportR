# Normalize intensity data

Applies a channel-wise normalization. The normalized channel values
replace the original column in `cells`.

## Usage

``` r
cr_normalize(
  experiment,
  channel,
  method = c("background", "control", "zscore", "robust_zscore", "quantile"),
  control_group = NULL,
  ...
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel column to normalize.

- method:

  One of `"background"`, `"control"`, `"zscore"`, `"robust_zscore"`,
  `"quantile"`.

- control_group:

  For `method = "control"`: the treatment name (in `design$treatment`)
  whose median / mean is used as reference.

- ...:

  Additional arguments passed to the underlying method.

## Value

A modified `cr_experiment`.

## Details

- `"background"` subtracts per-well background via
  [`cr_background_subtract()`](https://r-heller.github.io/cellreportR/reference/cr_background_subtract.md)
  (percentile method, 5th percentile).

- `"control"` divides each cell's intensity by the median intensity of
  cells assigned to `control_group`, then takes the log2 ratio.

- `"zscore"` applies a global Z-score across all cells.

- `"robust_zscore"` uses the median and MAD.

- `"quantile"` maps the per-well empirical distributions onto the global
  quantile distribution.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_normalize(exp, channel = "marker_1", method = "robust_zscore")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2911 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project, sop, and normalization
```
