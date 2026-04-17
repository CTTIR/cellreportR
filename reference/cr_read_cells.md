# Read segmented cell data from file

Reads per-cell measurements from CSV, TSV, RDS or FCS formats. The
format is auto-detected from the file extension unless `format` is given
explicitly.

## Usage

``` r
cr_read_cells(path, format = NULL)
```

## Arguments

- path:

  Path to file.

- format:

  Optional format string: one of `"csv"`, `"tsv"`, `"rds"`, `"fcs"`. If
  `NULL`, inferred from file extension.

## Value

A tibble of cell measurements.

## Examples

``` r
d <- tempfile("cr_cells_"); dir.create(d)
files <- cr_example_files(d)
cells <- cr_read_cells(file.path(d, "cells.csv"))
head(cells)
#> # A tibble: 6 × 10
#>   cell_id well      x     y  area circularity  DAPI marker_1 marker_2 marker_3
#>   <chr>   <chr> <dbl> <dbl> <dbl>       <dbl> <dbl>    <dbl>    <dbl>    <dbl>
#> 1 c000001 A01   1283. 1133.  99.1       0.518  521.     951.     831.     203.
#> 2 c000002 A01   1038. 1699.  76.4       0.770  587.    2563.     643.     221.
#> 3 c000003 A01   1473.  379.  53.5       0.934  750.    1283.     897.     441.
#> 4 c000004 A01    269.  543.  80.9       0.856  396.    2469.     874.     489.
#> 5 c000005 A01   1314. 1656.  66.0       0.886  728.    1116.     715.     487.
#> 6 c000006 A01   1410. 1386. 119.        0.802  545.    1377.     494.     170.
```
