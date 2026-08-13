# Declare how parenthetical file-name markers are interpreted

Acquisition software and operators annotate exports with short markers,
and those markers change the analysis. A `cr_marker_rules` object states
which regular expression means what, so that a marker becomes a typed
flag instead of a string somebody has to remember.

## Usage

``` r
cr_marker_rules(
  merge_unit = NULL,
  partial_plate = NULL,
  omitted_reagent = NULL,
  reacquisition = NULL,
  lot = NULL,
  capture_unknown = TRUE,
  ignore_case = TRUE
)
```

## Arguments

- merge_unit:

  Regular expression marking a file as one half of a two-pass
  acquisition, or `NULL`.

- partial_plate:

  Regular expression matched against the container (directory) name, or
  `NULL`.

- omitted_reagent:

  Regular expression marking the specificity arm, or `NULL`.

- reacquisition:

  Regular expression marking a repeated read, or `NULL`.

- lot:

  Regular expression marking a reagent lot, or `NULL`.

- capture_unknown:

  Logical. Capture an unmatched trailing parenthetical into `variant`.
  Default `TRUE`.

- ignore_case:

  Logical. Match case-insensitively. Default `TRUE`.

## Value

An object of class `cr_marker_rules` (a list).

## Details

The distinctions the rules encode are deliberate:

- `merge_unit` sits on a **file** and means one spatial unit was
  acquired in two passes. The two files are one unit and must be merged
  before any per-unit balancing, or the unit contributes twice the cells
  of its neighbours.

- `partial_plate` sits on a **container** (the plate directory) and
  means a partly filled plate. It has no downstream consequence.
  Collapsing the two into one flag hides the one that matters, so they
  are matched against different strings.

- `omitted_reagent` marks the specificity arm, where the detection
  reagent was left out. These acquisitions are never samples.

- `reacquisition` marks a repeated read of a unit that already has a
  plain sibling file.

- `lot` marks a different reagent lot. A lot marker is *not* an
  omitted-reagent control; pooling the two inverts the meaning of the
  arm.

Any trailing parenthetical that matches none of the rules is captured
verbatim into a `variant` column when `capture_unknown = TRUE`, rather
than being guessed at or silently dropped.

## See also

[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
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
rules <- cr_marker_rules(
  merge_unit = "\\(split\\)",
  partial_plate = "\\(partial\\)",
  omitted_reagent = "\\(no reagent\\)",
  reacquisition = "\\(repeat\\)",
  lot = "\\(lot[A-Z]\\)"
)
rules
#> $merge_unit
#> [1] "\\(split\\)"
#> 
#> $partial_plate
#> [1] "\\(partial\\)"
#> 
#> $omitted_reagent
#> [1] "\\(no reagent\\)"
#> 
#> $reacquisition
#> [1] "\\(repeat\\)"
#> 
#> $lot
#> [1] "\\(lot[A-Z]\\)"
#> 
#> $capture_unknown
#> [1] TRUE
#> 
#> $ignore_case
#> [1] TRUE
#> 
#> attr(,"class")
#> [1] "cr_marker_rules" "list"           
```
