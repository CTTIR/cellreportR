# Read a directory tree of segmented single-cell exports

Walks a directory recursively, reads every file matching `pattern` with
[`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md)
and row-binds the result. Design facts that live in the directory layout
and in the file names — rather than inside the files — are recovered by
a parser and joined back onto the cells.

## Usage

``` r
cr_read_exports(
  root,
  pattern = "\\.(csv|tsv|xls|xlsx)$",
  column_map = NULL,
  spec = NULL,
  parser = NULL,
  recursive = TRUE,
  drop_empty_rows = TRUE,
  col_types = NULL,
  progress = TRUE,
  call = rlang::caller_env()
)
```

## Arguments

- root:

  Directory to walk.

- pattern:

  Regular expression selecting export files. Default matches `.csv`,
  `.tsv`, `.xls` and `.xlsx`.

- column_map:

  Optional
  [`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
  applied to every export.

- spec:

  Optional
  [`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md)
  describing the directory and file-name grammar. Ignored when `parser`
  is supplied.

- parser:

  Optional function of the file paths returning a tibble with one row
  per path.

- recursive:

  Logical. Walk sub-directories. Default `TRUE`.

- drop_empty_rows:

  Logical. Passed to
  [`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md).

- col_types:

  Optional column-type specification passed to
  [`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md).

- progress:

  Logical. Show a progress bar while reading. Default `TRUE`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

A tibble of all cells, with `source_file` and `source_path` provenance
columns and any columns produced by the parser. The paths that were read
are attached as the `"files"` attribute.

## Details

No naming convention is hardcoded. Either supply a
[`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md)
via `spec`, which is handed to
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
or supply an arbitrary `parser` function. A parser receives the
character vector of file paths and must return one row per path; if it
returns a `source_path` column the join is made on that column,
otherwise row order is assumed to match.

Row-binding is tolerant of exports that carry different subsets of the
available columns: absent columns are filled with `NA`.

## See also

[`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md),
[`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md),
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md).

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
[`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md),
[`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md),
[`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md)

## Examples

``` r
# Build a small two-file export tree.
root <- file.path(tempdir(), "cr_exports_demo")
unlink(root, recursive = TRUE)
leaf <- file.path(root, "Run1", "CompoundA", "Plate_1")
dir.create(leaf, recursive = TRUE, showWarnings = FALSE)
one <- function(n) {
  data.frame("Event Label" = seq_len(n),
             "Signal - Mean Intensity" = seq_len(n) * 10,
             check.names = FALSE)
}
utils::write.csv(one(3), file.path(leaf, "CompoundA_vehicle_1.csv"),
                 row.names = FALSE)
utils::write.csv(one(4), file.path(leaf, "CompoundA_5min_10uM_treated_1.csv"),
                 row.names = FALSE)

spec <- cr_path_spec(
  levels = c("run", "compound", "plate"),
  grammar = cr_filename_grammar(
    tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM"),
    defaults = list(interval = "none", dose = "vehicle"),
    prefix_strip = "CompoundA"
  )
)
cells <- cr_read_exports(root, spec = spec, progress = FALSE)
cells
#> # A tibble: 7 × 19
#>   source_file    source_path `Event Label` Signal - Mean Intens…¹ run   compound
#>   <chr>          <chr>               <dbl>                  <dbl> <chr> <chr>   
#> 1 CompoundA_5mi… /tmp/RtmpD…             1                     10 Run1  Compoun…
#> 2 CompoundA_5mi… /tmp/RtmpD…             2                     20 Run1  Compoun…
#> 3 CompoundA_5mi… /tmp/RtmpD…             3                     30 Run1  Compoun…
#> 4 CompoundA_5mi… /tmp/RtmpD…             4                     40 Run1  Compoun…
#> 5 CompoundA_veh… /tmp/RtmpD…             1                     10 Run1  Compoun…
#> 6 CompoundA_veh… /tmp/RtmpD…             2                     20 Run1  Compoun…
#> 7 CompoundA_veh… /tmp/RtmpD…             3                     30 Run1  Compoun…
#> # ℹ abbreviated name: ¹​`Signal - Mean Intensity`
#> # ℹ 13 more variables: plate <chr>, merge_unit <lgl>, partial_plate <lgl>,
#> #   omitted_reagent <lgl>, reacquisition <lgl>, lot <lgl>, variant <chr>,
#> #   core <chr>, replicate <chr>, interval <chr>, dose <chr>, parse_ok <lgl>,
#> #   parse_error <chr>
```
