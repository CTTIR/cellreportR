# Correct batch effects

Applies a simple batch correction. `"median_center"` shifts each batch's
median to the overall median. `"combat"` delegates to
[`sva::ComBat`](https://rdrr.io/pkg/sva/man/ComBat.html) when available.

## Usage

``` r
cr_correct_batch(
  experiment,
  batch_var,
  channel,
  method = c("median_center", "combat")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- batch_var:

  Name of the batch variable. Must exist in `design`.

- channel:

  Channel to correct.

- method:

  `"median_center"` or `"combat"`.

## Value

A modified `cr_experiment`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
exp$design$batch <- rep(c("b1", "b2"), length.out = nrow(exp$design))
cr_correct_batch(exp, batch_var = "batch", channel = "marker_1")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2911 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project and sop
```
