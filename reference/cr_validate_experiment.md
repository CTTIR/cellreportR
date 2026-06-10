# Validate a `cr_experiment`

Performs structural checks on a `cr_experiment`. Called automatically by
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md)
but can also be used to verify that manual modifications have not broken
the object.

## Usage

``` r
cr_validate_experiment(x)
```

## Arguments

- x:

  A `cr_experiment`.

## Value

`TRUE` invisibly on success. On failure an informative error is raised.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
cr_validate_experiment(exp)
```
