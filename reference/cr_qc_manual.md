# Manually exclude wells or cells

Removes entire wells/slides and/or specific cell IDs (for example
contaminated wells or cells with focus issues).

## Usage

``` r
cr_qc_manual(experiment, well = NULL, cell_ids = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- well:

  Character vector of well / slide identifiers to remove. Default
  `NULL`.

- cell_ids:

  Character vector of cell IDs to remove.

## Value

A modified `cr_experiment`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
cr_qc_manual(exp, well = c("A01", "H12"))
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 1914 across 94 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
