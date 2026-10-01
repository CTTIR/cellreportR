# Construct a configurable laboratory report specification

Creates a domain-neutral, versioned description of values that may
appear in a laboratory-style report. No analytical calculation or
interpretation is performed. All scientific content is supplied by the
caller.

## Usage

``` r
cr_report_spec(
  report = list(),
  laboratory = list(),
  subject = list(),
  specimen = list(),
  examination = list(),
  result = list(),
  interpretation = list(),
  limitations = character(),
  authorization = list(),
  custom_fields = list(),
  custom_sections = list(),
  required_fields = character(),
  field_labels = character(),
  schema_version = "1.0"
)
```

## Arguments

- report, laboratory, subject, specimen, examination, result,
  interpretation, authorization:

  Named lists for the corresponding report sections.

- limitations:

  Character vector of user-supplied limitations.

- custom_fields:

  Named list of additional label/value pairs.

- custom_sections:

  List of sections, each with `title` and named `fields`.

- required_fields:

  Character vector of dotted field paths required by the caller.

- field_labels:

  Named character vector of optional display-label overrides.

- schema_version:

  Report-data schema version, independent of the package version.

## Value

An object of class `cr_report_spec`.

## See also

Other laboratory reporting:
[`cr_report_display_data()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_display_data.md),
[`cr_report_profile()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_profile.md),
[`cr_report_style()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_style.md),
[`cr_validate_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_validate_report_spec.md)
