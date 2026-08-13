# Extract file-name markers into typed flags

Applies a
[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md)
set to a table that carries a file-name column, adding one logical
column per rule plus a character `variant` column holding any unmatched
trailing parenthetical.

## Usage

``` r
cr_extract_markers(
  x,
  name_col = "source_file",
  container_col = NULL,
  rules = cr_marker_rules(),
  stem_col = NULL,
  strip_ext = TRUE,
  call = rlang::caller_env()
)
```

## Arguments

- x:

  A data frame with one row per file (or per cell).

- name_col:

  Name of the column holding the file name. Default `"source_file"`.

- container_col:

  Optional name of the column holding the container (plate or directory)
  name that `partial_plate` is matched against.

- rules:

  A
  [`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md)
  object.

- stem_col:

  Optional name of a column to write the marker-stripped name into.

- strip_ext:

  Logical. Remove a trailing file extension before matching. Default
  `TRUE`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

`x` with the columns `merge_unit`, `partial_plate`, `omitted_reagent`,
`reacquisition`, `lot` (all logical) and `variant` (character) added.
Columns for rules that were not supplied are `FALSE` throughout.

## See also

[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md),
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
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
  source_file = c("CompoundA_10uM_treated_1.csv",
                  "CompoundA_10uM_treated_1.1 (split).csv",
                  "CompoundA_vehicle_1 (no reagent).csv",
                  "CompoundA_vehicle_2 (weekend).csv"),
  plate = c("Plate_1", "Plate_1", "Plate_1", "Plate_2 (partial)")
)
cr_extract_markers(
  files,
  container_col = "plate",
  rules = cr_marker_rules(merge_unit = "\\(split\\)",
                          partial_plate = "\\(partial\\)",
                          omitted_reagent = "\\(no reagent\\)")
)
#> # A tibble: 4 × 8
#>   source_file plate merge_unit partial_plate omitted_reagent reacquisition lot  
#>   <chr>       <chr> <lgl>      <lgl>         <lgl>           <lgl>         <lgl>
#> 1 CompoundA_… Plat… FALSE      FALSE         FALSE           FALSE         FALSE
#> 2 CompoundA_… Plat… TRUE       FALSE         FALSE           FALSE         FALSE
#> 3 CompoundA_… Plat… FALSE      FALSE         TRUE            FALSE         FALSE
#> 4 CompoundA_… Plat… FALSE      TRUE          FALSE           FALSE         FALSE
#> # ℹ 1 more variable: variant <chr>
```
