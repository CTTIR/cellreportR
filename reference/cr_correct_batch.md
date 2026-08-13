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

  Name of the batch variable, or a character vector of several column
  names that jointly define a batch (they are collapsed with
  [`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md)).
  Columns are looked up in `design` first and then in `cells`.

- channel:

  Channel to correct.

- method:

  `"median_center"` or `"combat"`.

## Value

A modified `cr_experiment`.

## Details

Batch correction removes a batch offset from the measured signal. It is
*not* a substitute for
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md),
which expresses every cell relative to the control cells of its own
batch and leaves the measured signal untouched.

## See also

[`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md),
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)

Other batch standardization functions:
[`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md),
[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md),
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)

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

# A batch defined by more than one column
exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
cr_correct_batch(exp, batch_var = c("batch", "plate"),
                 channel = "marker_1")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2911 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project and sop
```
