# Parse design facts out of export paths

Turns a vector of export paths into one row of design information per
file: the directory levels below `root`, the file-name markers, the
replicate index and the grammar tokens.

## Usage

``` r
cr_parse_paths(
  paths,
  root = NULL,
  levels = NULL,
  grammar = NULL,
  markers = NULL,
  strict = TRUE,
  spec = NULL,
  call = rlang::caller_env()
)
```

## Arguments

- paths:

  Character vector of file paths.

- root:

  Directory the paths sit under. Required when `levels` is given.

- levels:

  Directory level specification; see
  [`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md).

- grammar:

  A
  [`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
  or `NULL`.

- markers:

  A
  [`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md)
  object, or `NULL`.

- strict:

  Logical. Abort on an unparseable file name. When `spec` is supplied
  and `strict` is not, the spec's setting is used.

- spec:

  Optional
  [`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md)
  supplying any of `levels`, `grammar`, `markers` and `strict` that are
  not given directly.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

## Value

A tibble with one row per path: `source_file`, `source_path`, one column
per directory level, the marker flag columns, `variant`, `core`,
`replicate`, one column per grammar token, and the `parse_ok` /
`parse_error` outcome.

## Details

With `strict = TRUE` (the default) a file name that matches no
`core_patterns` entry of the grammar aborts the parse. That is the
intended behaviour: a name that parses to defaults instead of failing
loudly can move a treated unit into a control arm without anything in
the analysis noticing.

## See also

[`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md),
[`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md),
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
[`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md),
[`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md),
[`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md),
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
root <- file.path(tempdir(), "cr_paths_demo")
paths <- file.path(
  root, "Run1", "CompoundA", "Plate_1",
  c("CompoundA_vehicle_1.csv", "CompoundA_5min_10uM_treated_1.csv")
)
cr_parse_paths(
  paths,
  root = root,
  levels = c("run", "compound", "plate"),
  grammar = cr_filename_grammar(
    tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM"),
    defaults = list(interval = "none", dose = "vehicle"),
    prefix_strip = "CompoundA"
  )
)
#> # A tibble: 2 × 17
#>   source_file          source_path run   compound plate merge_unit partial_plate
#>   <chr>                <chr>       <chr> <chr>    <chr> <lgl>      <lgl>        
#> 1 CompoundA_vehicle_1… /tmp/Rtmpb… Run1  Compoun… Plat… FALSE      FALSE        
#> 2 CompoundA_5min_10uM… /tmp/Rtmpb… Run1  Compoun… Plat… FALSE      FALSE        
#> # ℹ 10 more variables: omitted_reagent <lgl>, reacquisition <lgl>, lot <lgl>,
#> #   variant <chr>, core <chr>, replicate <chr>, interval <chr>, dose <chr>,
#> #   parse_ok <lgl>, parse_error <chr>
```
