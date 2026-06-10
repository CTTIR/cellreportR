# Generate a structured analysis report

Renders an R Markdown report template bundled with the package. The
report includes experimental setup, QC log, normalization notes, a
comparison summary, per-comparison detail plots, optional dose-response
fits, and a session info appendix.

## Usage

``` r
cr_report(
  experiment,
  results,
  template = NULL,
  output_dir = tempdir(),
  format = c("html", "pdf"),
  title = "cellreportR analysis report",
  author = ""
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- results:

  List of `cr_result` objects produced by
  [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md),
  [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md)
  or
  [`cr_logistic()`](https://cttir.github.io/cellreportR/reference/cr_logistic.md).

- template:

  Path to an R Markdown template. If `NULL`, the bundled template is
  used.

- output_dir:

  Output directory (default
  [`tempdir()`](https://rdrr.io/r/base/tempfile.html)).

- format:

  One of `"html"` or `"pdf"`.

- title:

  Report title.

- author:

  Author name for the report header.

## Value

Path to the rendered report (invisibly).

## Examples

``` r
if (FALSE) { # \dontrun{
# Requires a working pandoc installation.
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
out <- cr_report(exp, res)
out
} # }
```
