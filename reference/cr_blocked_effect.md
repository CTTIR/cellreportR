# Block-stratified sensitivity fit

Re-estimates each contrast *within* a blocking factor, typically the
plate. Units on one plate share a preparation run, an imaging session
and a single control denominator, so they are not independent and a
pooled estimate carries the between-plate variance inside its standard
deviation. Fitting `value ~ group + block` on unit-level data removes
the additive block effect and shows whether the pooled headline estimate
is conservative or inflated by pooling.

## Usage

``` r
cr_blocked_effect(
  data,
  value,
  group_var,
  reference_level,
  comparison_levels = NULL,
  block_var,
  by = NULL,
  unit = NULL,
  conf_level = 0.95,
  min_blocks = 2
)
```

## Arguments

- data:

  A data frame with one row per unit (or per cell when `unit` is given),
  or a `cr_experiment`.

- value:

  Name of the numeric response column.

- group_var:

  Name of the column holding the compared groups.

- reference_level:

  Reference level of `group_var`.

- comparison_levels:

  Levels contrasted against the reference. `NULL` (default) uses every
  other level present.

- block_var:

  Name of the blocking column, for example the plate.

- by:

  Optional character vector of stratifying columns, for example the
  compound.

- unit:

  Optional column identifying the unit of replication. When given, rows
  are averaged per unit before the model is fitted.

- conf_level:

  Confidence level for the coefficient interval.

- min_blocks:

  Minimum number of blocks that must carry data for a contrast to be
  fitted (default 2; with one block the model is the unblocked one).

## Value

A tibble with the `by` columns, `contrast`, `n_units`, `n_blocks`,
`shift_within_block` (the group coefficient), `ci_low`, `ci_high`,
`resid_sd`, `d_within_block` and `p_value`. Contrasts that could not be
fitted are returned in the `skipped` attribute.

## Details

The reported `d_within_block` is the group coefficient divided by the
residual standard deviation of the blocked fit, so it is on the same
scale as Cohen's *d* from
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md)
but conditions on the block.

## See also

[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md),
[`cr_unit_variability()`](https://cttir.github.io/cellreportR/reference/cr_unit_variability.md).

Other screen statistics:
[`cr_unit_variability()`](https://cttir.github.io/cellreportR/reference/cr_unit_variability.md)

## Examples

``` r
set.seed(1)
units <- data.frame(
  compound = rep(c("CompoundA", "CompoundB"), each = 16),
  arm = rep(rep(c("reference", "interval_short"), each = 8), 2),
  plate = rep(rep(c("P1", "P2"), each = 4), 8),
  log2_fc = stats::rnorm(32)
)
units$log2_fc <- units$log2_fc +
  ifelse(units$compound == "CompoundA" & units$arm == "interval_short",
         -1.2, 0) +
  ifelse(units$plate == "P2", 0.5, 0)
cr_blocked_effect(units, value = "log2_fc", group_var = "arm",
                  reference_level = "reference",
                  block_var = "plate", by = "compound")
#> # A tibble: 2 × 10
#>   compound  contrast n_units n_blocks shift_within_block ci_low ci_high resid_sd
#>   <chr>     <chr>      <int>    <int>              <dbl>  <dbl>   <dbl>    <dbl>
#> 1 CompoundA referen…      32        2             -1.28  -1.98   -0.576    0.973
#> 2 CompoundB referen…      32        2             -0.250 -0.896   0.397    0.894
#> # ℹ 2 more variables: d_within_block <dbl>, p_value <dbl>
```
