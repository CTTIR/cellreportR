# Generate a synthetic `cr_experiment`

Simulates a compact demonstration experiment: one 96-unit plate format,
six treatment levels, four exposure levels, two plates and two
pre-treatment intervals. It is small enough that every example in the
package can build a fresh copy in well under a second, and structured
enough that the batch, quality-control and effect-size functions all
have something to work on.

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

  Random seed. `NULL` uses the current RNG state.

- n_cells_per_well:

  Mean number of cells per unit (Poisson, with a floor of ten).

- n_wells_per_replicate:

  Number of units per replicate.

## Value

A `cr_experiment` whose `cells` table holds one row per cell (`cell_id`,
`well`, `x`, `y`, `area`, `circularity`, `DAPI`, `marker_1`, `marker_2`,
`marker_3`) and whose `design` table holds one row per unit, as
described in
[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md).

## Details

Use
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)
instead when a multi-compound screen with per-batch controls, merged
analysis units and a specificity arm is needed.

## Generating model

Values are drawn independently per cell from log-normal distributions,
so that the marker channels are right-skewed the way measured
intensities are:

- unit intercept:

  Each unit draws \\u \sim N(0, 0.15^2)\\, added to the log mean of
  every channel in that unit. This is what makes the unit, and not the
  cell, the honest replicate.

- target signal:

  `marker_1` is \\\mathrm{LogNormal}(\log 500 + u + e \log 2,\\
  0.5^2)\\, where \\e\\ is the treatment effect in log2 units: `0`
  untreated, `1.0` and `3.0` for the low and high exposure level of
  `CompoundA`, `3.3` for the positive control, `0.4` for `CompoundB` and
  `0.7` for `CompoundC`.

- further channels:

  `marker_2` moves against the target signal at \\-0.4e\\, `marker_3`
  weakly with it at \\0.3e\\.

- nuclear stain:

  `DAPI` is \\\mathrm{LogNormal}(\log 500 + u,\\ 0.3^2)\\ and carries no
  treatment effect.

- morphology:

  Nuclear `area` is \\\mathrm{LogNormal}(\log 400,\\ 0.25^2)\\ and
  `circularity` is \\\mathrm{Beta}(5, 2)\\.

- plate position:

  Units on the outer rows and columns get a fixed `+0.07` log bump on
  every channel, an edge effect for the plate map to show.

- debris:

  Five per cent of the cells of each unit are shrunk to a twentieth of
  their area and a tenth of their nuclear signal, so that the
  quality-control filters have something to remove.

- artefacts:

  Two named units are multiplied up on `marker_1` and down on `area`, a
  saturated pair for the outlier screens.

The random number generator state of the caller is restored on exit, so
calling this function does not disturb a seeded analysis.

## See also

[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md).

Other example data:
[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md),
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
exp
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 1961 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project and sop
head(exp$design, 3)
#> # A tibble: 3 × 9
#>   well  treatment  dose dose_unit group   replicate plate   interval timepoint
#>   <chr> <chr>     <dbl> <chr>     <chr>       <int> <chr>   <chr>        <dbl>
#> 1 A01   Untreated     0 uM        control         1 Plate_1 15min           24
#> 2 B01   Untreated     0 uM        control         1 Plate_1 15min           24
#> 3 C01   Untreated     0 uM        control         1 Plate_2 15min           24
```
