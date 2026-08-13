# Compare unit-level and cell-level effect estimates

Puts the two aggregation levels of a screen side by side and quantifies
how much narrower the cell-level intervals are. A ratio well above one
is pseudo-replication rather than precision: cells within a unit are not
independent, so the cell-level interval understates the uncertainty of
the very same estimate.

## Usage

``` r
cr_compare_levels(unit_effects, cell_effects, by = NULL, estimate = "cohens_d")
```

## Arguments

- unit_effects:

  Effect grid computed with `unit` set, from
  [`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

- cell_effects:

  Effect grid computed on the same data without `unit`.

- by:

  Join keys. `NULL` (default) uses every non-numeric column the two
  grids share, which is the stratifying columns plus `contrast`.

- estimate:

  Name of the effect size column to compare.

## Value

A tibble with the join keys, `estimate_unit`, `estimate_cell`,
`width_unit`, `width_cell` and `ratio` (`width_unit / width_cell`). The
median ratio is attached as the `median_ratio` attribute.

## See also

[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

Other effect sizes:
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md),
[`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md)

## Examples

``` r
set.seed(1)
cells <- data.frame(
  compound = rep(c("CompoundA", "CompoundB"), each = 240),
  arm = rep(rep(c("reference", "interval_short"), each = 120), 2),
  unit_id = rep(paste0("u", 1:8), each = 60),
  log2_fc = stats::rnorm(480)
)
cells$log2_fc <- cells$log2_fc +
  ifelse(cells$compound == "CompoundA" & cells$arm == "interval_short",
         -1, 0)
u <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
                    by = "compound", unit = "unit_id")
k <- cr_effect_grid(cells, "log2_fc", "arm", "reference",
                    by = "compound", min_n = 10)
cmp <- cr_compare_levels(u, k)
cmp
#> # A tibble: 0 × 7
#> # ℹ 7 variables: compound <chr>, contrast <chr>, estimate_unit <dbl>,
#> #   estimate_cell <dbl>, width_unit <dbl>, width_cell <dbl>, ratio <dbl>
attr(cmp, "median_ratio")
#> [1] NA
```
