# Prepare human-facing values for report rendering

Produces already formatted labels, dates, values, section visibility
flags, and audit rows. It does not change the report specification.

## Usage

``` r
cr_report_display_data(report)
```

## Arguments

- report:

  A `cr_lab_report`.

## Value

A plain nested list suitable for inspection, serialization, and
deterministic rendering.

## See also

Other laboratory reporting:
[`cr_report_profile()`](https://cttir.github.io/cellreportR/reference/cr_report_profile.md),
[`cr_report_spec()`](https://cttir.github.io/cellreportR/reference/cr_report_spec.md),
[`cr_report_style()`](https://cttir.github.io/cellreportR/reference/cr_report_style.md),
[`cr_validate_report_spec()`](https://cttir.github.io/cellreportR/reference/cr_validate_report_spec.md)

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
display <- cr_report_display_data(report)
names(display)
#>  [1] "labels"          "style"           "tokens"          "report"         
#>  [5] "identity"        "laboratory"      "subject"         "specimen"       
#>  [9] "examination"     "result"          "interpretation"  "qc"             
#> [13] "traceability"    "limitations"     "custom_fields"   "custom_sections"
#> [17] "authorization"   "amendment"       "audit"           "include"        
```
