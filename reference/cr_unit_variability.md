# Between-unit variability within a condition

Summarizes how far apart the units of one condition sit. For every group
defined by `by` that holds at least `min_units` units, the number of
units, the coefficient of variation, the spread (`max - min` of the unit
values) and the fold range (`log_base ^ spread`) are reported.

## Usage

``` r
cr_unit_variability(data, value, by, unit = NULL, min_units = 2, log_base = 2)
```

## Arguments

- data:

  A data frame with one row per unit (or per cell when `unit` is given),
  or a `cr_experiment`.

- value:

  Name of the numeric response column, typically a log-scale fold
  change.

- by:

  Character vector of columns defining a condition, for example
  compound, experiment, plate and pre-treatment interval.

- unit:

  Optional column identifying the unit of replication. When given, rows
  are averaged per unit first.

- min_units:

  Minimum number of units a group must contain to be reported (default
  2).

- log_base:

  Base of the logarithm the response is on. Used to turn the spread into
  a fold range. Default 2.

## Value

A tibble with the `by` columns, `n_units`, `mean_value`, `sd_value`,
`cv_pct`, `spread` and `fold_range`, carrying a `summary` attribute (a
one-row tibble with the number of groups and the median, quartiles and
maximum of the fold range).

## Details

This is unit-to-unit variability. It is **not** within-unit technical
repeatability: that would require the same unit to be measured twice,
which a design with one acquisition per unit cannot deliver. A unit
assembled from two partial acquisitions is two halves of one unit, not
two reads of it.

The coefficient of variation is computed as `100 * sd / abs(mean)`,
which is unstable when the mean of a log-scale response approaches zero;
the fold range is the robust summary and is what the attached overall
summary reports.

## See also

[`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md),
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

Other screen statistics:
[`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md)

## Examples

``` r
set.seed(1)
units <- data.frame(
  compound = rep(c("CompoundA", "CompoundB"), each = 12),
  plate = rep(rep(c("P1", "P2"), each = 6), 2),
  log2_fc = stats::rnorm(24, 0, 0.4)
)
v <- cr_unit_variability(units, value = "log2_fc",
                         by = c("compound", "plate"))
v
#> # A tibble: 4 × 8
#>   compound  plate n_units mean_value sd_value cv_pct spread fold_range
#>   <chr>     <chr>   <int>      <dbl>    <dbl>  <dbl>  <dbl>      <dbl>
#> 1 CompoundA P1          6    -0.0116    0.377  3249.  0.972       1.96
#> 2 CompoundA P2          6     0.227     0.235   104.  0.727       1.66
#> 3 CompoundB P1          6    -0.0552    0.484   877.  1.34        2.52
#> 4 CompoundB P2          6     0.0801    0.446   556.  1.16        2.24
attr(v, "summary")
#> # A tibble: 1 × 5
#>   n_groups median_fold_range q25_fold_range q75_fold_range max_fold_range
#>      <int>             <dbl>          <dbl>          <dbl>          <dbl>
#> 1        4              2.10           1.89           2.31           2.52
```
