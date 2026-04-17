# Generate a synthetic `cr_experiment`

Creates a realistic synthetic cell-culture microscopy data set for
demonstration and testing. The simulated experiment has six treatment
groups, four replicates per group and 96 wells in total. Four
fluorescence channels are generated: a nuclear stain (`DAPI`), a damage
marker (`marker_1`), a viability marker (`marker_2`) and a secondary
readout (`marker_3`).

## Usage

``` r
cr_example_experiment(
  seed = 42,
  n_cells_per_well = 150,
  n_wells_per_replicate = 4
)
```

## Arguments

- seed:

  Random seed.

- n_cells_per_well:

  Mean number of cells per well (Poisson).

- n_wells_per_replicate:

  Number of wells per replicate.

## Value

A `cr_experiment`.

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
