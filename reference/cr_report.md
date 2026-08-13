# Assemble a structured analysis report

Collects everything a write-up needs into one `cr_report` object: the
experiment, the statistical results, the quality-control record, the
effect-size grid, the sample-size table, any supplementary tables and
any plots. Assembling first and formatting later is what keeps a number
in the text tied to the object it came from — tables, generated macros
and the rendered document are then all derived from the same assembly
rather than transcribed from each other.

## Usage

``` r
cr_report(
  experiment,
  results = NULL,
  qc = NULL,
  effects = NULL,
  sizes = NULL,
  tables = NULL,
  plots = NULL,
  title = "cellreportR analysis report",
  author = "",
  metadata = list(),
  render = NULL,
  template = NULL,
  output_dir = NULL,
  format = c("html", "pdf")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- results:

  Optional `cr_result`, list of `cr_result` objects (as returned by
  [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md)),
  or a data frame of results.

- qc:

  Optional quality-control record: a data frame, or a list holding one
  (for example a gate object with a `units` element). If `NULL`, the
  experiment's QC log is used.

- effects:

  Optional data frame of effect sizes — one row per contrast, typically
  with estimate and confidence-bound columns.

- sizes:

  Optional data frame of sample-size calculations, one row per contrast.

- tables:

  Optional named list of supplementary tables (data frames). A
  `disposition` table is added automatically when the list does not
  already contain one.

- plots:

  Optional named list of ggplot2 objects.

- title:

  Report title.

- author:

  Author name for the report header.

- metadata:

  Optional named list of arbitrary metadata.

- render:

  Whether to render the report to a file. The default `NULL` renders
  when `template` or `output_dir` is supplied — that is, when the caller
  has said where the document should go — and otherwise returns the
  assembled object. Pass `TRUE` or `FALSE` to be explicit.

- template:

  Path to an R Markdown template. If `NULL`, the bundled template is
  used.

- output_dir:

  Output directory for the rendered document.

- format:

  One of `"html"` or `"pdf"`.

## Value

A `cr_report` object, an S3 list with the slots

- `experiment`:

  The `cr_experiment` the report describes.

- `results`:

  Named list of `cr_result` objects.

- `summary`:

  One-row-per-contrast overview tibble.

- `qc`:

  Quality-control tibble.

- `effects`:

  Effect-size tibble, or `NULL`.

- `sizes`:

  Sample-size tibble, or `NULL`.

- `tables`:

  Named list of supplementary tibbles.

- `plots`:

  Named list of ggplot2 objects.

- `metadata`:

  User metadata.

- `params`:

  Title, author, package version, creation time.

When rendering was requested, the path to the rendered document is
returned invisibly instead, carrying the assembled object in its
`report` attribute.

## See also

[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md)
to render an assembled report,
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)
to extract its tables and
[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md)
to emit its numbers.

Other reporting:
[`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md),
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md),
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md),
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
rep <- cr_report(exp, title = "Marker 1 overview")
rep
#> ── cr_report ───────────────────────────────────────────────────────────────────
#> • Analyses: 0
#> • Plots queued: 0

# supply an effect grid and the sample sizes derived from it
eff <- data.frame(
  group = c("CompoundA_low", "CompoundA_high"),
  estimate = c(0.31, 1.42),
  ci_low = c(-0.10, 0.55),
  ci_high = c(0.72, 2.29)
)
rep2 <- cr_report(exp, effects = eff, title = "Marker 1 screen")
rep2$summary
#> # A tibble: 2 × 4
#>   group          estimate ci_low ci_high
#>   <chr>             <dbl>  <dbl>   <dbl>
#> 1 CompoundA_low      0.31  -0.1     0.72
#> 2 CompoundA_high     1.42   0.55    2.29
```
