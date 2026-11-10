# Summary method for `cr_experiment`

Summary method for `cr_experiment`

## Usage

``` r
# S3 method for class 'cr_experiment'
summary(object, ...)
```

## Arguments

- object:

  A `cr_experiment`.

- ...:

  Unused.

## Value

A tibble summarising the experiment (invisibly printed).

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
summary(exp)
#> # A tibble: 6 × 3
#>   treatment      n_wells n_cells
#>   <chr>            <int>   <int>
#> 1 CompoundA_high      16     324
#> 2 CompoundA_low       16     341
#> 3 CompoundB           16     350
#> 4 CompoundC           16     335
#> 5 PosControl          16     303
#> 6 Untreated           16     308
```
