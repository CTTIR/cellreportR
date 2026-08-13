# Effect sizes for a whole grid of contrasts

Drives
[`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md)
over every group in a screen: for each stratum given by `by`, each
comparison level of `group_var` is contrasted against `reference_level`,
and every requested effect size is reported with a confidence interval.
The same function serves both aggregation levels: supply `unit` to
aggregate the rows to one value per experimental unit (the unit of
replication) before the contrast is computed, or leave it `NULL` to work
on the rows as they are (typically single cells).

## Usage

``` r
cr_effect_grid(
  data,
  value,
  group_var,
  reference_level,
  comparison_levels = NULL,
  by = NULL,
  unit = NULL,
  methods = c("cohens_d", "hedges_g", "cliffs_delta"),
  conf_level = 0.95,
  min_n = 3,
  test = c("t", "wilcox", "none"),
  p_adjust = c("bonferroni", "BH"),
  level = NULL
)
```

## Arguments

- data:

  A data frame (one row per cell or per unit) or a `cr_experiment`, in
  which case the design is joined onto the cells first.

- value:

  Name of the numeric response column, for example a standardized log2
  fold change or a raw channel.

- group_var:

  Name of the column holding the compared groups.

- reference_level:

  Level of `group_var` used as the reference arm of every contrast.

- comparison_levels:

  Levels contrasted against the reference. `NULL` (default) uses every
  other level present, in factor-level order when `group_var` is a
  factor.

- by:

  Optional character vector of stratifying columns. One set of contrasts
  is computed per combination, for example one per compound.

- unit:

  Optional name of the column identifying the unit of replication. When
  given, rows are averaged to one value per unit before the contrast is
  computed.

- methods:

  Effect sizes to compute; see
  [`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md).

- conf_level:

  Confidence level for the intervals.

- min_n:

  Minimum number of observations required in *each* arm. Contrasts below
  it are skipped and recorded in the `skipped` attribute. Use 3 for unit
  level and something like 10 for cell level.

- test:

  P-value to accompany the effect sizes: `"t"` (Welch two-sample t-test,
  the default), `"wilcox"` or `"none"`.

- p_adjust:

  Multiplicity adjustments applied across the grid. Default both
  `"bonferroni"` and `"BH"`; see
  [`stats::p.adjust()`](https://rdrr.io/r/stats/p.adjust.html).

- level:

  Optional label written into the `level` column. Defaults to `"unit"`
  when `unit` is given and `"cell"` otherwise.

## Value

A tibble with one row per stratum and contrast: the `by` columns,
`contrast`, `level`, `n_ref`, `n_cmp`, `mean_shift`, one `<method>`,
`<method>_ci_low`, `<method>_ci_high` and `<method>_magnitude` triplet
per requested method, `p_value`, one `p_<adjustment>` column per entry
of `p_adjust`, and `ci_excludes_zero` for the first method. The
attributes `conf_level`, `level`, `primary_method` and `skipped` (a
tibble of the contrasts that fell below `min_n`) are attached.

## Details

Cell-level intervals are anticonservative by construction, because cells
within a unit are not independent. Compute both levels and pass them to
[`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md)
to quantify the difference; interpretation belongs to the unit level.

Multiplicity adjustment is applied across the entire returned grid and
reported *alongside* the unadjusted p-value, never in place of it: for
an exploratory screen the effect sizes and their intervals are the
reportable quantity.

## See also

[`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md),
[`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md),
[`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md),
[`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md).

Other effect sizes:
[`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md),
[`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md)

## Examples

``` r
set.seed(1)
units <- data.frame(
  compound = rep(c("CompoundA", "CompoundB"), each = 12),
  arm = rep(rep(c("reference", "interval_short"), each = 6), 2),
  unit_id = paste0("u", 1:24),
  log2_fc = c(stats::rnorm(6, 0, 0.3), stats::rnorm(6, -1, 0.3),
              stats::rnorm(6, 0, 0.3), stats::rnorm(6, -0.1, 0.3))
)
eff <- cr_effect_grid(units, value = "log2_fc", group_var = "arm",
                      reference_level = "reference", by = "compound")
eff[, c("compound", "contrast", "cohens_d", "cohens_d_ci_low",
        "cohens_d_ci_high", "ci_excludes_zero")]
#> # A tibble: 2 × 6
#>   compound  contrast  cohens_d cohens_d_ci_low cohens_d_ci_high ci_excludes_zero
#>   <chr>     <chr>        <dbl>           <dbl>            <dbl> <lgl>           
#> 1 CompoundA referenc… -3.49              -5.65            -1.33 TRUE            
#> 2 CompoundB referenc…  0.00426           -1.28             1.29 FALSE           
```
