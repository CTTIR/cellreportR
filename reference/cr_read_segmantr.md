# Read a segmantR result

Imports an RDS file produced by the `segmantR` segmentation package.
Accepts either a `segmantr_result` list (where cells are in `$cells`) or
a plain data frame.

## Usage

``` r
cr_read_segmantr(path)
```

## Arguments

- path:

  Path to RDS file.

## Value

A tibble of cells.

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
[`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md),
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)

## Examples

``` r
f <- tempfile(fileext = ".rds")
saveRDS(data.frame(cell_id = "c1", well = "A01", target_signal = 12), f)
cr_read_segmantr(f)
#> # A tibble: 1 × 3
#>   cell_id well  target_signal
#>   <chr>   <chr>         <dbl>
#> 1 c1      A01              12
```
