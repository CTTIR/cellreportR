# Declare the token grammar of an export file name

A `cr_filename_grammar` states how one export file name decomposes into
design facts: which trailing token is the replicate index, which leading
labels are stripped, which substrings are tokens, and which whole-name
shapes are legal at all.

## Usage

``` r
cr_filename_grammar(
  tokens = list(),
  defaults = list(),
  core_patterns = character(),
  typo_fixes = character(),
  prefix_strip = character(),
  replicate = "[0-9]+(?:\\.[0-9]+)?",
  sep = "_",
  normalise_space = TRUE
)

# S3 method for class 'cr_filename_grammar'
print(x, ...)
```

## Arguments

- tokens:

  Named list (or named character vector) of regular expressions. Each is
  searched for in the name core; the matched text becomes the value of a
  column named after the list element.

- defaults:

  Named list of values to use when a token is absent. Elements with no
  entry default to `NA`.

- core_patterns:

  Character vector of regular expressions. The core (the name with
  extension, markers, replicate index and prefix removed) must match at
  least one of them. Empty means no whitelist.

- typo_fixes:

  Named character vector of `pattern = replacement` repairs applied
  before anything else is parsed.

- prefix_strip:

  Character vector of leading labels to strip from the core, longest
  first.

- replicate:

  Regular expression for the trailing replicate token. Default
  `"[0-9]+(?:\\.[0-9]+)?"`, which accepts both `1` and `1.1`.

- sep:

  Token separator. Default `"_"`.

- normalise_space:

  Logical. Convert runs of whitespace to `sep` and collapse repeated
  separators. Default `TRUE`.

- x:

  A `cr_filename_grammar`.

- ...:

  Ignored.

## Value

An object of class `cr_filename_grammar` (a list).

`x`, invisibly.

## Details

The `core_patterns` whitelist exists because the absence of a token is
itself meaningful — a name with no interval token is the untreated
reference arm, a name with no concentration token is a vehicle control.
A mistyped token therefore matches nothing, falls through to the
defaults, and silently reclassifies a treated unit as a vehicle control,
pulling it into the control denominator of its own batch. With a
whitelist in place such a name is a hard error instead.

`prefix_strip` entries are removed longest-first, so a short label
cannot consume a longer one that starts with the same characters.

## See also

[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md),
[`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md).

Other import:
[`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md),
[`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md),
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md),
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md),
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
g <- cr_filename_grammar(
  tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM",
                mode = "treated|vehicle"),
  defaults = list(interval = "none", dose = "vehicle"),
  core_patterns = c("^vehicle$",
                    "^[0-9]+min_vehicle$",
                    "^[0-9]+uM_treated$",
                    "^[0-9]+min_[0-9]+uM_treated$"),
  prefix_strip = c("CompoundA", "CompoundB")
)
g
#> <cr_filename_grammar>
#> • tokens: interval, dose, and mode
#> • core patterns: 4
#> • prefixes stripped: 2
#> • replicate: "[0-9]+(?:\\.[0-9]+)?"
```
