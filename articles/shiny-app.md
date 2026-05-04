# Interactive Analysis with the cellreportR Shiny App

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
