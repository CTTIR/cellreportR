# Count cells in a `cr_experiment`

Count cells in a `cr_experiment`

## Usage

``` r
cr_n_cells(experiment, by = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- by:

  Optional character vector of grouping columns from the `design` or
  `cells` table. If `NULL`, returns total count.

## Value

Either a scalar integer (no grouping) or a tibble with cell counts per
group.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
cr_n_cells(exp)
#> [1] 1068
cr_n_cells(exp, by = "treatment")
#> # A tibble: 6 × 2
#>   treatment       n_cells
#>   <chr>             <int>
#> 1 CompoundA_ScavX     182
#> 2 CompoundA_ScavY     173
#> 3 CompoundA_high      169
#> 4 CompoundA_low       181
#> 5 PosControl          175
#> 6 Untreated           188
```
