# Convert an existing experiment QC log to report-compatible rows

Convert an existing experiment QC log to report-compatible rows

## Usage

``` r
cr_report_qc_from_log(x)
```

## Arguments

- x:

  A `cr_experiment` or QC-log data frame.

## Value

A report QC tibble as returned by
[`cr_report_qc()`](https://cttir.github.io/cellreportR/reference/cr_report_qc.md),
with one row per recorded QC step.

## Examples

``` r
qc_log <- data.frame(step = c("area filter", "doublet filter"),
                     cells_after = c(950, 930))
cr_report_qc_from_log(qc_log)
#> # A tibble: 2 × 5
#>   criterion      observed acceptance                  status   source
#>   <chr>          <chr>    <chr>                       <chr>    <chr> 
#> 1 area filter    950      Recorded analytical QC step RECORDED qc_log
#> 2 doublet filter 930      Recorded analytical QC step RECORDED qc_log
```
