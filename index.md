# cellreportR

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.21889928.svg)](https://doi.org/10.5281/zenodo.21889928)

`cellreportR` is an analysis and reporting pipeline for cell culture
assays read out by microscopy. It picks up where segmentation leaves
off: segmented single-cell exports flow in, and quality-controlled
estimates, publication figures, machine-readable tables and a generated
file of every quoted number flow out.

The organising idea is the **unit of replication**. Cells are not
replicates. `cellreportR` resolves acquisitions into units, standardizes
every cell against the control condition of its *own* batch, and reports
each effect at both unit and cell level so the cost of pooling is
visible rather than assumed.

## Pipeline

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

## Installation

`cellreportR` is **pure R** — it compiles nothing — so it installs the
same way on **Windows, macOS, and Linux**. The only hard prerequisite is
**R \>= 4.1.0**.

Install the development version from GitHub:

``` r

# install.packages("pak")
pak::pak("CTTIR/cellreportR")
```

### Platform notes

- **Windows** — no *Rtools* required: the package itself compiles
  nothing, and its dependencies install as pre-built binaries from CRAN.
- **macOS** — nothing beyond R; no XQuartz needed.
- **Linux** — several dependencies (`dplyr`, `readr`, `tidyr`,
  `ggplot2`) contain C++ and build from source unless you use a binary
  repository such as the [Posit Public Package
  Manager](https://packagemanager.posit.co) or
  [r2u](https://eddelbuettel.github.io/r2u/), which avoids needing a
  compiler. Otherwise install a build toolchain (for example
  `build-essential` on Debian/Ubuntu).

Installing the package pulls in its required imports automatically.
Optional features need a few extra packages:

| Feature | Needs |
|----|----|
| Interactive front-end ([`cr_run_app()`](https://cttir.github.io/cellreportR/reference/cr_run_app.md)) | `bslib`, `DT` |
| Rendered reports ([`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md), [`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md)) | `rmarkdown`, `knitr`, and a working pandoc |
| Excel export ([`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md), [`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md)) | `writexl` |
| Reading `.fcs` inputs | `flowCore` (Bioconductor) |
| Batch correction via empirical Bayes | `sva` (Bioconductor) |

## Quick start

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

## Screening workflow

The screening path is the reason the package exists. Each stage is an
exported function, so the analysis is inspectable at every step rather
than being one opaque call.

``` r

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

``` r

cr_run_app()
```

The application provides a guided workflow covering import, quality
control, normalization, statistical analysis, dose-response fitting,
interactive visualisation and report export.

## Output structure

[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md)
and
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md)
return a list of class `cr_experiment`:

| Slot | Description |
|----|----|
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
|----|----|
| Ingest | [`cr_read_export()`](https://cttir.github.io/cellreportR/reference/cr_read_export.md), [`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md), [`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md), [`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md), [`cr_read_cellprofiler()`](https://cttir.github.io/cellreportR/reference/cr_read_cellprofiler.md), [`cr_read_qupath()`](https://cttir.github.io/cellreportR/reference/cr_read_qupath.md), [`cr_read_segmantr()`](https://cttir.github.io/cellreportR/reference/cr_read_segmantr.md), [`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md), [`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md), [`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md), [`cr_filename_grammar()`](https://cttir.github.io/cellreportR/reference/cr_filename_grammar.md), [`cr_marker_rules()`](https://cttir.github.io/cellreportR/reference/cr_marker_rules.md), [`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md) |
| Experiment object | [`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md), [`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md), [`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md), [`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md), [`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md), [`cr_channels()`](https://cttir.github.io/cellreportR/reference/cr_channels.md), [`cr_n_cells()`](https://cttir.github.io/cellreportR/reference/cr_n_cells.md), [`cr_filter_cells()`](https://cttir.github.io/cellreportR/reference/cr_filter_cells.md), [`cr_merge_experiments()`](https://cttir.github.io/cellreportR/reference/cr_merge_experiments.md) |
| Units and balancing | [`cr_merge_rules()`](https://cttir.github.io/cellreportR/reference/cr_merge_rules.md), [`cr_assign_units()`](https://cttir.github.io/cellreportR/reference/cr_assign_units.md), [`cr_unit_map()`](https://cttir.github.io/cellreportR/reference/cr_unit_map.md), [`cr_centroid_overlap()`](https://cttir.github.io/cellreportR/reference/cr_centroid_overlap.md), [`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md), [`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md) |
| Quality control | [`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md), [`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md), [`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md), [`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md), [`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md), [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md), [`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md), [`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md), [`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md) |
| Standardization | [`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md), [`cr_background_subtract()`](https://cttir.github.io/cellreportR/reference/cr_background_subtract.md), [`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md), [`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md), [`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md) |
| Quantification | [`cr_summarize_wells()`](https://cttir.github.io/cellreportR/reference/cr_summarize_wells.md), [`cr_fold_change()`](https://cttir.github.io/cellreportR/reference/cr_fold_change.md), [`cr_compute_metrics()`](https://cttir.github.io/cellreportR/reference/cr_compute_metrics.md) |
| Effect sizes | [`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md), [`cr_compare_levels()`](https://cttir.github.io/cellreportR/reference/cr_compare_levels.md), [`cr_blocked_effect()`](https://cttir.github.io/cellreportR/reference/cr_blocked_effect.md), [`cr_unit_variability()`](https://cttir.github.io/cellreportR/reference/cr_unit_variability.md), [`cr_effect_size()`](https://cttir.github.io/cellreportR/reference/cr_effect_size.md), [`cr_test()`](https://cttir.github.io/cellreportR/reference/cr_test.md), [`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md) |
| Sample size | [`cr_conservative_effect()`](https://cttir.github.io/cellreportR/reference/cr_conservative_effect.md), [`cr_power()`](https://cttir.github.io/cellreportR/reference/cr_power.md), [`cr_power_grid()`](https://cttir.github.io/cellreportR/reference/cr_power_grid.md), [`cr_power_analysis()`](https://cttir.github.io/cellreportR/reference/cr_power_analysis.md) |
| Discriminability | [`cr_logistic()`](https://cttir.github.io/cellreportR/reference/cr_logistic.md), [`cr_roc()`](https://cttir.github.io/cellreportR/reference/cr_roc.md), [`cr_auc()`](https://cttir.github.io/cellreportR/reference/cr_auc.md), [`cr_confusion_matrix()`](https://cttir.github.io/cellreportR/reference/cr_confusion_matrix.md) |
| Dose-response | [`cr_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_dose_response.md), [`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md) |
| Visualization | eighteen `cr_plot_*()` functions, plus [`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md), [`cr_palette()`](https://cttir.github.io/cellreportR/reference/cr_palette.md), [`cr_shapes()`](https://cttir.github.io/cellreportR/reference/cr_shapes.md), [`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md), [`cr_save_plot()`](https://cttir.github.io/cellreportR/reference/cr_save_plot.md) |
| Tables and reporting | [`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md), [`cr_table_disposition()`](https://cttir.github.io/cellreportR/reference/cr_table_disposition.md), [`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md), [`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md), [`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md), [`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md), [`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md), [`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md) |
| Generated numbers | [`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md), [`cr_macros_from()`](https://cttir.github.io/cellreportR/reference/cr_macros_from.md), [`cr_macro_name()`](https://cttir.github.io/cellreportR/reference/cr_macro_name.md), [`cr_format_number()`](https://cttir.github.io/cellreportR/reference/cr_format_number.md), [`cr_enumerate()`](https://cttir.github.io/cellreportR/reference/cr_enumerate.md) |
| Example data | [`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md), [`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md), [`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md) |
| Interactive | [`cr_run_app()`](https://cttir.github.io/cellreportR/reference/cr_run_app.md) |

## Documentation

- [Getting
  Started](https://cttir.github.io/cellreportR/articles/getting-started.html)
- [Statistical
  Analysis](https://cttir.github.io/cellreportR/articles/statistical-analysis.html)
- [Dose-Response](https://cttir.github.io/cellreportR/articles/dose-response.html)
- [Interactive
  Front-End](https://cttir.github.io/cellreportR/articles/shiny-app.html)

## Citation

If you use `cellreportR` in academic work, please cite the package:

> Heller R, Schwindling L, Büchner A, Lindenberger L, Müller S,
> Hannemann M, Achatz G, Rothmiller S (2026). *cellreportR: Cell Culture
> Microscopy Assay Analysis and Reporting*. R package version 0.2.0,
> <https://github.com/CTTIR/cellreportR>.

BibTeX:

``` bibtex
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

## License

MIT (c) 2026 R. Heller.
