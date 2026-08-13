# Declare how files are merged into analysis units

States which replicate suffixes and marker flags mean "these files are
one unit" and which mean "these files are different units". Getting this
wrong is silent in both directions, so each rule is explicit.

## Usage

``` r
cr_merge_rules(
  merge_suffix = "\\.1$",
  merge_marker = "merge_unit",
  keep_separate = "\\.2$",
  reacquisition = "reacquisition",
  merge_reacquisition = TRUE,
  separate_suffix = "re"
)

# S3 method for class 'cr_merge_rules'
print(x, ...)
```

## Arguments

- merge_suffix:

  Regular expression matched against the replicate index, marking a
  second acquisition pass. `NULL` disables.

- merge_marker:

  Name of a logical column that must be `TRUE` for a `merge_suffix`
  match to merge, or `NULL` to merge on the suffix alone. When the
  column is absent no suffix merging happens.

- keep_separate:

  Regular expression matched against the replicate index, marking
  indices that must never merge. `NULL` disables.

- reacquisition:

  Name of a logical column marking repeated reads, or `NULL`.

- merge_reacquisition:

  Logical. Fold repeated reads into their plain sibling. Default `TRUE`.

- separate_suffix:

  Suffix appended to the replicate index of a repeated read when
  `merge_reacquisition = FALSE`. Default `"re"`.

- x:

  A `cr_merge_rules`.

- ...:

  Ignored.

## Value

An object of class `cr_merge_rules` (a list).

`x`, invisibly.

## Details

- `merge_suffix` matches the replicate index of a file that is the
  *second pass* over a unit that already exists. Left unmerged, such a
  unit draws a full cell allocation twice and is double-weighted in its
  own batch.

- `merge_marker` names a logical column (typically produced by
  [`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md))
  that must also be `TRUE` before a suffix match is merged. Requiring
  the marker is the conservative default: a suffix on its own is not
  evidence.

- `keep_separate` matches replicate indices that look mergeable but are
  a different physical unit. It always wins over `merge_suffix`.
  [`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md)
  is the evidence test for deciding which of the two a given suffix is.

- `reacquisition` names the logical column marking a repeated read. With
  `merge_reacquisition = TRUE` such a file folds into its plain sibling;
  otherwise `separate_suffix` is appended so it stays a unit of its own.

## See also

[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md),
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
cr_merge_rules()
#> <cr_merge_rules>
#> • merge suffix: "\\.1$"
#> • gated on marker: "merge_unit"
#> • kept separate: "\\.2$"
#> • merge repeated reads: TRUE
cr_merge_rules(merge_marker = NULL, keep_separate = NULL)
#> <cr_merge_rules>
#> • merge suffix: "\\.1$"
#> • gated on marker: "no"
#> • kept separate: "disabled"
#> • merge repeated reads: TRUE
```
