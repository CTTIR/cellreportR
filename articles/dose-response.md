# Dose-Response Analysis

[![R-CMD-check](https://github.com/CTTIR/cellreportR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/cellreportR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/cellreportR/actions/workflows/pkgdown.yaml/badge.svg)](https://cttir.github.io/cellreportR/)
[![CRAN
status](https://www.r-pkg.org/badges/version/cellreportR)](https://CRAN.R-project.org/package=cellreportR)
[![Codecov test
coverage](https://codecov.io/gh/CTTIR/cellreportR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/cellreportR?branch=main)
[![CRAN
downloads](https://cranlogs.r-pkg.org/badges/cellreportR)](https://cran.r-project.org/package=cellreportR)
[![CRAN downloads
total](https://cranlogs.r-pkg.org/badges/grand-total/cellreportR)](https://cran.r-project.org/package=cellreportR)
[![License:
MIT](https://img.shields.io/badge/license-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)

cellreportR fits three standard dose-response models:

- **4PL** (four-parameter log-logistic)
- **3PL** (fixed lower asymptote at zero)
- **Linear** (for convenience; fits `y ~ x`)

## Setting up a dose-response experiment

Any `cr_experiment` with a `dose` column in `design` is eligible.

``` r

exp <- cr_example_experiment(seed = 3, n_cells_per_well = 60)
exp$design$dose <- dplyr::case_when(
  exp$design$treatment == "Untreated"      ~ 0.1,
  exp$design$treatment == "CompoundA_low"  ~ 50,
  exp$design$treatment == "CompoundA_high" ~ 500,
  exp$design$treatment == "PosControl"     ~ 1000,
  TRUE ~ 10
)
```

## Fitting

``` r

fit <- cr_dose_response(exp,
                        channel = "marker_1",
                        model = "4pl",
                        log_dose = TRUE)
fit$model
#> [1] "4pl"
fit$params
#> # A tibble: 4 × 3
#>   parameter estimate std_error
#>   <chr>        <dbl>     <dbl>
#> 1 a           615.          NA
#> 2 d          4503.          NA
#> 3 e             8.90        NA
#> 4 b         -3072.          NA
```

## IC50 / EC50

``` r

cr_ic50(fit)
#> # A tibble: 1 × 5
#>   parameter   estimate ci_low ci_high units
#>   <chr>          <dbl>  <dbl>   <dbl> <chr>
#> 1 IC50      788211529.     NA      NA uM
```

## Plotting

``` r

cr_plot_dose_response(fit)
```

![](dose-response_files/figure-html/plot-dr-1.png)

## Troubleshooting

If [`nls()`](https://rdrr.io/r/stats/nls.html) fails to converge (for
example when there are very few dose levels), cellreportR falls back to
a linear model. Check `fit$model` after fitting.
