# Post-hoc power for a hierarchical cell-based assay

A Monte-Carlo approximation of the power of a two-sample comparison that
accounts for the hierarchical structure (cells nested within replicate
units). Used mainly for reporting; for sizing a follow-up study use
[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md),
which inverts the design analytically.

## Usage

``` r
cr_power_analysis(
  effect_size,
  n_replicates,
  n_cells_per_rep,
  alpha = 0.05,
  test = "t_test",
  n_sim = 500,
  seed = NULL
)
```

## Arguments

- effect_size:

  Cohen's *d* at the cell level.

- n_replicates:

  Number of replicate units per group.

- n_cells_per_rep:

  Cells per replicate unit.

- alpha:

  Type I error rate.

- test:

  Only `"t_test"` is implemented.

- n_sim:

  Number of simulations (default 500).

- seed:

  Optional integer seed. The caller's random number stream is restored
  on exit.

## Value

A tibble with the inputs and the simulated `power`.

## See also

[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md).

Other power:
[`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md),
[`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md),
[`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md)

## Examples

``` r
cr_power_analysis(effect_size = 0.8, n_replicates = 4,
                  n_cells_per_rep = 100, n_sim = 100, seed = 1)
#> # A tibble: 1 × 5
#>   effect_size n_replicates n_cells_per_rep alpha power
#>         <dbl>        <dbl>           <dbl> <dbl> <dbl>
#> 1         0.8            4             100  0.05     1
```
