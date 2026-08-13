# Standardize a channel against the control of each cell's own batch

Expresses every cell relative to the control cells of the batch it
belongs to, rather than to one pooled reference for the whole
experiment. This is the standardization a plate-based screen needs:
plates, runs and acquisition days each carry their own offset, and a
single pooled control folds that offset into the estimate.

## Usage

``` r
cr_standardize_batch(
  experiment,
  channel,
  control_level,
  batch_vars,
  control_var = "treatment",
  method = c("log2_fc", "zscore", "raw"),
  eps = 1,
  sd_floor = 1e-08,
  value_to = "value_std",
  on_missing_control = c("error", "warn", "drop")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel column to standardize. Must be numeric.

- control_level:

  Value (or values) of `control_var` that mark the control cells of a
  batch.

- batch_vars:

  Character vector of columns that jointly define a batch. See
  [`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md).

- control_var:

  Column holding the treatment assignment. Defaults to `"treatment"`.

- method:

  Which quantity becomes the canonical analysis value in `value_to`:
  `"log2_fc"` (default), `"zscore"` (the per-batch z-score `z_ctrl`), or
  `"raw"` (the untransformed channel, for a like-for-like comparison of
  standardized against measured signal).

- eps:

  Additive offset for the log2 fold change.

- sd_floor:

  Lower bound for the control standard deviation.

- value_to:

  Name of the column receiving the value selected by `method`. Use
  `NULL` to add the component columns only.

- on_missing_control:

  What to do with batches that have no control cells: `"error"`
  (default), `"warn"` or `"drop"`.

## Value

The `cr_experiment` with these columns added to `cells`:

- `batch_key`:

  The batch each cell belongs to.

- `ctrl_n`, `ctrl_mean`, `ctrl_median`, `ctrl_sd`:

  The reference statistics of that batch.

- `z_ctrl`:

  `(y - ctrl_mean) / ctrl_sd`.

- `log2_fc`:

  `log2((y + eps) / (ctrl_mean + eps))`.

- `value_to`:

  The value selected by `method`.

The reference table is stored as `$batch_reference`, the batch columns
as `$batch_vars`, and the settings under `$metadata$standardization`.

## Details

Three quantities are always added, whichever `method` is chosen, because
downstream steps need different ones: `log2_fc`, `z_ctrl` and the
untouched channel. `method` only decides which of them is copied into
`value_to` as the canonical analysis value.

The log2 fold change uses an *additive* offset,
`log2((y + eps) / (ctrl_mean + eps))`, not a floor on `y`. An offset
keeps the transformation monotone and well behaved near zero, whereas
clamping small values to a floor flattens a whole range of the signal
onto one number.

The fold change divides by the control **mean** while
[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md)
also reports the control **median**; see there for why both are kept.

A batch that contains no control cells cannot be standardized: its
reference does not exist, and a value computed against some other
batch's control would be a silent error rather than a measurement.
`cr_standardize_batch()` therefore refuses by default. Use
`on_missing_control = "drop"` to remove those cells (recorded in the QC
log) or `"warn"` to keep them with `NA` standardized values.

## See also

[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md),
[`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md),
[`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md)

Other batch standardization functions:
[`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md),
[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md),
[`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))

std <- cr_standardize_batch(exp, channel = "marker_1",
                            control_level = "Untreated",
                            batch_vars = "plate")
round(summary(std$cells$log2_fc), 2)
#>    Min. 1st Qu.  Median    Mean 3rd Qu.    Max. 
#>   -2.73   -0.22    0.67    0.92    2.17    5.04 
std$batch_reference
#> # A tibble: 2 × 8
#>   plate batch_key n_cells ctrl_n ctrl_mean ctrl_median ctrl_sd has_control
#>   <chr> <chr>       <int>  <int>     <dbl>       <dbl>   <dbl> <lgl>      
#> 1 P1    P1            946    165      806.        450.   1270. TRUE       
#> 2 P2    P2           1015    143      632.        525.    374. TRUE       

# Per-batch z-score instead of the fold change
z <- cr_standardize_batch(exp, channel = "marker_1",
                          control_level = "Untreated",
                          batch_vars = "plate", method = "zscore")
round(stats::median(z$cells$value_std), 2)
#> [1] 0.66

# A batch without control cells is refused, not guessed at
exp$design$plate[exp$design$treatment == "Untreated"] <- "P1"
try(cr_standardize_batch(exp, channel = "marker_1",
                         control_level = "Untreated",
                         batch_vars = "plate"))
#> Error in cr_standardize_batch(exp, channel = "marker_1", control_level = "Untreated",  : 
#>   Cannot standardize marker_1.
#> 1 of 2 batches contain no control cells.
#> ✖ Affected: "P2"
#> ℹ Control cells are those whose treatment is "Untreated".
#> ℹ Widen `batch_vars`, or set `on_missing_control = 'drop'` to exclude them.
```
