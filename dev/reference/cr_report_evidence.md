# Bind report claims and figures to portable source-file evidence

This neutral provenance layer does not calculate effects, infer units,
verify scientific validity, or prove that a figure was generated from
its declared tables. Figure links are explicit declarations whose file
identities are checked. Source files remain external to the report.

## Usage

``` r
cr_report_evidence(root, tables, claims = list(), figures = list())
```

## Arguments

- root:

  Existing directory containing all source files. Paths stored in the
  evidence are relative to this root, so the complete tree can be moved.

- tables:

  Named list of descriptors with `path`, `format` (`"csv"` or `"tsv"`),
  and `key` (one or more unique-key column names). Fields are read as
  UTF-8 character strings without automatic missing-value conversion.

- claims:

  Named list of descriptors with `table`, `key` (a named character
  vector giving every key value), `column`, and optional `format`
  (`"text"` or `"number"`, default `"text"`) and `digits` (default 3).
  Numeric claims must be finite decimal numbers; formatting uses
  [`cr_format_number()`](https://cttir.github.io/cellreportR/dev/reference/cr_format_number.md).
  No scaling, unit conversion, missing-value substitution or inference
  occurs.

- figures:

  Named list of descriptors with `path` and `tables` (nonempty character
  vector of declared source-table identifiers).

## Value

`cr_report_evidence` returns a versioned list with file SHA-256 hashes,
keyed raw values, formatted displays and a manifest SHA-256. Its hash
uses UTF-8 JSON bytes, not R serialization. Identifiers use radix
ordering and numeric displays use a period decimal mark regardless of
locale/options. Row order and other source-byte changes deliberately
invalidate the source hash.

## Examples

``` r
root <- tempfile(); dir.create(root)
writeLines(c("group,value", "control,1.25"), file.path(root, "result.csv"))
evidence <- cr_report_evidence(root,
  tables = list(result = list(path = "result.csv", format = "csv", key = "group")),
  claims = list(mean = list(table = "result", key = c(group = "control"),
                            column = "value", format = "number", digits = 2)))
cr_validate_report_evidence(evidence, root)
unlink(root, recursive = TRUE)
```
