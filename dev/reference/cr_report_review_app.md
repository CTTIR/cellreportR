# Review an immutable source-bound report in a Shiny application

Creates an application object without starting a listener. The report is
detached from the caller by serialization; previews and downloads
validate its captured state and bound source files before and after each
operation. Claim values, source metadata, limitations and report status
are visible. Source details expand using keyboard-accessible disclosures
on narrow screens.

## Usage

``` r
cr_report_review_app(report, root = NULL)
```

## Arguments

- report:

  An already-bound `cr_lab_report` with `cr_report_evidence`. Experiment
  payloads, live result graphics, external logos and mutable objects
  such as environments, functions or connections are not supported.
  Trusted HTML, tags and other unsupported S3 classes are rejected,
  including in attributes. Supported classes are the package's report,
  evidence, spec, QC, style and profile classes, lists, data frames and
  tibbles, Date, POSIXt and factors. Unclassed atomic vectors and lists
  are also supported.

- root:

  Optional existing source root for identical relocated evidence.
  Defaults to the report's bound evidence root.

## Value

A `shiny.appobj`, suitable for
[`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Details

The optional package `bslib` is required. HTML/PDF downloads
additionally require the render dependencies of
[`cr_render_lab_report()`](https://cttir.github.io/cellreportR/dev/reference/cr_render_lab_report.md),
including `rmarkdown`, Pandoc and a suitable LaTeX installation for PDF.

Only declared PNG/PDF figures are downloadable. Filename extensions and
byte signatures must agree; this is not full decoding or content
sanitization. Source tables are shown as metadata and are never
registered as a static directory. Staged downloads are removed after
failure or completion.

This application is not a sandbox, authentication service or
authorization system. Source identity does not establish scientific
validity or release authorization. Pre/post checks do not provide
filesystem snapshot isolation. The function starts no server and changes
no global listener configuration. For local review, explicitly use
`shiny::runApp(app, host = "127.0.0.1")`. Claims and figures may be
empty; bound evidence requires source tables.

## See also

[`cr_report_evidence()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_evidence.md),
[`cr_lab_report_from_evidence()`](https://cttir.github.io/cellreportR/dev/reference/cr_lab_report_from_evidence.md)

## Examples

``` r
if (interactive() && requireNamespace("bslib", quietly = TRUE)) {
  root <- tempfile("report-sources-")
  dir.create(root)
  writeLines(c("group,value", "treated,1.25"), file.path(root, "results.csv"))
  evidence <- cr_report_evidence(root,
    tables = list(results = list(
      path = "results.csv", format = "csv",
      key = "group"
    )),
    claims = list(estimate = list(
      table = "results",
      key = c(group = "treated"), column = "value"
    ))
  )
  spec <- cr_report_spec(
    report = list(report_id = "example"),
    result = list(display_value = "Source-bound example")
  )
  report <- cr_lab_report_from_evidence(evidence, root, spec)
  app <- cr_report_review_app(report)
  # shiny::runApp(app, host = "127.0.0.1")
}
```
