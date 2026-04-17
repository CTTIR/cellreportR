# Read QuPath measurement export

Read QuPath measurement export

## Usage

``` r
cr_read_qupath(path)
```

## Arguments

- path:

  Path to QuPath TSV.

## Value

A tibble with standardised column names.

## Examples

``` r
d <- tempfile("cr_qp_"); dir.create(d)
files <- cr_example_files(d)
qp <- cr_read_qupath(file.path(d, "cells_qupath.tsv"))
head(qp)
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
