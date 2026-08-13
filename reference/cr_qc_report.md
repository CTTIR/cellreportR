# Report every analysis unit with its QC verdict

Returns one row per analysis unit so that the gate can be audited: which
units were seen, what their signal was relative to their own control,
which were excluded and why, and how many cells each still contributes.
Units the gate removed are kept in the report — a gate whose casualties
disappear from the record cannot be reviewed.

## Usage

``` r
cr_qc_report(experiment, gate = NULL, unit = NULL, vars = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- gate:

  Optional `cr_qc_gate`. Defaults to the gate stored by
  [`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md)
  in `metadata$qc_gate`, if any.

- unit:

  Analysis unit column. Defaults to the gate's unit, or the experiment's
  unit / spatial unit.

- vars:

  Optional character vector of extra design columns to carry into the
  report. `NULL` (default) carries the columns the gate was batched on.

## Value

A tibble with one row per unit: the unit identifier, the requested
design columns, `n_cells_gated` (cells the gate saw), `n_cells` (cells
present now), `retained`, and — when a gate is available — the control
statistics, `pct_of_control`, `fails_vs_median`, `fails_vs_mean`,
`disputed`, `verdict` and `reason`. Failing units are listed first.

## See also

[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md).

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
exp2 <- cr_apply_gate(exp, gate)
rep <- cr_qc_report(exp2)
head(rep[, c("well", "n_cells", "verdict", "reason")])
#> # A tibble: 6 × 4
#>   well  n_cells verdict reason                                          
#>   <chr>   <int> <chr>   <chr>                                           
#> 1 B09         0 fail    "unit median does not exceed the control median"
#> 2 B11         0 fail    "unit median does not exceed the control median"
#> 3 A05        43 pass    ""                                              
#> 4 A09        39 pass    ""                                              
#> 5 A11        38 pass    ""                                              
#> 6 B05        47 pass    ""                                              

# without a gate the report is still a per-unit inventory
head(cr_qc_report(exp))
#> # A tibble: 6 × 14
#>   well  treatment  dose dose_unit group   replicate plate   interval timepoint
#>   <chr> <chr>     <dbl> <chr>     <chr>       <int> <chr>   <chr>        <dbl>
#> 1 A01   Untreated     0 uM        control         1 Plate_1 15min           24
#> 2 B01   Untreated     0 uM        control         1 Plate_1 15min           24
#> 3 C01   Untreated     0 uM        control         1 Plate_2 15min           24
#> 4 D01   Untreated     0 uM        control         1 Plate_2 15min           24
#> 5 E01   Untreated     0 uM        control         2 Plate_1 15min           24
#> 6 F01   Untreated     0 uM        control         2 Plate_1 15min           24
#> # ℹ 5 more variables: n_cells <int>, n_cells_gated <int>, retained <lgl>,
#> #   verdict <chr>, reason <chr>
```
