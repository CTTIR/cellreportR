# Quantify the leverage of gate exclusions

Re-estimates every contrast affected by a gate exclusion twice — with
the failing unit retained and with it removed — so that "one excluded
unit changes the verdict" carries a number rather than a recollection.
This matters most when an excluded unit sits in the *reference* arm,
where retaining it makes the untreated condition look as though it were
already responding.

## Usage

``` r
cr_qc_gate_impact(
  experiment,
  gate,
  value = "log2_fc",
  group_var,
  reference_level,
  comparison_levels = NULL,
  by = NULL,
  unit = NULL,
  min_units = 3,
  affected_only = TRUE
)
```

## Arguments

- experiment:

  A `cr_experiment` that still contains the gated units.

- gate:

  A `cr_qc_gate` from
  [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md).

- value:

  Per-cell numeric column averaged to the unit level before the contrast
  is taken. Default `"log2_fc"`.

- group_var:

  Column holding the arm labels of the contrast.

- reference_level:

  Level of `group_var` used as the reference arm.

- comparison_levels:

  Levels contrasted against the reference. `NULL` (default) uses every
  other level present.

- by:

  Optional character vector of columns to compute the contrasts within
  (for example the compound).

- unit:

  Analysis unit column. Defaults to the gate's unit.

- min_units:

  Minimum number of units per arm; contrasts below it return `NA`
  estimates. Default `3`.

- affected_only:

  Restrict the output to `by` groups that actually lost a unit. Default
  `TRUE`.

## Value

A tibble with one row per `by` group and contrast: unit counts in both
states, `estimate_with_excluded`, `estimate_without_excluded`, their
magnitudes, and whether the magnitude or the sign changes when the unit
is dropped. The estimate is a pooled, uncorrected standardised mean
difference.

## Details

Call this **before**
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md):
the "retained" state needs the failing units to still be present in
`experiment`.

## See also

[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md).

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
exp$cells$signal <- log2(exp$cells$marker_1)
gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
cr_qc_gate_impact(exp, gate,
  value = "signal",
  group_var = "treatment",
  reference_level = "Untreated"
)
#> # A tibble: 5 × 12
#>   contrast                n_reference_with n_comparison_with n_reference_without
#>   <chr>                              <int>             <int>               <int>
#> 1 Untreated -> CompoundA…               16                16                  16
#> 2 Untreated -> CompoundA…               16                16                  16
#> 3 Untreated -> CompoundB                16                16                  16
#> 4 Untreated -> CompoundC                16                16                  16
#> 5 Untreated -> PosControl               16                16                  16
#> # ℹ 8 more variables: n_comparison_without <int>, n_units_excluded <int>,
#> #   estimate_with_excluded <dbl>, magnitude_with_excluded <chr>,
#> #   estimate_without_excluded <dbl>, magnitude_without_excluded <chr>,
#> #   magnitude_changed <lgl>, sign_changed <lgl>
```
