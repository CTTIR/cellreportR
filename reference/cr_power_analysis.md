# Post-hoc power for a hierarchical cell-based assay

A Monte-Carlo approximation that accounts for the hierarchical structure
(cells nested within replicates). Used mainly for reporting.

## Usage

``` r
cr_power_analysis(
  effect_size,
  n_replicates,
  n_cells_per_rep,
  alpha = 0.05,
  test = "t_test",
  n_sim = 500
)
```

## Arguments

- effect_size:

  Cohen's d.

- n_replicates:

  Number of replicate units per group.

- n_cells_per_rep:

  Cells per replicate.

- alpha:

  Type I error rate.

- test:

  Only `"t_test"` implemented.

- n_sim:

  Number of simulations (default 500).

## Value

A tibble with the computed power.

## Examples

``` r
cr_power_analysis(effect_size = 0.8, n_replicates = 4,
                  n_cells_per_rep = 100)
#> # A tibble: 1 × 5
#>   effect_size n_replicates n_cells_per_rep alpha power
#>         <dbl>        <dbl>           <dbl> <dbl> <dbl>
#> 1         0.8            4             100  0.05     1
```
