# Read one segmented single-cell export

Reads a single export file (`.csv`, `.tsv`, `.txt`, `.xls` or `.xlsx`),
applies an optional column contract and prepends the file's provenance.

## Usage

``` r
cr_read_export(
  path,
  column_map = NULL,
  drop_empty_rows = TRUE,
  col_types = NULL,
  sheet = 1L,
  call = rlang::caller_env()
)
```

## Arguments

- path:

  Path to the export file.

- column_map:

  Optional
  [`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
  describing how raw headers translate to analysis names.

- drop_empty_rows:

  Logical. Drop rows that are `NA` in every measurement column. Default
  `TRUE`.

- col_types:

  Optional column-type specification passed to the underlying reader (a
  `readr` column specification for delimited files, a `readxl` type
  string such as `"numeric"` for Excel files).

- sheet:

  Sheet name or index for Excel exports. Default `1`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

A tibble of cells with `source_file` and `source_path` as the first two
columns.

## Details

Provenance is not optional in this reader. One export is one acquisition
of one spatial unit, and export base names repeat across plates, so the
*path* — not the file name — identifies the acquisition. Both are
carried on every row as `source_file` and `source_path`, and both
survive into the analysis unit assignment performed by
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md).

Many instruments terminate an export with a single all-blank row. With
`drop_empty_rows = TRUE` (the default) such rows are removed rather than
carried into the analysis as an all-`NA` cell.

## See also

[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md)
for a whole directory tree,
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md).

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
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md),
[`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md),
[`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md),
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)

## Examples

``` r
d <- file.path(tempdir(), "cr_export_demo")
dir.create(d, showWarnings = FALSE)
raw <- data.frame(
  "Event Label" = 1:3,
  "Signal - Mean Intensity" = c(120, 140, 95),
  check.names = FALSE
)
raw[4, ] <- NA # trailing blank row, as many instruments write
f <- file.path(d, "CompoundA_5min_10uM_treated_1.csv")
utils::write.csv(raw, f, row.names = FALSE)

map <- cr_column_map(
  exact = c("Event Label" = "cell_id",
            "Signal - Mean Intensity" = "target_signal")
)
cr_read_export(f, column_map = map)
#> # A tibble: 3 × 4
#>   source_file                       source_path            cell_id target_signal
#>   <chr>                             <chr>                    <dbl>         <dbl>
#> 1 CompoundA_5min_10uM_treated_1.csv /tmp/RtmpDtL8CM/cr_ex…       1           120
#> 2 CompoundA_5min_10uM_treated_1.csv /tmp/RtmpDtL8CM/cr_ex…       2           140
#> 3 CompoundA_5min_10uM_treated_1.csv /tmp/RtmpDtL8CM/cr_ex…       3            95
```
