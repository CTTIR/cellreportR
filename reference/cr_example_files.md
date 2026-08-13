# Write example files in several on-disk formats

Writes the tables behind
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md)
in the layouts the `cr_read_*` importers understand, so that the import
functions can be demonstrated on real files without any being shipped.

## Usage

``` r
cr_example_files(dir = tempdir(), seed = 42)
```

## Arguments

- dir:

  Directory to write into. Created when it does not exist.

- seed:

  Seed passed to
  [`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md).

## Value

A character vector of the written file paths, invisibly.

## See also

[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md)
for a nested export tree with the design encoded in the paths,
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md)
for the files shipped inside the package.

Other example data:
[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md),
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)

## Examples

``` r
d <- file.path(tempdir(), "cr_example_files")
files <- cr_example_files(d, seed = 1)
basename(files)
#> [1] "cells.csv"              "design.xlsx"            "cells_cellprofiler.csv"
#> [4] "cells_qupath.tsv"      
```
