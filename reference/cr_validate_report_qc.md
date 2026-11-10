# Validate a concise report QC table

Validate a concise report QC table

## Usage

``` r
cr_validate_report_qc(qc)
```

## Arguments

- qc:

  A data frame with criterion, observed, acceptance and status columns.

## Value

`TRUE`, invisibly. Invalid tables raise an error.

## Examples

``` r
qc <- cr_report_qc("Cells per well", observed = "1520",
                   acceptance = ">= 500", status = "PASS")
cr_validate_report_qc(qc)
```
