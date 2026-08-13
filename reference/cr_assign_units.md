# Assign cells to analysis units

Derives the identifier of the analysis unit — the spatial unit that is
the unit of replication — for every row of a cell table, merging the
files that belong to the same unit according to a
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md)
set.

## Usage

``` r
cr_assign_units(
  x,
  key_vars,
  replicate_var = "replicate",
  rules = cr_merge_rules(),
  id_col = "well_id",
  sep = "|",
  call = rlang::caller_env()
)
```

## Arguments

- x:

  A data frame of cells (or of files) carrying the design columns and a
  replicate index.

- key_vars:

  Character vector of column names that, together with the replicate
  index, identify one unit.

- replicate_var:

  Name of the replicate index column. Default `"replicate"`.

- rules:

  A
  [`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md)
  object.

- id_col:

  Name of the unit identifier column to add. Default `"well_id"`.

- sep:

  Separator used to build the identifier. Default `"|"`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

`x` with two columns added: `replicate_merged` (the replicate index
after merging) and the unit identifier named by `id_col`. The number of
units is attached as the `"n_units"` attribute.

## Details

The unit identifier is the combination of `key_vars` and the merged
replicate index. Files that share it are one unit; files that do not are
separate replicates. Because a unit may be assembled from more than one
file,
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)
should be used afterwards to see which units were merged and from how
many files.

## See also

[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md),
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md).

Other import:
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
[`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md),
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)

## Examples

``` r
files <- tibble::tibble(
  compound = "CompoundA",
  plate = "Plate_1",
  mode = "treated",
  replicate = c("1", "1.1", "2", "2.2"),
  merge_unit = c(FALSE, TRUE, FALSE, FALSE),
  reacquisition = FALSE
)
units <- cr_assign_units(files, key_vars = c("compound", "plate", "mode"))
units[, c("replicate", "replicate_merged", "well_id")]
#> # A tibble: 4 × 3
#>   replicate replicate_merged well_id                      
#>   <chr>     <chr>            <chr>                        
#> 1 1         1                CompoundA|Plate_1|treated|1  
#> 2 1.1       1                CompoundA|Plate_1|treated|1  
#> 3 2         2                CompoundA|Plate_1|treated|2  
#> 4 2.2       2.2              CompoundA|Plate_1|treated|2.2
```
