# Save a publication-ready figure deterministically

Save a publication-ready figure deterministically

## Usage

``` r
cr_save_figure(
  plot,
  filename,
  size = c("single", "double", "report", "square"),
  dpi = 600,
  background = "white",
  metadata = NULL
)
```

## Arguments

- plot:

  A ggplot object.

- filename:

  Explicit PDF, SVG, PNG, TIFF or TIF filename.

- size:

  Standard size name or numeric width/height.

- dpi:

  Raster resolution.

- background:

  Explicit background.

- metadata:

  Optional list written to a JSON sidecar.

## Value

`filename`, invisibly.

## Details

TIFF uses Cairo with lossless LZW compression when native Cairo and TIFF
support are available. Otherwise the normal bitmap device is used. With
Quartz configured, the fallback is uncompressed because Quartz does not
support compression. CRAN R on macOS needs XQuartz for Cairo devices. A
reported Cairo capability alone does not establish that the runtime
libraries are installed. The figure and optional sidecar are staged
before replacing their targets. Missing or empty device output is an
error. Ordinary publication failures restore previous files; callers
must serialize writers to these paths.

## Examples

``` r
p <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
  ggplot2::geom_point()
out <- tempfile(fileext = ".png")
cr_save_figure(p, out, size = "single", dpi = 72)
unlink(out)
```
