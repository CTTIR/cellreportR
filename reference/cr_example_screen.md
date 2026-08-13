# Generate a synthetic multi-compound screen

Simulates a screen of up to ten compounds, each acquired at four
exposure levels and two pre-treatment intervals, on two plates and in
two experiments. Unlike
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md)
the analysis unit is not the raw plate well: units carry file
provenance, some are assembled from more than one acquisition, and one
arm is set aside instead of screened.

## Usage

``` r
cr_example_screen(
  seed = 42,
  n_compounds = 10,
  n_cells_per_well = 40,
  n_units_per_arm = 3,
  n_experiments = 2
)
```

## Arguments

- seed:

  Random seed. `NULL` uses the current RNG state.

- n_compounds:

  Number of compounds, 1 to 10. They are named `CompoundA` to
  `CompoundJ`.

- n_cells_per_well:

  Mean number of cells per unit (Poisson, with a floor of ten).

- n_units_per_arm:

  Units per compound, experiment, interval and exposure level. Three or
  more is needed for the effect-size grid.

- n_experiments:

  Number of experiments, 1 or 2.

## Value

A `cr_experiment` with

- `cells`:

  one row per cell: `cell_id`, `well_id`, `source_file`, `source_path`,
  `x`, `y`, `area`, `circularity`, `nuclear_signal`, `target_signal`.

- `design`:

  one row per unit: `well_id`, `compound`, `experiment`, `plate`,
  `well`, `interval`, `dose`, `dose_unit`, `treatment`, `group`,
  `replicate`.

- `provenance`:

  one row per acquisition file, with marker flags and the number of
  files each unit was assembled from.

- `set_aside`:

  a list whose `reagent_omitted` element holds the specificity arm.

`unit_var` is `"well_id"` and `batch_vars` is
`c("compound", "experiment", "plate", "interval")`.

## Details

Everything the screening functions need is present: a vehicle control
inside every batch for
[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md)
and
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md),
one unit that fails a control-referenced gate for
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
enough units per arm for
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md),
plates crossed with arms for
[`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md),
and a reagent-omitted arm in `set_aside`.

## Generating model

A batch is the combination of `compound`, `experiment`, `plate` and
`interval`. Writing \\p_c\\ for the potency of compound \\c\\, \\d\\ for
the exposure level and \\u_w\\ for the unit intercept:

- potency:

  \\p_c\\ runs from `1.6` down to `0.1` in equal steps from `CompoundA`
  to the last compound, so the rank order of the screen is known in
  advance and the top hit is a hit by construction rather than by
  chance.

- exposure:

  The response saturates in dose as \\d / (d + 40)\\, so the four
  exposure levels are not equally spaced in effect.

- interval:

  The longer pre-treatment interval multiplies the effect by `1.15`.

- effect:

  \\e = p_c \cdot d/(d + 40) \cdot g\_{interval}\\, in log2 units
  against the vehicle of the same batch.

- unit intercept:

  \\u_w \sim N(0, 0.12^2)\\ on the log scale, one draw per unit.

- acquisition offsets:

  The second experiment has a `1.35` times higher raw baseline and the
  second plate a `1.08` times higher one. Both act on control and
  treated units alike, which is what standardising against the control
  of a unit's own batch removes, and why raw signal is not comparable
  across experiments.

- target signal:

  \\\mathrm{LogNormal}(\log(400 \cdot g\_{exp} \cdot g\_{plate}) + u_w +
  e \log 2,\\ 0.45^2)\\.

- nuclear signal:

  \\\mathrm{LogNormal}(\log 600 + u_w,\\ 0.3^2)\\, with no treatment
  effect.

- morphology:

  Nuclear `area` is \\\mathrm{LogNormal}(\log 180,\\ 0.3^2)\\ and
  `circularity` is \\\mathrm{Beta}(6, 2)\\. Four per cent of objects are
  shrunk to an eighth of their area, the sub-threshold debris that
  [`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md)
  is meant to drop.

## Planted edge cases

- gate failure:

  One treated unit of the first compound is given a negative effect, so
  it sits below the control of its own batch and fails a
  control-referenced gate.

- two-pass acquisition:

  One unit's cells are split across two files, the second carrying a
  `(split)` marker and a `.1` replicate suffix. Left unmerged it would
  count twice.

- repeated read:

  One unit's cells are split across a file and its `(repeat)` sibling,
  which has to merge into it.

- look-alike suffix:

  One separate unit is named with a `.2` replicate suffix, which must
  *not* merge with the unit named `2`: it is a different physical unit
  on a different plate.

- arm outside the screen:

  A reagent-omitted arm is generated and placed in `set_aside` rather
  than in the analysis pool.

The random number generator state of the caller is restored on exit.

## See also

[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md),
[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md),
[`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md).

Other example data:
[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md),
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md)

## Examples

``` r
screen <- cr_example_screen(seed = 1, n_compounds = 3,
                            n_cells_per_well = 12)
screen
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 1822 across 144 well_ids
#> • Channels: "nuclear_signal" and "target_signal"
#> • Design: 4 treatment groups
#> • QC steps applied: 0
#> ℹ Metadata fields: project, design, and control_level
table(screen$design$compound, screen$design$treatment)
#>            
#>             Dose_10 Dose_250 Dose_50 Vehicle
#>   CompoundA      12       12      12      12
#>   CompoundB      12       12      12      12
#>   CompoundC      12       12      12      12

# Units assembled from more than one acquisition file
prov <- screen$provenance
unique(prov$well_id[prov$n_files > 1])
#> [1] "CompoundA_Exp_1_Plate_1_D01" "CompoundA_Exp_1_Plate_2_D02"
```
