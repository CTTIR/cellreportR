# Univariate logistic regression of treatment vs. control

Fits a univariate logistic regression on a single fluorescence channel
for the binary outcome `treatment == treatment` (vs.
`treatment == control`). Returns a `cr_result` with the fitted model,
ROC curve and AUC.

## Usage

``` r
cr_logistic(
  experiment,
  channel,
  treatment,
  control,
  level = c("cell", "replicate")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- treatment:

  Name of treatment group.

- control:

  Name of control group.

- level:

  `"cell"` (default) or `"replicate"`.

## Value

A `cr_result`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_logistic(exp,
                   channel = "marker_1",
                   treatment = "CompoundA_high",
                   control = "Untreated")
print(res)
#> ── cr_result ───────────────────────────────────────────────────────────────────
#> • Channel: "marker_1"
#> • Treatment: "CompoundA_high"
#> • Control: "Untreated"
#> • Test: "logistic"
#> ℹ Cell-level p = 3.88e-54
#> ℹ Effect sizes: cohens_d and cliffs_delta
#> ℹ AUC = 0.982
```
