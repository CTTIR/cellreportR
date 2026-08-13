# Subtract background from a channel

Computes a per-well background estimate and subtracts it from every cell
in that well. Negative values are clipped to zero.

## Usage

``` r
cr_background_subtract(
  experiment,
  channel,
  method = c("percentile", "modal", "empty_wells"),
  q = 0.05,
  empty_wells = NULL
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- method:

  Background estimator. `"percentile"` (default) uses a low percentile
  (default 5th), `"modal"` uses the mode of a kernel density estimate,
  and `"empty_wells"` uses the median intensity of wells listed in
  `empty_wells`.

- q:

  Percentile for `"percentile"` method (0-1, default 0.05).

- empty_wells:

  Character vector of well IDs for `"empty_wells"`.

## Value

A modified `cr_experiment`.

## See also

[`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md),
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)

Other normalization functions:
[`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_background_subtract(exp, channel = "marker_1")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2911 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project and sop
```
