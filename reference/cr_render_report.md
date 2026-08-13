# Render a report to HTML or PDF

Renders an assembled report through an R Markdown template. The bundled
template covers experimental setup, the QC log, an intensity overview,
the comparison summary and a session-info appendix. A custom template
receives the report through its `params`; only the parameters a template
declares are passed, so templates of different vintages keep working.

## Usage

``` r
cr_render_report(
  report,
  output_dir = tempdir(),
  format = c("html", "pdf"),
  template = NULL,
  title = NULL,
  author = NULL,
  quiet = TRUE
)
```

## Arguments

- report:

  A `cr_report` from
  [`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md).
  A `cr_experiment` is also accepted and is assembled into a report
  first.

- output_dir:

  Output directory (default
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)).

- format:

  One of `"html"` or `"pdf"`.

- template:

  Path to an R Markdown template. If `NULL`, the bundled template is
  used.

- title, author:

  Override the report title and author. `NULL` keeps the values stored
  in the report.

- quiet:

  Passed to
  [`rmarkdown::render()`](https://pkgs.rstudio.com/rmarkdown/reference/render.html).

## Value

Path to the rendered document (invisibly).

## See also

[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md).

Other reporting:
[`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md),
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md),
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md),
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
rep <- cr_report(exp)
if (requireNamespace("rmarkdown", quietly = TRUE) &&
    requireNamespace("knitr", quietly = TRUE) &&
    rmarkdown::pandoc_available()) {
  out <- cr_render_report(rep, output_dir = tempdir())
  basename(out)
}
#> [1] "cellreportR_report.html"
# }
```
