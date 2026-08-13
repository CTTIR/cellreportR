# Map source files to analysis units

Summarises which file contributed how many cells to which unit, and
flags the units that were assembled from more than one file. This is the
post-condition check for
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md):
a unit built from several files should be one you can name and justify.

## Usage

``` r
cr_unit_map(
  x,
  id_col = "well_id",
  file_col = "source_path",
  call = rlang::caller_env()
)
```

## Arguments

- x:

  A cell table carrying a unit identifier and a file column, as returned
  by
  [`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md).

- id_col:

  Name of the unit identifier column. Default `"well_id"`.

- file_col:

  Name of the file column. Default `"source_path"`; the path rather than
  the base name, because base names repeat across plates.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

A tibble with one row per file: the unit identifier, the file,
`n_cells`, `n_files` (files contributing to that unit) and `merged`
(`TRUE` when `n_files > 1`).

## See also

[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md),
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md),
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
[`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md),
[`cr_read_cellprofiler()`](https://cttir.github.io/cellreportR/reference/cr_read_cellprofiler.md),
[`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md),
[`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md),
[`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md),
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md),
[`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md),
[`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md)

## Examples

``` r
cells <- tibble::tibble(
  source_path = rep(c("a.csv", "b.csv", "c.csv"), times = c(3, 2, 4)),
  compound = "CompoundA",
  replicate = rep(c("1", "1.1", "2"), times = c(3, 2, 4)),
  merge_unit = rep(c(FALSE, TRUE, FALSE), times = c(3, 2, 4))
)
units <- cr_assign_units(cells, key_vars = "compound")
cr_unit_map(units)
#> # A tibble: 3 × 5
#>   well_id     source_path n_cells n_files merged
#>   <chr>       <chr>         <int>   <int> <lgl> 
#> 1 CompoundA|1 a.csv             3       2 TRUE  
#> 2 CompoundA|1 b.csv             2       2 TRUE  
#> 3 CompoundA|2 c.csv             4       1 FALSE 
```
