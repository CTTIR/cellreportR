# Assemble a laboratory report with validated, source-bound quoted values

Claim identifiers become custom-field names and their displays become
field values. Existing custom fields with the same names are rejected.
The existing report renderer and audit exporter revalidate source files
and bound fields. Other report fields and free text are not verified by
this contract.

## Usage

``` r
cr_lab_report_from_evidence(evidence, root, spec = cr_report_spec(), ...)
```

## Arguments

- evidence:

  A
  [`cr_report_evidence()`](https://cttir.github.io/cellreportR/reference/cr_report_evidence.md)
  object.

- root:

  Current source-tree root. Retained for local validation, but excluded
  from report data and portable evidence hashes.

- spec:

  A
  [`cr_report_spec()`](https://cttir.github.io/cellreportR/reference/cr_report_spec.md).

- ...:

  Other arguments to
  [`cr_lab_report()`](https://cttir.github.io/cellreportR/reference/cr_lab_report.md).

## Value

A `cr_lab_report` with additional evidence and local root fields.

## Examples

``` r
root <- tempfile()
dir.create(root)
writeLines(c("group,value", "control,1.25"), file.path(root, "result.csv"))
evidence <- cr_report_evidence(root,
  tables = list(result = list(path = "result.csv", format = "csv", key = "group")),
  claims = list(mean = list(table = "result", key = c(group = "control"),
                            column = "value", format = "number", digits = 2)))
spec <- cr_report_spec(
  report = list(report_id = "EXAMPLE-001"),
  result = list(value = 1.42, unit = "a.u.", classification = "INTERMEDIATE"),
  authorization = list(authorized_by = "Example Authorizer")
)
report <- cr_lab_report_from_evidence(evidence, root, spec = spec)
report$spec$custom_fields
#> $mean
#> [1] "1.25"
#> 
unlink(root, recursive = TRUE)
```
