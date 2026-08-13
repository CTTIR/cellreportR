# Read a QuPath measurement export

Read a QuPath measurement export

## Usage

``` r
cr_read_qupath(path)
```

## Arguments

- path:

  Path to QuPath TSV.

## Value

A tibble with standardised column names.

## See also

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
[`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md),
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)

## Examples

``` r
f <- tempfile(fileext = ".tsv")
writeLines(
  c("Image\tCentroid X um\tCentroid Y um\tArea um^2\tCell: marker_1 mean",
    "A01.ome.tif\t10\t12\t120\t0.44",
    "A01.ome.tif\t30\t42\t118\t0.51"),
  f
)
cr_read_qupath(f)
#> # A tibble: 2 × 6
#>   cell_id well      x     y  area marker_1
#>   <chr>   <chr> <dbl> <dbl> <dbl>    <dbl>
#> 1 c000001 A01      10    12   120     0.44
#> 2 c000002 A01      30    42   118     0.51
```
