# Validate a `cr_experiment`

Performs structural checks on a `cr_experiment`. Called automatically by
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md)
but can also be used to verify that manual modifications have not broken
the object.

## Usage

``` r
cr_validate_experiment(x, call = rlang::caller_env())
```

## Arguments

- x:

  A `cr_experiment`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

`TRUE` invisibly on success. On failure an informative error is raised.

## Details

The optional `unit_var`, `batch_vars`, `provenance` and `set_aside`
slots are checked only when they are present, so that objects built by
earlier versions still validate.

## See also

[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md).

Other constructors:
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md),
[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md),
[`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md)

## Examples

``` r
cells <- tibble::tibble(
  cell_id = c("c1", "c2"), well = c("A01", "A02"),
  target_signal = c(10, 20)
)
design <- tibble::tibble(well = c("A01", "A02"),
                         treatment = c("Vehicle", "CompoundA"))
cr_validate_experiment(cr_build_experiment(cells, design))
```
