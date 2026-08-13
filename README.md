# cellreportR <img src="man/figures/logo.png" align="right" height="139" alt="cellreportR logo" />

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889928.svg)](https://doi.org/10.5281/zenodo.21889928)

<!-- badges: start -->
[![CRAN status](https://www.r-pkg.org/badges/version/cellreportR)](https://CRAN.R-project.org/package=cellreportR)
[![R-CMD-check](https://github.com/CTTIR/cellreportR/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/CTTIR/cellreportR/actions/workflows/R-CMD-check.yaml)
[![pkgdown](https://github.com/CTTIR/cellreportR/actions/workflows/pkgdown.yaml/badge.svg)](https://github.com/CTTIR/cellreportR/actions/workflows/pkgdown.yaml)
[![lint](https://github.com/CTTIR/cellreportR/actions/workflows/lint.yaml/badge.svg)](https://github.com/CTTIR/cellreportR/actions/workflows/lint.yaml)
[![Codecov test coverage](https://codecov.io/gh/CTTIR/cellreportR/branch/main/graph/badge.svg)](https://app.codecov.io/gh/CTTIR/cellreportR?branch=main)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
<!-- badges: end -->

## Laboratory-style reporting

cellreportR can construct a versioned report specification containing report
identity, laboratory metadata, subject/specimen identifiers, finalized results,
selected QC summaries, user-supplied interpretation, limitations,
authorization metadata, custom fields, and technical provenance. The same
report object is rendered programmatically or configured through the bundled
Shiny application.

The reporting layer does not calculate results, supply decision limits, infer
classifications, or invent interpretation. Those values and policies remain
explicit caller inputs. Structured report data can be reviewed before
rendering and exported with a deterministic hash and machine-readable audit
record.

```r
spec <- cellreportR::cr_report_spec(
  report = list(report_id = "EXAMPLE-001", version = "1.0", status = "DRAFT"),
  laboratory = list(name = "Example Laboratory"),
  specimen = list(specimen_id = "SPECIMEN-001"),
  examination = list(name = "Example assay"),
  result = list(value = 1.42, unit = "a.u.", classification = "HIGH"),
  interpretation = list(text = "User-supplied interpretation."),
  authorization = list(authorized_by = "Example Authorizer")
)
report <- cellreportR::cr_lab_report(spec = spec)
```

## Publication-ready visual design

Package figures use one restrained, colour-vision-conscious visual system with
redundant shapes or line types for categorical distinctions. Colour and
grayscale modes, standard manuscript/report dimensions, vector PDF/SVG export,
and high-resolution PNG/TIFF export are available without changing plotted
data.

```r
estimates <- data.frame(
  group = c("Reference", "Group A", "Group B"),
  estimate = c(0.1, 0.8, 1.3),
  conf_low = c(-0.2, 0.3, 0.7),
  conf_high = c(0.4, 1.3, 1.9)
)
p <- cellreportR::cr_plot_estimates(estimates, reference = 0)
cellreportR::cr_save_figure(p, tempfile(fileext = ".pdf"), size = "single")
```

`cellreportR` is an analysis and reporting pipeline for cell culture
assays read out by microscopy. It picks up where segmentation leaves off:
segmented single-cell exports flow in, and quality-controlled estimates,
publication figures, machine-readable tables and a generated file of every
quoted number flow out.

The organising idea is the **unit of replication**. Cells are not
replicates. `cellreportR` resolves acquisitions into units, standardizes
every cell against the control condition of its *own* batch, and reports
each effect at both unit and cell level so the cost of pooling is visible
rather than assumed.

## Pipeline

```
Cell culture -> Treatment -> Staining -> Microscopy -> Segmentation
                                       (segmantR / CellProfiler / QuPath)
                                                    |
                                                    v
                                   +----------------------------------+
                                   |           cellreportR            |
                                   |                                  |
                                   |  Ingest + design from paths      |
                                   |  Units, exclusion, balancing     |
                                   |  Per-batch standardization       |
                                   |  Quality-control gate            |
                                   |  Effect sizes: unit vs cell      |
                                   |  Sample size from the CI bound   |
                                   |  Figures / tables / macros       |
                                   |  Interactive front-end           |
                                   +----------------------------------+
                                                    |
                                                    v
                                Report + tables + generated numbers
```

## Installation

`cellreportR` is **pure R** — it compiles nothing — so it installs the
same way on **Windows, macOS, and Linux**. The only hard prerequisite is
**R >= 4.1.0**.

Install the development version from GitHub:

```r
# install.packages("pak")
pak::pak("CTTIR/cellreportR")
```

### Platform notes

* **Windows** — no *Rtools* required: the package itself compiles nothing,
  and its dependencies install as pre-built binaries from CRAN.
* **macOS** — nothing beyond R; no XQuartz needed.
* **Linux** — several dependencies (`dplyr`, `readr`, `tidyr`, `ggplot2`)
  contain C++ and build from source unless you use a binary repository
  such as the [Posit Public Package
  Manager](https://packagemanager.posit.co) or
  [r2u](https://eddelbuettel.github.io/r2u/), which avoids needing a
  compiler. Otherwise install a build toolchain (for example
  `build-essential` on Debian/Ubuntu).

Installing the package pulls in its required imports automatically.
Optional features need a few extra packages:

| Feature | Needs |
|---|---|
| Interactive front-end (`cr_run_app()`) | `bslib`, `DT` |
| Rendered reports (`cr_report()`, `cr_render_report()`) | `rmarkdown`, `knitr`, and a working pandoc |
| Excel export (`cr_export_tables()`, `cr_export_results()`) | `writexl` |
| Reading `.fcs` inputs | `flowCore` (Bioconductor) |
| Batch correction via empirical Bayes | `sva` (Bioconductor) |

## Quick start

```r
library(cellreportR)

exp <- cr_example_experiment(seed = 42)

exp <- cr_qc_filter(exp, min_area = 50, max_area = 5000)

res <- cr_test_all(exp,
                   channel = "marker_1",
                   control_group = "Untreated",
                   level = "replicate")

cr_plot_effect_sizes(res)
```

## Screening workflow

The screening path is the reason the package exists. Each stage is an
exported function, so the analysis is inspectable at every step rather
than being one opaque call.

```r
# 1. Ingest: design facts live in the tree and the file name, not the file
cells <- cr_read_exports(
  root       = "data/exports",
  column_map = cr_column_map(),
  spec       = cr_path_spec(levels = c("run", "compound", "experiment", "plate"))
)

# 2. Units: some files merge into one unit, some deliberately do not
cells <- cr_assign_units(
  cells,
  key_vars = c("compound", "experiment", "plate", "interval", "concentration"),
  rules    = cr_merge_rules()
)

ds <- cr_dataset(cells, unit_var = "well_id")

# 3. Exclusion first, then balancing -- the order changes the threshold
ds <- cr_exclude_small(ds, var = "area", probs = 0.10)
ds <- cr_balance_cells(ds, n_max = 10000, seed = 42)

# 4. Standardize against the control condition of each cell's own batch
ds <- cr_standardize_batch(
  ds,
  channel       = "target",
  control_level = "vehicle",
  batch_vars    = c("compound", "run", "plate", "experiment", "interval")
)

# 5. Biological gate, plus the leverage of what it removed
gate <- cr_qc_gate(ds, channel = "target", control_level = "vehicle",
                   batch_vars = c("compound", "run", "plate", "experiment"))
cr_qc_gate_impact(ds, gate, channel = "target")
ds <- cr_apply_gate(ds, gate)

# 6. Effects at the unit level, then the same grid at cell level
units <- cr_summarize_wells(ds, channel = "target")

eff_unit <- cr_effect_grid(units, value = "log2_fc", group_var = "treatment",
                           reference_level = "reference", by = "compound")
eff_cell <- cr_effect_grid(ds$cells, value = "log2_fc", group_var = "treatment",
                           reference_level = "reference", by = "compound")

cr_compare_levels(eff_unit, eff_cell)   # cell intervals are narrower, not better

# 7. Sample size from the bound nearer the null, not the point estimate
cr_power_grid(eff_unit)

# 8. Figures, tables, and every quoted number in one generated file
cr_plot_screen(ds$cells, units = units, facet_by = "interval", seed = 42)
cr_export_tables(cr_tables(ds, eff_unit), "out/tables.xlsx")
cr_macros(list(n_units = nrow(units)), "out/generated-numbers.tex")
```

## Interactive analysis

```r
cr_run_app()
```

The application provides a guided workflow covering import, quality
control, normalization, statistical analysis, dose-response fitting,
interactive visualisation and report export.

## Output structure

`cr_dataset()` and `cr_build_experiment()` return a list of class
`cr_experiment`:

| Slot | Description |
|---|---|
| `cells` | One row per segmented object, with provenance (`source_file`, `source_path`) and any derived columns added by later stages |
| `design` | One row per spatial unit, carrying the treatment factors recovered from the design table or from the path grammar |
| `channels` | Character vector of measurement channels detected or declared |
| `plate_info` | Plate geometry and layout metadata |
| `qc_log` | Append-only record of every filter, exclusion and gate applied, with the realised thresholds |
| `metadata` | Free-form list of user-supplied experiment metadata |
| `spatial_unit` | Name of the column identifying the physical acquisition location |
| `unit_var` | Name of the column identifying the analysis unit of replication |
| `batch_vars` | Character vector of design columns whose combination defines a batch |
| `provenance` | One row per source file, with cell counts and the unit it was assigned to |
| `set_aside` | Control arms split out of the sample pool and retained separately |

## Function reference

| Stage | Functions |
|---|---|
| Ingest | `cr_read_export()`, `cr_read_exports()`, `cr_read_cells()`, `cr_read_design()`, `cr_read_cellprofiler()`, `cr_read_qupath()`, `cr_read_segmantr()`, `cr_column_map()`, `cr_path_spec()`, `cr_parse_paths()`, `cr_filename_grammar()`, `cr_marker_rules()`, `cr_extract_markers()` |
| Experiment object | `cr_dataset()`, `cr_build_experiment()`, `cr_validate_experiment()`, `cr_design()`, `cr_batch_key()`, `cr_channels()`, `cr_n_cells()`, `cr_filter_cells()`, `cr_merge_experiments()` |
| Units and balancing | `cr_merge_rules()`, `cr_assign_units()`, `cr_unit_map()`, `cr_centroid_overlap()`, `cr_exclude_small()`, `cr_balance_cells()` |
| Quality control | `cr_qc_filter()`, `cr_qc_doublets()`, `cr_qc_intensity()`, `cr_qc_manual()`, `cr_qc_summary()`, `cr_qc_gate()`, `cr_qc_gate_impact()`, `cr_apply_gate()`, `cr_qc_report()` |
| Standardization | `cr_normalize()`, `cr_background_subtract()`, `cr_correct_batch()`, `cr_batch_reference()`, `cr_standardize_batch()` |
| Quantification | `cr_summarize_wells()`, `cr_fold_change()`, `cr_compute_metrics()` |
| Effect sizes | `cr_effect_grid()`, `cr_compare_levels()`, `cr_blocked_effect()`, `cr_unit_variability()`, `cr_effect_size()`, `cr_test()`, `cr_test_all()` |
| Sample size | `cr_conservative_effect()`, `cr_power()`, `cr_power_grid()`, `cr_power_analysis()` |
| Discriminability | `cr_logistic()`, `cr_roc()`, `cr_auc()`, `cr_confusion_matrix()` |
| Dose-response | `cr_dose_response()`, `cr_ic50()` |
| Visualization | eighteen `cr_plot_*()` functions, plus `cr_theme()`, `cr_palette()`, `cr_shapes()`, `cr_scale_group()`, `cr_save_plot()` |
| Tables and reporting | `cr_tables()`, `cr_table_disposition()`, `cr_table_qc()`, `cr_export_tables()`, `cr_export_results()`, `cr_export_plots()`, `cr_report()`, `cr_render_report()` |
| Generated numbers | `cr_macros()`, `cr_macros_from()`, `cr_macro_name()`, `cr_format_number()`, `cr_enumerate()` |
| Example data | `cr_example_experiment()`, `cr_example_design()`, `cr_example_files()` |
| Interactive | `cr_run_app()` |

## Documentation

- [Getting Started](https://cttir.github.io/cellreportR/articles/getting-started.html)
- [Statistical Analysis](https://cttir.github.io/cellreportR/articles/statistical-analysis.html)
- [Dose-Response](https://cttir.github.io/cellreportR/articles/dose-response.html)
- [Interactive Front-End](https://cttir.github.io/cellreportR/articles/shiny-app.html)

## Citation

If you use `cellreportR` in academic work, please cite the package:

> Heller R, Schwindling L, Büchner A, Lindenberger L, Müller S, Hannemann
> M, Achatz G, Rothmiller S (2026). _cellreportR: Cell Culture Microscopy
> Assay Analysis and Reporting_. R package version 0.2.0,
> <https://github.com/CTTIR/cellreportR>.

BibTeX:

```bibtex
@Manual{cellreportR,
  title  = {cellreportR: Cell Culture Microscopy Assay Analysis and Reporting},
  author = {Raban Heller and Leila Schwindling and Alexander B\"uchner and
            Lucia Lindenberger and Steffen M\"uller and Michael Hannemann and
            Gerhard Achatz and Simone Rothmiller},
  year   = {2026},
  note   = {R package version 0.2.0},
  url    = {https://github.com/CTTIR/cellreportR},
}
```

You can always retrieve the up-to-date entry directly from R:

```r
citation("cellreportR")
```

## Use of LLM tools

Portions of this package were prepared with assistance from large language model tooling for
narrowly defined, non-authorial tasks: copyediting, prose smoothing, Markdown/LaTeX formatting,
scaffolding of boilerplate files (CI configs, build scripts), code refactoring. The tools used were [Chat AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/),
the LLM service of KISSKI (GWDG), and a self-hosted **Mistral Small (24B, Apache-2.0)** run locally via
[Ollama](https://ollama.com/) and the `ollamar` R package — local inference only, with no data sent to
third parties for the self-hosted model.

All scientific claims, methodological choices, analyses, interpretations, and conclusions are the
author's own. No LLM-generated text was incorporated without review and revision, and every reference
was verified against its DOI, arXiv ID, or ISBN.

## License

MIT (c) 2026 R. Heller.
