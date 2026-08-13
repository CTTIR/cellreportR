# Export plots to PNG, PDF or SVG in batch

Export plots to PNG, PDF or SVG in batch

## Usage

``` r
cr_export_plots(
  plots,
  path,
  format = c("png", "pdf", "svg"),
  width = 6,
  height = 4,
  dpi = 300,
  ...
)
```

## Arguments

- plots:

  A named list of ggplot2 objects. Unnamed elements are numbered.

- path:

  Output directory, created when needed.

- format:

  `"png"`, `"pdf"` or `"svg"`.

- width, height:

  Figure dimensions in inches.

- dpi:

  Resolution for raster outputs.

- ...:

  Further arguments passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html).

## Value

A character vector of written file paths (invisibly).

## See also

[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md).

Other reporting:
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md),
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md),
[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md),
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
p1 <- cr_plot_intensity(exp, "marker_1")
out <- tempfile("plots_")
cr_export_plots(list(intensity = p1), out, width = 4, height = 3)
```
