# Centroid overlap between two candidate units

Answers the question a mergeable-looking replicate suffix raises: are
these two files two passes over the same physical unit, or two different
units? Two passes over one unit share their segmentation centroids; two
different units share essentially none.

## Usage

``` r
cr_centroid_overlap(
  x,
  unit_a,
  unit_b,
  coords = c("x", "y"),
  tol = 1,
  id_col = "well_id",
  call = rlang::caller_env()
)
```

## Arguments

- x:

  A cell table carrying a unit identifier and centroid columns.

- unit_a, unit_b:

  The two unit identifiers to compare.

- coords:

  Length-2 character vector naming the centroid columns. Default
  `c("x", "y")`.

- tol:

  Numeric matching tolerance in centroid units. Default `1`.

- id_col:

  Name of the unit identifier column. Default `"well_id"`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

A single number: the fraction of cells in the smaller unit that have a
centroid within `tol` of a centroid in the other unit. The cell counts
and the number of matches are attached as the `"n_a"`, `"n_b"` and
`"n_matched"` attributes.

## See also

[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
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
cells <- tibble::tibble(
  well_id = rep(c("u1", "u2"), each = 4),
  x = c(1, 2, 3, 4, 1, 2, 3, 90),
  y = c(1, 2, 3, 4, 1, 2, 3, 90)
)
# u1 and u2 share three of four centroids:
cr_centroid_overlap(cells, "u1", "u2")
#> [1] 0.75
#> attr(,"n_a")
#> [1] 4
#> attr(,"n_b")
#> [1] 4
#> attr(,"n_matched")
#> [1] 3
```
