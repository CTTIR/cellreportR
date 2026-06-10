# Hypothesis test comparing treatment to control

Runs a parametric or non-parametric two-sample test comparing cells (or
replicate summaries) from a treatment group to the control group on a
single channel.

## Usage

``` r
cr_test(
  experiment,
  channel,
  treatment,
  control,
  test = c("mann_whitney", "t_test", "welch", "wilcoxon_signed"),
  level = c("cell", "replicate", "both")
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel to test.

- treatment:

  Name of the treatment group (matches `design$treatment`).

- control:

  Name of the control group.

- test:

  One of `"mann_whitney"`, `"t_test"`, `"welch"`, `"wilcoxon_signed"`,
  `"kruskal"`, `"anova"`. For two-group tests, the first four are valid.
  `"kruskal"` and `"anova"` can be used only with
  [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md)
  where additional groups are compared together.

- level:

  `"cell"` (default) or `"replicate"`.

## Value

A `cr_result` object.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_test(exp,
               channel = "marker_1",
               treatment = "CompoundA_high",
               control = "Untreated",
               test = "mann_whitney",
               level = "replicate")
print(res)
#> ── cr_result ───────────────────────────────────────────────────────────────────
#> • Channel: "marker_1"
#> • Treatment: "CompoundA_high"
#> • Control: "Untreated"
#> • Test: "mann_whitney"
#> ℹ Replicate-level p = 1.54e-06
#> ℹ Effect sizes: cohens_d, hedges_g, cliffs_delta, and rank_biserial
```
