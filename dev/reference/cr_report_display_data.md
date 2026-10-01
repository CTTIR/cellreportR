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
[`cr_report_profile()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_profile.md),
[`cr_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_spec.md),
[`cr_report_style()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_style.md),
[`cr_validate_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_validate_report_spec.md)
