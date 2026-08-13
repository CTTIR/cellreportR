# Build a `cr_experiment` object

Assembles a validated `cr_experiment` from its components. A
`cr_experiment` is the central S3 object in cellreportR and holds
per-cell measurements, experimental design, channel metadata, plate
information, a QC log and arbitrary user metadata.

## Usage

``` r
cr_build_experiment(
  cells,
  design = NULL,
  channels = NULL,
  plate_info = list(),
  metadata = list(),
  unit_var = NULL,
  batch_vars = NULL,
  provenance = NULL,
  set_aside = NULL,
  call = rlang::caller_env()
)
```

## Arguments

- cells:

  A data frame / tibble of per-cell measurements, or a
  [`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md).
  Must contain a `cell_id` column and a spatial unit column (`well`,
  `slide`, `well_id` or `unit`, or the column named by `unit_var`).

- design:

  A data frame / tibble that maps each spatial unit to treatment
  information, or a
  [`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md)
  object. Must contain the spatial unit column and a `treatment` column.
  Recommended columns: `dose`, `dose_unit`, `replicate`, `group`,
  `timepoint`. May be `NULL` when `cells` is a `cr_dataset` carrying a
  design.

- channels:

  Optional tibble describing marker channels. Columns: `channel`
  (required), `role`, `target`, `fluorophore`. If `NULL`, channels are
  auto-detected from numeric columns in `cells` that are not recognised
  as morphology fields.

- plate_info:

  Optional list with plate metadata (e.g. `format` = "96", `microscope`,
  `date`, `operator`).

- metadata:

  Optional list with arbitrary user metadata.

- unit_var:

  Optional name of the analysis unit column.

- batch_vars:

  Optional character vector of columns that together define a batch.

- provenance:

  Optional per-file provenance table.

- set_aside:

  Optional data frame or list of arms split out of the analysis pool.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

A `cr_experiment` object (an S3 list).

## Details

Three optional slots describe structure that a single design table
cannot: `unit_var` names the analysis unit when it is neither `well` nor
`slide` (a unit assembled from several files, for instance),
`batch_vars` names the *combination* of columns that defines a batch,
and `provenance` keeps the per-file record that lets any cell be traced
back to its acquisition. `set_aside` holds arms that were split out of
the analysis pool, such as a specificity control, so that they travel
with the experiment instead of being lost.

## See also

[`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md),
[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md),
[`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md).

Other constructors:
[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md),
[`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md),
[`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md)

## Examples

``` r
cells <- tibble::tibble(
  cell_id = sprintf("c%03d", 1:6),
  well = rep(c("A01", "A02"), each = 3),
  area = c(120, 130, 125, 118, 122, 131),
  target_signal = c(10, 12, 11, 30, 33, 29)
)
design <- tibble::tibble(
  well = c("A01", "A02"),
  treatment = c("Vehicle", "CompoundA"),
  plate = "Plate_1"
)
exp <- cr_build_experiment(cells, design, batch_vars = "plate")
exp
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 6 across 2 wells
#> • Channels: "target_signal"
#> • Design: 2 treatment groups
#> • QC steps applied: 0
```
