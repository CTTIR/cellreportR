# Build a `cr_experiment` object

Assembles a validated `cr_experiment` from its components. A
`cr_experiment` is the central S3 object in cellreportR and holds
per-cell measurements, experimental design, channel metadata, plate
information, a QC log and arbitrary user metadata.

## Usage

``` r
cr_build_experiment(
  cells,
  design,
  channels = NULL,
  plate_info = list(),
  metadata = list()
)
```

## Arguments

- cells:

  A data frame / tibble of per-cell measurements. Must contain a
  `cell_id` column and a spatial unit column (either `well` or `slide`).

- design:

  A data frame / tibble that maps each spatial unit to treatment
  information. Must contain the spatial unit column and a `treatment`
  column. Recommended columns: `dose`, `dose_unit`, `replicate`,
  `group`, `timepoint`.

- channels:

  Optional tibble describing fluorescence channels. Columns: `channel`
  (required), `role`, `antibody`, `fluorophore`. If `NULL`, channels are
  auto-detected from numeric columns in `cells` that are not recognised
  as morphology fields.

- plate_info:

  Optional list with plate metadata (e.g. `format` = "96", `microscope`,
  `date`, `operator`).

- metadata:

  Optional list with arbitrary user metadata.

## Value

A `cr_experiment` object (an S3 list).

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
print(exp)
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 1961 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project and sop
```
