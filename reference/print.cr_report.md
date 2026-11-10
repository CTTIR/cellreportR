# Print method for `cr_report`

Print method for `cr_report`

## Usage

``` r
# S3 method for class 'cr_report'
print(x, ...)
```

## Arguments

- x:

  A `cr_report`.

- ...:

  Unused.

## Value

`x` invisibly.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
rep <- cr_report(exp, title = "Marker 1 overview")
print(rep)
#> ── cr_report ───────────────────────────────────────────────────────────────────
#> • Analyses: 0
#> • Plots queued: 0
```
