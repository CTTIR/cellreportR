# Filter cells in a `cr_experiment`

A thin wrapper around
[`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html)
applied to the `cells` slot. Filtering is additive: rows excluded here
are removed from the returned experiment and logged in `qc_log`.

## Usage

``` r
cr_filter_cells(experiment, ...)
```

## Arguments

- experiment:

  A `cr_experiment`.

- ...:

  Filtering expressions passed on to
  [`dplyr::filter()`](https://dplyr.tidyverse.org/reference/filter.html).

## Value

A modified `cr_experiment`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
cr_filter_cells(exp, area > 50)
#> ── cr_experiment ───────────────────────────────────────────────────────────────
#> • Cells: 1026 across 96 wells
#> • Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
#> • Design: 6 treatment groups
#> • QC steps applied: 1
#> ℹ Metadata fields: project and sop
```
