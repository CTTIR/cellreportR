# Validate a laboratory report specification

Validate a laboratory report specification

## Usage

``` r
cr_validate_report_spec(spec, strict = TRUE, return_issues = FALSE)
```

## Arguments

- spec:

  A `cr_report_spec`.

- strict:

  In strict mode structural minima and caller-defined required fields
  are errors.

- return_issues:

  Return a severity-coded issue table instead of throwing errors.

## Value

`TRUE` invisibly, or a data frame when `return_issues = TRUE`.

## See also

Other laboratory reporting:
[`cr_report_display_data()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_display_data.md),
[`cr_report_profile()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_profile.md),
[`cr_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_spec.md),
[`cr_report_style()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_style.md)
