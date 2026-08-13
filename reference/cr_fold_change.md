# Compute fold change relative to a control group

Returns log2 fold changes at the cell and unit levels, relative to one
pooled reference computed from the control group.

## Usage

``` r
cr_fold_change(
  experiment,
  channel,
  control_group,
  method = c("median", "mean"),
  eps = 0,
  unit = NULL
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name (a column of `experiment$cells`).

- control_group:

  Value in `design$treatment` that defines the reference.

- method:

  `"median"` (default) or `"mean"` — the estimator used to aggregate
  within a unit before taking log2 ratios.

- eps:

  Additive offset applied to numerator and denominator before the ratio
  is taken, i.e. `log2((value + eps) / (ref + eps))`. The default `0`
  keeps the historical behavior, which floors the numerator at a small
  positive value instead. An additive offset is the better choice for
  counts and for signals that legitimately reach zero, because flooring
  turns every zero into the same arbitrary large negative fold change.

- unit:

  Optional name of the column that identifies the analysis unit. May be
  a column of `cells` or of `design`. If `NULL` (default) the
  experiment's `unit_var` slot is used when present, and the spatial
  unit otherwise.

## Value

A list with components `cell` (tibble, one row per cell with `log2_fc`),
`well` (one row per analysis unit) and `summary` (per treatment: number
of units, median, mean and SD of the unit-level log2 fold change).

## Details

The reference is pooled across the whole experiment. When controls
differ systematically between plates, runs or acquisition days,
standardize each cell against the control of its own batch instead — a
pooled reference silently mixes those batches together.

## See also

[`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md).

Other quantification:
[`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md),
[`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md),
[`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
fc <- cr_fold_change(exp, channel = "marker_1",
                     control_group = "Untreated")
fc$summary
#> # A tibble: 6 × 5
#>   treatment      n_wells median_log2_fc mean_log2_fc sd_log2_fc
#>   <chr>            <int>          <dbl>        <dbl>      <dbl>
#> 1 CompoundA_high      16      2.80            2.87        0.287
#> 2 CompoundA_low       16      0.945           0.916       0.362
#> 3 CompoundB           16      0.306           0.228       0.299
#> 4 CompoundC           16      0.810           0.892       0.607
#> 5 PosControl          16      3.34            3.28        0.398
#> 6 Untreated           16     -0.0000999       0.0986      0.642

# additive offset instead of a floor
fc2 <- cr_fold_change(exp, channel = "marker_1",
                      control_group = "Untreated", eps = 1)
fc2$summary
#> # A tibble: 6 × 5
#>   treatment      n_wells median_log2_fc mean_log2_fc sd_log2_fc
#>   <chr>            <int>          <dbl>        <dbl>      <dbl>
#> 1 CompoundA_high      16      2.80            2.87        0.287
#> 2 CompoundA_low       16      0.944           0.915       0.362
#> 3 CompoundB           16      0.306           0.228       0.298
#> 4 CompoundC           16      0.809           0.891       0.607
#> 5 PosControl          16      3.34            3.27        0.398
#> 6 Untreated           16     -0.0000995       0.0986      0.642
```
