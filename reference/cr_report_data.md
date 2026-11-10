# Inspect the exact structured values entering a laboratory report

Inspect the exact structured values entering a laboratory report

## Usage

``` r
cr_report_data(report)
```

## Arguments

- report:

  A `cr_lab_report`.

## Value

A plain list with the schema and template identifiers, the
specification, the QC table, the style and, when present, the bound
evidence.

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
str(cr_report_data(report), max.level = 1)
#> List of 7
#>  $ schema_name     : chr "cellreportR-report-spec"
#>  $ schema_version  : chr "1.0"
#>  $ template_name   : chr "laboratory-report"
#>  $ template_version: chr "2.0"
#>  $ spec            :List of 16
#>  $ qc              :'data.frame':    1 obs. of  5 variables:
#>  $ style           :List of 14
```
