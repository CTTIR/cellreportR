# Save a figure at publication settings

Writes one plot to one or more formats with the package's publication
defaults: 600 dpi, a white background (so a transparent panel does not
render as black in a typeset document) and a golden-ratio height when
none is given.

## Usage

``` r
cr_save_plot(
  plot,
  path,
  width = 12,
  height = NULL,
  dpi = 600,
  formats = c("png", "pdf"),
  units = "in",
  bg = "white",
  quiet = FALSE
)
```

## Arguments

- plot:

  A `ggplot` object, or any object
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  accepts.

- path:

  Output path. Any extension is replaced by each entry of `formats`, so
  one call can write matching raster and vector files.

- width:

  Width in `units` (default `12`).

- height:

  Height in `units`. `NULL` (default) uses `width / 1.618`.

- dpi:

  Raster resolution (default `600`).

- formats:

  Character vector of file extensions to write (default
  `c("png", "pdf")`).

- units:

  Passed to
  [`ggplot2::ggsave()`](https://ggplot2.tidyverse.org/reference/ggsave.html)
  (default `"in"`).

- bg:

  Background colour (default `"white"`).

- quiet:

  Suppress the message naming the written files (default `FALSE`).

## Value

The written paths, invisibly, as a character vector.

## See also

Other screen figures:
[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md),
[`cr_plot_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc_gate.md),
[`cr_plot_sample_size()`](https://cttir.github.io/cellreportR/reference/cr_plot_sample_size.md),
[`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md),
[`cr_plot_specificity()`](https://cttir.github.io/cellreportR/reference/cr_plot_specificity.md)

## Examples

``` r
p <- ggplot2::ggplot(data.frame(x = 1:5, y = 1:5),
                     ggplot2::aes(x, y)) +
  ggplot2::geom_point() +
  cr_theme()
out <- file.path(tempdir(), "figure-1")
paths <- cr_save_plot(p, out, width = 5, formats = "png")
#> ✔ Wrote 1 file to /tmp/RtmpDtL8CM.
basename(paths)
#> [1] "figure-1.png"
unlink(paths)
```
