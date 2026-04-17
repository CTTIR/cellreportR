# Write example files in multiple formats to a directory

Writes the example cells and design tables in several on-disk formats to
demonstrate the `cr_read_*` importers.

## Usage

``` r
cr_example_files(dir = tempdir(), seed = 42)
```

## Arguments

- dir:

  Directory to write into. Must exist.

- seed:

  Seed passed to
  [`cr_example_experiment()`](https://r-heller.github.io/cellreportR/reference/cr_example_experiment.md).

## Value

A character vector of written file paths (invisibly).

## Examples

``` r
d <- tempfile("cr_example_"); dir.create(d)
cr_example_files(d)
```
