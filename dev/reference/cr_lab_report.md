# Assemble a laboratory report without recalculating analytical values

Assemble a laboratory report without recalculating analytical values

## Usage

``` r
cr_lab_report(
  experiment = NULL,
  spec = cr_report_spec(),
  qc = NULL,
  result_graphic = FALSE,
  include_audit_appendix = NULL,
  strict = TRUE,
  style = NULL,
  profile = NULL
)
```

## Arguments

- experiment:

  Optional validated `cr_experiment`; it is retained by reference
  semantics of ordinary R lists and never modified.

- spec:

  A `cr_report_spec`.

- qc:

  Optional concise QC table from
  [`cr_report_qc()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_qc.md).

- result_graphic:

  Optional precomputed plot, or `TRUE` to build one from result
  thresholds when possible.

- include_audit_appendix:

  Include a compact audit appendix in the rendered document.

- strict:

  Apply strict specification validation.

- style:

  A
  [`cr_report_style()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_style.md)
  shared by the document and its embedded report figures. Legacy
  `cr_plot_style` objects are converted.

- profile:

  Optional
  [`cr_report_profile()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_profile.md)
  containing laboratory defaults, labels, required fields, and
  organization-wide visual settings.
