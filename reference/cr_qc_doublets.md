# Flag or remove doublets

Flags cells whose area is far above the population median, which in
microscopy typically indicates segmented doublets. The cells are removed
and recorded in the QC log.

## Usage

``` r
cr_qc_doublets(experiment, channel = NULL, threshold_method = "area", k = 2.5)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Unused in the default method but kept for API symmetry; future
  implementations may use DNA content.

- threshold_method:

  Currently only `"area"` is supported.

- k:

  Multiplicative threshold: cells with area \> `k * median` are removed.
  Default `2.5`.

## Value

A modified `cr_experiment`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
cr_qc_doublets(exp, threshold_method = "area")
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 2910 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
