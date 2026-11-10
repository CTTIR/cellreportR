# Render a concise laboratory report

Render a concise laboratory report

## Usage

``` r
cr_render_lab_report(
  report,
  output_file,
  template = NULL,
  quiet = TRUE,
  audit_file = NULL,
  overwrite = FALSE,
  keep_tex = FALSE
)
```

## Arguments

- report:

  A `cr_lab_report`.

- output_file:

  Explicit output file ending in `.pdf` or `.html`.

- template:

  Optional R Markdown template. The default HTML template embeds its
  assets, disables dynamic math rendering, and wraps long table values.
  Custom templates retain their own HTML output options.

- quiet:

  Passed to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

- audit_file:

  Optional JSON audit path written after rendering. It must be distinct
  from the report path, including relative-path aliases.

- overwrite:

  Replace existing report and audit files. Defaults to `FALSE`, so
  released or draft reports are never silently replaced.

- keep_tex:

  Keep the generated `.tex` file beside a PDF for layout diagnostics.
  Defaults to `FALSE`.

## Value

`output_file`, invisibly.

## Examples

``` r
# \donttest{
if (requireNamespace("rmarkdown", quietly = TRUE) &&
    rmarkdown::pandoc_available()) {
  spec <- cr_report_spec(
    report = list(report_id = "EXAMPLE-001"),
    result = list(value = 1.42, unit = "a.u.", classification = "INTERMEDIATE"),
    authorization = list(authorized_by = "Example Authorizer")
  )
  qc <- cr_report_qc("Cells per well", observed = "1520",
                     acceptance = ">= 500", status = "PASS")
  report <- cr_lab_report(spec = spec, qc = qc)
  out <- tempfile(fileext = ".html")
  cr_render_lab_report(report, out)
  unlink(out)
}
# }
```
