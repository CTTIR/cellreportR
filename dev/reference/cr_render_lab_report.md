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

  Optional R Markdown template.

- quiet:

  Passed to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

- audit_file:

  Optional JSON audit path written after rendering.

- overwrite:

  Replace an existing output file. Defaults to `FALSE`, so released or
  draft reports are never silently replaced.

- keep_tex:

  Keep the generated `.tex` file beside a PDF for layout diagnostics.
  Defaults to `FALSE`.
