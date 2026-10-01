# Configure the appearance of laboratory reports

Creates a presentation-only object shared by programmatic rendering and
the Shiny report workflow. It does not alter report values or analytical
data.

## Usage

``` r
cr_report_style(
  paper = "A4",
  mode = c("colour", "grayscale"),
  density = c("standard", "compact"),
  locale = c("en", "de"),
  logo = NULL,
  primary_colour = "#315A70",
  secondary_colour = "#65747C",
  date_format = NULL,
  date_time_format = NULL,
  labels = character(),
  footer_text = NULL,
  include_audit_appendix = FALSE,
  show_signature_lines = FALSE,
  draft_watermark = FALSE
)
```

## Arguments

- paper:

  Paper size. Version 2 currently supports `"A4"`.

- mode:

  `"colour"` or intentionally monochrome `"grayscale"`.

- density:

  `"standard"` or `"compact"`.

- locale:

  Display-label locale, currently `"en"` or `"de"`.

- logo:

  Optional local PNG, JPEG, or PDF logo path.

- primary_colour, secondary_colour:

  Six-digit hex colours. In grayscale mode neutral values are used
  regardless of these settings.

- date_format, date_time_format:

  Optional [`format()`](https://rdrr.io/r/base/format.html) patterns.
  Defaults are human-readable and locale-specific.

- labels:

  Named display-label overrides.

- footer_text:

  Optional laboratory-controlled document-footer statement.

- include_audit_appendix:

  Include the technical appendix by default.

- show_signature_lines:

  Add printable reviewer/authorizer lines.

- draft_watermark:

  Add a light watermark only when status is `DRAFT`.

## Value

A `cr_report_style` object.

## See also

Other laboratory reporting:
[`cr_report_display_data()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_display_data.md),
[`cr_report_profile()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_profile.md),
[`cr_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_spec.md),
[`cr_validate_report_spec()`](https://cttir.github.io/cellreportR/dev/reference/cr_validate_report_spec.md)
