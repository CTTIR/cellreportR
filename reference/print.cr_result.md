# Print method for `cr_result`

Print method for `cr_result`

## Usage

``` r
# S3 method for class 'cr_result'
print(x, ...)
```

## Arguments

- x:

  A `cr_result`.

- ...:

  Unused.

## Value

`x` invisibly.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
res <- cr_test(exp, channel = "marker_1", treatment = "CompoundA_high",
               control = "Untreated", level = "replicate")
print(res)
#> ── cr_result ───────────────────────────────────────────────────────────────────
#> • Channel: "marker_1"
#> • Treatment: "CompoundA_high"
#> • Control: "Untreated"
#> • Test: "mann_whitney"
#> ℹ Replicate-level p = 1.86e-06
#> ℹ Effect sizes: cohens_d, hedges_g, cliffs_delta, and rank_biserial
```
