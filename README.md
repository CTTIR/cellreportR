# cellreportR <picture class="cttir-readme-logo"><source class="cttir-logo-dark-source" media="(prefers-color-scheme: dark)" srcset="man/figures/logo-with-name-dark.png" /><img src="man/figures/logo-with-name.png" align="right" alt="cellreportR logo" width="120" height="139" /></picture>


<!-- badges: start -->
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

PDF reports use a package-owned A4 KOMA-Script template with a controlled
first-page identity block, repeating page identity, `Page X of Y` footers,
compact metadata, a prominent result panel, deliberate pagination, and a
kept-together authorization block. `cr_report_style()` controls colour or
intentional grayscale output, density, locale-aware date display, optional
branding, signature lines, and an optional draft watermark. Reusable
organization settings can be stored in `cr_report_profile()` without mixing
branding policy with analytical configuration.

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
cellreportR::cr_render_lab_report(report, tempfile(fileext = ".pdf"))
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
* **macOS** — install [XQuartz](https://www.xquartz.org/) for the Cairo
  graphics devices used by compressed TIFF figures and laboratory PDF reports
  with CRAN R. Restart R after installation. Ordinary analyses do not use XQuartz.
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
| Rendered research reports (`cr_report()`, `cr_render_report()`) | `rmarkdown`, `knitr`, and a working pandoc |
| Laboratory PDF reports (`cr_render_lab_report()`) | the above plus XeLaTeX, TeX Gyre fonts (`tex-gyre`), and the TeX Live components checked by render preflight |
| Excel export (`cr_export_tables()`, `cr_export_results()`) | `writexl` |
| Reading `.fcs` inputs | `flowCore` (Bioconductor) |

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

This runnable example uses a synthetic screen with independent experimental
units, controls in every batch and source-file provenance. For actual segmented
files, declare the filename grammar and design explicitly as shown in the
[end-to-end guide](https://cttir.github.io/cellreportR/articles/end-to-end.html).
`cr_dataset()` is an ingest container; convert it with `cr_build_experiment()`
and an explicit design before applying experiment-level analysis functions.

```r
library(cellreportR)
ds <- cr_example_screen(seed = 42, n_compounds = 2, n_cells_per_well = 20)
batch <- ds$batch_vars

# Exclude debris, balance cells, then use each batch's own control.
ds <- cr_exclude_small(ds, var = "area", probs = 0.10)
ds <- cr_balance_cells(ds, n_max = 30, seed = 42)
ds <- cr_standardize_batch(ds, channel = "target_signal",
                            control_level = "Vehicle", batch_vars = batch)
gate <- cr_qc_gate(ds, channel = "target_signal", control_level = "Vehicle",
                   batch_vars = batch)
cr_qc_gate_impact(ds, gate, group_var = "treatment",
                  reference_level = "Vehicle", by = "compound")
ds <- cr_apply_gate(ds, gate)

# The summarized response column is named value.
units <- cr_summarize_wells(ds, channel = "log2_fc")
eff_unit <- cr_effect_grid(units, value = "value", group_var = "treatment",
                           reference_level = "Vehicle", by = "compound", level = "unit")
eff_cell <- cr_effect_grid(ds, value = "log2_fc", group_var = "treatment",
                           reference_level = "Vehicle", by = "compound")
cr_compare_levels(eff_unit, eff_cell, by = c("compound", "contrast"))
sizes <- cr_power_grid(eff_unit)
forest <- cr_plot_forest(eff_unit, estimate = "cohens_d", ci_low = "cohens_d_ci_low",
                          ci_high = "cohens_d_ci_high", label = "contrast", facet_by = "compound") +
  ggplot2::labs(subtitle = "Unit-level effects after QC; bars show 95% confidence intervals.")
forest

out <- tempfile("cellreportR-output-")
dir.create(out)
tables <- c(cr_tables(ds), list(unit_effects = eff_unit, cell_effects = eff_cell,
                                sample_sizes = sizes))
cr_export_tables(tables, file.path(out, "tables.xlsx"), format = "xlsx")
ggplot2::ggsave(file.path(out, "effects.pdf"), forest, width = 9, height = 5)
cr_macros(list(n_units = nrow(units)), file.path(out, "generated-numbers.tex"))
out
```

## Corrective development version

The single-channel `cr_correct_batch(method = "combat")` path now refuses an
unsupported analysis. Earlier versions could return median centering after a
ComBat error. Choose `method = "median_center"` explicitly when appropriate, or
prepare a feature-by-sample matrix and a suitable design for `sva::ComBat()`.

Version 0.3.0 corrects analysis integrity defects; it is not yet a published
release. For exact reproduction of the historical manuscript software, install
`CTTIR/cellreportR@manuscript-anchor-2026-08-21` in a separate library. Do not
replace archived results when comparing versions.

- `cr_test()` and `cr_test_all()` now report replicate effect sizes when
  `level = "replicate"` or `"both"`. With `"both"`, the cell effects are also
  available as `$cell_effect_sizes`. Recompute affected effect estimates,
  confidence intervals, plots and summary interpretations before citing them.
- Fully confounded or saturated blocked models are skipped. Ambiguous batch
  labels and comparison joins are rejected; supply all comparison keys in `by`.
- `sufficient` in `cr_power_grid()` requires a usable conservative target.
  An interval spanning zero cannot certify sufficiency through observed sizing.
- The legacy `wilcoxon_signed` option is refused because this interface has no
  matched-pair key. Join paired observations explicitly, verify one observation
  per pair and arm, retain complete pairs, and call
  `stats::wilcox.test(x, y, paired = TRUE)` on the aligned vectors. Row order or
  equal group size alone does not establish pairing.

Public function signatures and the API-lock snapshots remain unchanged. The
manuscript anchor and historical source data remain intact.

## Source-bound report evidence

`cr_report_evidence()` connects explicitly keyed CSV/TSV result cells to quoted
values and records figure hashes with their declared source-table links.
`cr_lab_report_from_evidence()` inserts those displays into an existing laboratory
report's custom fields. The normal renderer and audit exporter revalidate the
files and bound fields before use; existing reports retain their behavior.

```r
# Source files are relative to an existing project results directory.
evidence <- cr_report_evidence(
  root = "results",
  tables = list(effects = list(path = "effects.tsv", format = "tsv",
                              key = c("contrast", "endpoint"))),
  claims = list(estimate = list(table = "effects",
    key = c(contrast = "treated_vs_control", endpoint = "response"),
    column = "estimate", format = "number", digits = 3)),
  figures = list(effect_plot = list(path = "effect_plot.pdf", tables = "effects"))
)
spec <- cr_report_spec(report = list(report_id = "example"),
  result = list(display_value = "See source-bound additional information"),
  authorization = list(authorized_by = "Reviewer"))
report <- cr_lab_report_from_evidence(evidence, "results", spec = spec)
cr_export_report_audit(report, "report-audit.json")
```

Relative paths and SHA-256 source identities allow relocation of the whole tree;
reassemble the report with `cr_lab_report_from_evidence(evidence, new_root, spec)`
using the original specification after relocation. Existing render, export and
provenance function signatures remain unchanged.
Source-byte changes, ambiguous or missing keys, nonfinite numeric claims, and
altered bound fields fail validation. Numeric formatting performs no scaling or
unit conversion. Figure-to-table links are declarations, not proof that a figure
was generated from those tables. Scientific validity and other report prose or
fields remain the author's responsibility. Evidence hashes use versioned UTF-8
JSON bytes; the existing `cr_report_hash()` contract is unchanged.

## Interactive analysis

```r
cr_run_app()
```

The application provides a guided workflow covering import, quality
control, normalization, statistical analysis, dose-response fitting,
interactive visualisation and report export.

## Output structure

`cr_build_experiment()` returns a list of class `cr_experiment`.
`cr_dataset()` instead returns the ingest container described above:

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

Cite the exact version used. This checkout is the unpublished corrective
version 0.3.0; no verified DOI is currently attached to it. For this
version, the citation is:

> Heller R, Schwindling L, Büchner A, Lindenberger L, Müller S, Hannemann
> M, Achatz G, Rothmiller S (2026). _cellreportR: Cell Culture Microscopy
> Assay Analysis and Reporting_. R package version 0.3.0,
> <https://github.com/CTTIR/cellreportR>.

BibTeX:

```bibtex
@Manual{cellreportR,
  title  = {cellreportR: Cell Culture Microscopy Assay Analysis and Reporting},
  author = {Raban Heller and Leila Schwindling and Alexander B\"uchner and
            Lucia Lindenberger and Steffen M\"uller and Michael Hannemann and
            Gerhard Achatz and Simone Rothmiller},
  year   = {2026},
  note   = {R package version 0.3.0},
  url    = {https://github.com/CTTIR/cellreportR},
}
```

You can always retrieve the up-to-date entry directly from R:

```r
citation("cellreportR")
```

## License

MIT (c) 2026 R. Heller.

## Use of LLM tools

Where applicable, LLM tools were used for narrowly defined, non-authorial tasks:
copyediting, prose refinement, Markdown/LaTeX formatting, boilerplate scaffolding
(such as CI configurations and build scripts), and code refactoring. Tools included
[Chat AI](https://kisski.gwdg.de/leistungen/2-02-llm-service/), the KISSKI
(GWDG) service, and self-hosted **Mistral Small (24B, Apache-2.0)** served through
a local **vLLM architecture** on an Ubuntu Linux workstation with Intel
processors and NVIDIA GPUs. Self-hosted use also includes models that were
further trained (fine-tuned) or weight-edited in-house for specific tasks.
All self-hosted models ran locally, with no data sent to third parties.

All scientific claims, methodological choices, analyses, interpretations and
conclusions remain the authors' own. Where applicable, LLM-generated material
must be reviewed and revised before inclusion, and references must be verified
against their DOI, arXiv ID or ISBN.

Local software setup: vLLM with Python/PyTorch, plus R and RStudio.

## Branding

Editable R sources and regeneration instructions are in
[tools/branding](https://github.com/CTTIR/cellreportR/tree/main/tools/branding).
