# Create a reusable laboratory report profile

A profile stores organization-wide branding and display policy
separately from examination-specific scientific configuration.

## Usage

``` r
cr_report_profile(
  laboratory = list(),
  style = cr_report_style(),
  labels = character(),
  footer_statement = NULL,
  default_title = NULL,
  required_fields = character()
)
```

## Arguments

- laboratory:

  Default laboratory metadata.

- style:

  A
  [`cr_report_style()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_style.md).

- labels:

  Named display-label overrides.

- footer_statement:

  Optional laboratory-controlled release statement.

- default_title:

  Optional default report title.

- required_fields:

  Optional dotted required-field paths.

## Value

A `cr_report_profile` object.

## See also

Other laboratory reporting:
[`cr_report_display_data()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_display_data.md),
[`cr_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_spec.md),
[`cr_report_style()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_style.md),
[`cr_validate_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_validate_report_spec.md)
