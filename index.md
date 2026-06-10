# cellreportR

**cellreportR** is a complete analysis and reporting pipeline for
routine cell-culture laboratory diagnostics with microscopic evaluation.
It picks up where segmentation leaves off: segmented single-cell data
flows in, and structured statistical analyses, quality-controlled
results, and publication- and audit-ready reports flow out.

## Pipeline

    Cell culture -> Treatment -> Staining -> Microscopy -> Segmentation
                                                        (segmantR / CellProfiler / QuPath)
                                                                 |
                                                                 v
                                                    +---------------------+
                                                    |     cellreportR     |
                                                    |                     |
                                                    |  Design & QC        |
                                                    |  Normalization      |
                                                    |  Hierarchical tests |
                                                    |  Effect sizes + ROC |
                                                    |  Dose-response      |
                                                    |  Visualization      |
                                                    |  Report generation  |
                                                    |  Shiny dashboard    |
                                                    +---------------------+
                                                                 |
                                                                 v
                                                    Structured diagnostic report

## Installation

``` r

# install.packages("pak")
pak::pak("cttir/cellreportR")
```

## Quick example

``` r

library(cellreportR)

exp <- cr_example_experiment(seed = 42)
exp <- cr_qc_filter(exp, min_area = 50, max_area = 5000)

res <- cr_test_all(exp,
                   channel = "marker_1",
                   control_group = "Untreated",
                   level = "replicate")

cr_plot_effect_sizes(res)
```

## Interactive analysis

``` r

cr_run_app()
```

The Shiny app provides a guided seven-tab workflow covering data import,
QC, normalization, statistical analysis, dose-response fitting,
interactive visualisation and report generation.

## Documentation

- [Getting
  Started](https://cttir.github.io/cellreportR/articles/getting-started.html)
- [Statistical
  Analysis](https://cttir.github.io/cellreportR/articles/statistical-analysis.html)
- [Dose-Response](https://cttir.github.io/cellreportR/articles/dose-response.html)
- [Shiny App
  Guide](https://cttir.github.io/cellreportR/articles/shiny-app.html)

## Citation

If you use cellreportR in your research, please cite the package:

``` r

citation("cellreportR")
```

## Use of LLM tools

Portions of this package were prepared with assistance from large
language model tooling for narrowly defined, non-authorial tasks:
copyediting, prose smoothing, Markdown/LaTeX formatting, scaffolding of
boilerplate files (CI configs, build scripts), code refactoring. The
tools used were [Chat
AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the LLM
service of KISSKI (GWDG), and a self-hosted **Mistral Small (24B,
Apache-2.0)** run locally via [Ollama](https://ollama.com/) and the
`ollamar` R package — local inference only, with no data sent to third
parties for the self-hosted model.

All scientific claims, methodological choices, analyses,
interpretations, and conclusions are the author’s own. No LLM-generated
text was incorporated without review and revision, and every reference
was verified against its DOI, arXiv ID, or ISBN.
