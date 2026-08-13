# Gate analysis units against their own in-batch control

A biological rather than a statistical gate: a treated unit must carry
more target signal than the vehicle control acquired in its own batch.
Units that do not are candidates for exclusion. The comparison is made
against the control of the unit's *own* batch, so a plate that ran hot
or cold as a whole cannot pass or fail units in unrelated batches.

## Usage

``` r
cr_qc_gate(
  experiment,
  channel,
  control_level,
  batch_vars = NULL,
  unit = NULL,
  control_var = "treatment",
  statistic = c("median", "mean"),
  reference = c("median", "mean"),
  direction = c("greater", "less"),
  gate_controls = FALSE,
  min_cells = 1L
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Name of the raw signal column in `cells`.

- control_level:

  Value of `control_var` marking the vehicle control units.

- batch_vars:

  Character vector of columns (from `cells` or `design`) whose
  combination defines one batch. `NULL` (default) treats the whole
  experiment as a single batch.

- unit:

  Column identifying the analysis unit. Defaults to the experiment's
  unit column, falling back to its spatial unit.

- control_var:

  Column holding the treatment labels. Default `"treatment"`.

- statistic:

  Centre of the *unit* used for the comparison: `"median"` (default) or
  `"mean"`.

- reference:

  Centre of the *control* used as the threshold: `"median"` (default) or
  `"mean"`.

- direction:

  `"greater"` (default) requires a unit to exceed its control; `"less"`
  requires it to fall below.

- gate_controls:

  Should control units be gated against themselves? Default `FALSE`;
  they form the reference arm.

- min_cells:

  Units with fewer than `min_cells` cells fail regardless of their
  signal. Default `1`, i.e. no effect.

## Value

An object of class `cr_qc_gate`, a list with:

- `units`:

  One row per analysis unit: cell count, both raw centres, the control
  statistics of its batch, `pct_of_control`, `fails_vs_median`,
  `fails_vs_mean`, `disputed`, `verdict` and `reason`.

- `disputed`:

  The units whose verdict depends on which control centre is used.

- `excluded`:

  Identifiers of the units that fail under the chosen
  `statistic`/`reference` combination.

- `params`:

  The arguments the gate was built with.

## Details

Two properties of this gate decide whether it is honest, and both are
made explicit here.

**Like for like.** Target signal is usually right-skewed, so a control's
mean sits above its median. Comparing a unit's median against the
control's *mean* is therefore silently stricter than the rule it claims
to apply. Because the gate can only ever drop *low* units, an
over-strict gate manufactures apparent treatment effects. Both verdicts
are computed for every unit — `fails_vs_median` and `fails_vs_mean` —
and the units whose verdict *depends* on that choice are returned in
`$disputed`. The default (`statistic = "median"`,
`reference = "median"`) is like for like.

**Leverage.** Excluding a unit changes the estimate it fed into.
Quantify that with
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md)
*before* calling
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
while both states are still in hand.

Gate the analysis unit, not the acquisition file: a unit assembled from
two files would otherwise be gated twice.

## See also

[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md).

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
gate <- cr_qc_gate(exp,
  channel = "marker_1",
  control_level = "Untreated",
  batch_vars = "replicate"
)
gate
#> 
#> ── QC gate ─────────────────────────────────────────────────────────────────────
#> Signal marker_1 vs "Untreated" of the same batch
#> Rule: unit median must be greater than the control median
#> • 96 units, 80 gated
#> • 2 fail vs the control median
#> • 13 fail vs the control mean
#> • 2 excluded under the chosen rule
#> ! 11 verdicts depend on which control centre is used.
head(gate$units[, c("well", "n_cells", "pct_of_control", "verdict")])
#> # A tibble: 6 × 4
#>   well  n_cells pct_of_control verdict
#>   <chr>   <int>          <dbl> <chr>  
#> 1 A01        36           476. control
#> 2 A02        48           104. control
#> 3 A03        47           655. pass   
#> 4 A04        37           961. pass   
#> 5 A05        43           172. pass   
#> 6 A06        43           189. pass   
gate$excluded
#> [1] "B09" "B11"
```
