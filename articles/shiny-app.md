# Interactive Analysis with the cellreportR Shiny App

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

The bundled Shiny application exposes the full cellreportR pipeline
through seven guided tabs. It is intended for laboratory personnel
without an R background.

## Launching

``` r

library(cellreportR)
cr_run_app()                             # example data
cr_run_app(experiment = my_cr_exp)       # your own experiment
```

## Tab overview

1.  **Import & Design** — upload cell and design files, or load the
    example data.
2.  **Quality Control** — set morphology thresholds and remove doublets.
3.  **Normalization** — background subtraction, control-reference or
    Z-score.
4.  **Statistical Analysis** — parametric and non-parametric tests at
    cell or replicate level, with effect sizes and adjusted p-values.
5.  **Dose-Response** — fit 4PL / 3PL / linear models and read off IC50.
6.  **Visualization** — interactive gallery covering all 13 plot types.
7.  **Report & Export** — generate HTML or PDF reports, export tables
    and figures.

## Cross-tab state

The Shiny app keeps a single `cr_experiment` in `reactiveValues()`. QC
filtering, normalization and analysis all mutate this object so that
downstream tabs react automatically.
