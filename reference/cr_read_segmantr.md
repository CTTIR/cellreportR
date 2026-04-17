# Read segmantR output

Imports an RDS file produced by the `segmantR` segmentation package.
Accepts either a `segmantr_result` list (where cells are in `$cells`) or
a plain data frame.

## Usage

``` r
cr_read_segmantr(path)
```

## Arguments

- path:

  Path to RDS file.

## Value

A tibble of cells.

## Examples

``` r
tmp <- tempfile(fileext = ".rds")
df <- cr_example_experiment(seed = 1, n_cells_per_well = 5)$cells
saveRDS(df, tmp)
cells <- cr_read_segmantr(tmp)
head(cells)
#> # A tibble: 6 × 10
#>   cell_id well      x     y  area circularity  DAPI marker_1 marker_2 marker_3
#>   <chr>   <chr> <dbl> <dbl> <dbl>       <dbl> <dbl>    <dbl>    <dbl>    <dbl>
#> 1 c000001 A01   1816.  768.  35.7       0.737  362.    3001.     651.     220.
#> 2 c000002 A01    403. 1540.  74.2       0.852  468.    2165.    1054.     192.
#> 3 c000003 A01   1797.  995. 106.        0.663  467.    3835.    1223.     200.
#> 4 c000004 A01   1889. 1435.  93.3       0.921  451.    4786.    1156.     164.
#> 5 c000005 A01   1322. 1984.  80.0       0.635  551.    2076.     703.     487.
#> 6 c000006 A01   1258.  760.  26.2       0.661  391.    1378.    1260.     427.
```
