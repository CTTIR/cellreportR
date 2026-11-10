# Export report audit provenance as JSON

Export report audit provenance as JSON

## Usage

``` r
cr_export_report_audit(report, path, output_file = NULL)
```

## Arguments

- report:

  A `cr_lab_report`.

- path:

  Output JSON path.

- output_file:

  Optional rendered file to hash.

## Value

`path`, invisibly.

## Examples

``` r
spec <- cr_report_spec(
  report = list(report_id = "EXAMPLE-001"),
  result = list(value = 1.42, unit = "a.u.", classification = "INTERMEDIATE"),
  authorization = list(authorized_by = "Example Authorizer")
)
qc <- cr_report_qc("Cells per well", observed = "1520",
                   acceptance = ">= 500", status = "PASS")
report <- cr_lab_report(spec = spec, qc = qc)
audit <- tempfile(fileext = ".json")
cr_export_report_audit(report, audit)
unlink(audit)
```
