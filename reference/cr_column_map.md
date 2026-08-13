# Declare a column contract for vendor exports

Segmented single-cell exports name their columns however the acquisition
software happens to. A `cr_column_map` records how those raw headers
translate to the analysis names used downstream, so that the mapping
lives in one declarative object instead of being spread through reader
code.

## Usage

``` r
cr_column_map(exact = NULL, prefix = NULL, keep = NULL)

# S3 method for class 'cr_column_map'
print(x, ...)
```

## Arguments

- exact:

  Named character vector. Names are raw header names, values the
  analysis name to rename them to.

- prefix:

  Named character vector. Names are regular expressions matched against
  the raw header names, values the analysis name. The first matching
  column is renamed.

- keep:

  Optional character vector of analysis names to retain after renaming,
  in this order. Names that are absent are ignored. `NULL` keeps every
  column.

- x:

  A `cr_column_map`.

- ...:

  Ignored.

## Value

An object of class `cr_column_map`: a list with elements `exact`,
`prefix` and `keep`.

`x`, invisibly.

## Details

Two matching modes are available because vendor headers are not always
stable: `exact` matches a header verbatim, while `prefix` matches a
regular expression. Prefix matching exists for headers that embed a unit
glyph (an area column ending in a squared-micrometre symbol, for
instance), where the exact spelling cannot be relied on.

Renaming is deliberately *tolerant*: names that do not occur in a given
export are skipped silently rather than raising an error. Exports from
the same instrument routinely carry different subsets of the available
measurements, and a strict renamer forces a second reader to exist for
every subset.

## See also

[`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md),
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
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
map <- cr_column_map(
  exact = c(
    "Event Label" = "cell_id",
    "Signal - Mean Intensity" = "target_signal"
  ),
  prefix = c("^Nuclei - Area" = "area"),
  keep = c("cell_id", "target_signal", "area")
)
map
#> <cr_column_map>
#> • exact rules: 2
#> • prefix rules: 1
#> • keep: 3 columns
```
