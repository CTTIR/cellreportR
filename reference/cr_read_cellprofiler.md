# Read a CellProfiler object export

Imports a CellProfiler CSV export and renames the columns to the
cellreportR convention (`well`, `x`, `y`, `area`, `circularity`, one
column per marker channel).

## Usage

``` r
cr_read_cellprofiler(path)
```

## Arguments

- path:

  Path to CellProfiler CSV.

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
[`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md),
[`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md),
[`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md),
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md),
[`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md),
[`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md),
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)

## Examples

``` r
f <- tempfile(fileext = ".csv")
utils::write.csv(
  data.frame(
    Metadata_Well = c("A01", "A01"),
    Location_Center_X = c(10, 20),
    Location_Center_Y = c(15, 25),
    AreaShape_Area = c(120, 130),
    Intensity_MeanIntensity_marker_1 = c(0.4, 0.6)
  ),
  f, row.names = FALSE
)
cr_read_cellprofiler(f)
#> # A tibble: 2 × 6
#>   cell_id well      x     y  area marker_1
#>   <chr>   <chr> <dbl> <dbl> <dbl>    <dbl>
#> 1 c000001 A01      10    15   120      0.4
#> 2 c000002 A01      20    25   130      0.6
```
