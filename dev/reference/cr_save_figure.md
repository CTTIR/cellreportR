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
