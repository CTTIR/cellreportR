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
  dpi = 300
)
```

## Arguments

- plots:

  A named list of ggplot2 objects.

- path:

  Output directory.

- format:

  `"png"`, `"pdf"` or `"svg"`.

- width, height:

  Figure dimensions in inches.

- dpi:

  Resolution for raster outputs.

## Value

Character vector of written file paths (invisibly).

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
p1 <- cr_plot_intensity(exp, "marker_1")
out <- tempfile("plots_"); dir.create(out)
cr_export_plots(list(intensity = p1), out)
```
