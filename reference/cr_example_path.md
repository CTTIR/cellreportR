# Locate the example files shipped with the package

Three tiny synthetic files are installed under `extdata` so that
examples, tests and vignettes can read a real file without writing one
first and without depending on any gated data.

## Usage

``` r
cr_example_path(file = NULL)
```

## Arguments

- file:

  Name of one shipped file, or `NULL` (the default) to return them all.

## Value

A character vector of absolute paths; length one when `file` is given.

## Details

- `example-export.csv`:

  One acquisition of one unit as a vendor export: raw instrument
  headers, an all-blank trailing row of the kind many instruments write,
  and a header carrying a unit glyph, which is what the prefix matching
  of
  [`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
  exists for.

- `example-export.xlsx`:

  The same acquisition as a workbook.

- `example-design.csv`:

  The unit-level design table covering the units in the exports.

The two exports are the treated acquisition that
`cr_example_exports(seed = 42, n_cells = 20)` writes, so the shipped
files can be regenerated at any time rather than being opaque binaries.

## See also

[`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md),
[`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md).

Other example data:
[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_exports()`](https://cttir.github.io/cellreportR/reference/cr_example_exports.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)

## Examples

``` r
basename(cr_example_path())
#> [1] "example-design.csv"  "example-export.csv"  "example-export.xlsx"

cells <- cr_read_export(cr_example_path("example-export.csv"))
head(cells, 3)
#> # A tibble: 3 × 8
#>   source_file      source_path `Event Label` `Position X [px]` `Position Y [px]`
#>   <chr>            <chr>       <chr>                     <dbl>             <dbl>
#> 1 example-export.… /home/runn… E0001                     1402.             1377.
#> 2 example-export.… /home/runn… E0002                      826.             1294.
#> 3 example-export.… /home/runn… E0003                      903.              476.
#> # ℹ 3 more variables: `Nuclei - Area [µm²]` <dbl>,
#> #   `Nuclei - Signal Mean` <dbl>, `Target - Signal Mean` <dbl>
```
