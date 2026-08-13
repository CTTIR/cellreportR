# Bundle a directory and file-name specification

A `cr_path_spec` holds everything needed to recover design facts from
where a file sits and what it is called: the meaning of each directory
level, the file-name grammar, the marker rules and whether an
unparseable name is an error.

## Usage

``` r
cr_path_spec(levels = NULL, grammar = NULL, markers = NULL, strict = TRUE)

# S3 method for class 'cr_path_spec'
print(x, ...)
```

## Arguments

- levels:

  Either an unnamed character vector naming the directory levels below
  the root in order (use `NA` or `""` to skip a level), or a named
  integer vector mapping column names to level indices, where negative
  indices count back from the file (`-1` is the directory containing the
  file).

- grammar:

  A
  [`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
  or `NULL`.

- markers:

  A
  [`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md)
  object, or `NULL`.

- strict:

  Logical. Treat a file name that does not match the grammar as an
  error. Default `TRUE`.

- x:

  A `cr_path_spec`.

- ...:

  Ignored.

## Value

An object of class `cr_path_spec` (a list).

`x`, invisibly.

## See also

[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md),
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md),
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
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
spec <- cr_path_spec(
  levels = c(run = 1L, compound = 2L, plate = -1L),
  grammar = cr_filename_grammar(
    tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM")
  ),
  markers = cr_marker_rules(merge_unit = "\\(split\\)")
)
spec
#> <cr_path_spec>
#> • levels: run[1] / compound[2] / plate[-1]
#> • grammar tokens: interval, dose
#> • markers: set
#> • strict: TRUE
```
