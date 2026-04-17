# Generate an example experimental design

Generate an example experimental design

## Usage

``` r
cr_example_design(plate_format = 96, n_wells_per_replicate = 4)
```

## Arguments

- plate_format:

  96 or 384.

- n_wells_per_replicate:

  Number of wells per replicate per treatment group.

## Value

A tibble of design columns: `well`, `treatment`, `dose`, `dose_unit`,
`replicate`, `group`, `timepoint`.

## Examples

``` r
cr_example_design(96)
#> # A tibble: 96 × 7
#>    well  treatment  dose dose_unit group   replicate timepoint
#>    <chr> <chr>     <dbl> <chr>     <chr>       <int>     <dbl>
#>  1 A01   Untreated     0 uM        control         1        24
#>  2 B01   Untreated     0 uM        control         1        24
#>  3 C01   Untreated     0 uM        control         1        24
#>  4 D01   Untreated     0 uM        control         1        24
#>  5 E01   Untreated     0 uM        control         2        24
#>  6 F01   Untreated     0 uM        control         2        24
#>  7 G01   Untreated     0 uM        control         2        24
#>  8 H01   Untreated     0 uM        control         2        24
#>  9 A02   Untreated     0 uM        control         3        24
#> 10 B02   Untreated     0 uM        control         3        24
#> # ℹ 86 more rows
```
