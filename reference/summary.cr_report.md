# Summary method for `cr_report`

Summary method for `cr_report`

## Usage

``` r
# S3 method for class 'cr_report'
summary(object, ...)
```

## Arguments

- object:

  A `cr_report`.

- ...:

  Unused.

## Value

`object` invisibly.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
rep <- cr_report(exp, title = "Marker 1 overview")
summary(rep)
#> ── cr_report ───────────────────────────────────────────────────────────────────
#> • Analyses: 0
#> • Plots queued: 0
```
