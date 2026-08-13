# Generate an example experimental design

Builds the unit-level design table used by
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md).
Six treatment levels are crossed with two plates and two pre-treatment
intervals, so that a batch is the *combination* of plate and interval
rather than a single column and every batch still contains untreated
units to standardise against.

## Usage

``` r
cr_example_design(plate_format = 96, n_wells_per_replicate = 4)
```

## Arguments

- plate_format:

  Either `96` or `384`.

- n_wells_per_replicate:

  Number of units per replicate per treatment level.

## Value

A tibble with one row per unit and the columns `well`, `treatment`,
`dose`, `dose_unit`, `group`, `replicate`, `plate`, `interval` and
`timepoint`.

## Details

Treatment names are deliberately abstract. `Untreated` is the vehicle
level, `PosControl` a positive control, and `CompoundA` appears at a low
and a high exposure level so that a dose axis exists; `CompoundB` and
`CompoundC` are further compounds at the low exposure level. The four
distinct values of `dose` are the four exposure levels of the
demonstration assay.

## See also

[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md).

Other example data:
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md),
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)

## Examples

``` r
design <- cr_example_design(96)
table(design$treatment, design$interval)
#>                 
#>                  15min 60min
#>   CompoundA_high     8     8
#>   CompoundA_low      8     8
#>   CompoundB          8     8
#>   CompoundC          8     8
#>   PosControl         8     8
#>   Untreated          8     8
```
