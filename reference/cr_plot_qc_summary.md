# Compact text-first QC status plot

Compact text-first QC status plot

## Usage

``` r
cr_plot_qc_summary(qc, mode = c("colour", "grayscale"))
```

## Arguments

- qc:

  A report QC table.

- mode:

  Colour mode.

## Value

A `ggplot` object.

## Examples

``` r
qc <- cr_report_qc(criterion = c("Cells per well", "Focus"),
                   observed = c("1520", "soft"),
                   acceptance = c(">= 500", "visual check"),
                   status = c("PASS", "WARN"))
cr_plot_qc_summary(qc)
```
