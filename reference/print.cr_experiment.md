# Print method for `cr_experiment`

Print method for `cr_experiment`

## Usage

``` r
# S3 method for class 'cr_experiment'
print(x, ...)
```

## Arguments

- x:

  A `cr_experiment`.

- ...:

  Unused.

## Value

`x` invisibly.

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
