# cellreportR: Cell Culture Microscopy Assay Analysis and Reporting

The cellreportR package provides a complete pipeline for analyzing cell
culture-based laboratory assays evaluated by microscopy. It picks up
where cell segmentation tools (e.g. `segmantR`, CellProfiler, QuPath)
leave off, and covers experimental design, quality control,
normalization, hierarchical statistical testing, effect size estimation,
discriminability analysis, and structured report generation.

A companion interactive shiny application is available via
[`cr_run_app()`](https://r-heller.github.io/cellreportR/reference/cr_run_app.md)
for guided analysis by laboratory personnel.

## Typical workflow

1.  Read segmented cell data with
    [`cr_read_cells()`](https://r-heller.github.io/cellreportR/reference/cr_read_cells.md)
    or
    [`cr_read_cellprofiler()`](https://r-heller.github.io/cellreportR/reference/cr_read_cellprofiler.md)
    /
    [`cr_read_qupath()`](https://r-heller.github.io/cellreportR/reference/cr_read_qupath.md)
    /
    [`cr_read_segmantr()`](https://r-heller.github.io/cellreportR/reference/cr_read_segmantr.md).

2.  Assemble with design and channel metadata via
    [`cr_build_experiment()`](https://r-heller.github.io/cellreportR/reference/cr_build_experiment.md).

3.  Apply quality control
    ([`cr_qc_filter()`](https://r-heller.github.io/cellreportR/reference/cr_qc_filter.md),
    [`cr_qc_doublets()`](https://r-heller.github.io/cellreportR/reference/cr_qc_doublets.md),
    [`cr_qc_intensity()`](https://r-heller.github.io/cellreportR/reference/cr_qc_intensity.md)).

4.  Normalize
    ([`cr_normalize()`](https://r-heller.github.io/cellreportR/reference/cr_normalize.md),
    [`cr_background_subtract()`](https://r-heller.github.io/cellreportR/reference/cr_background_subtract.md)).

5.  Quantify
    ([`cr_summarize_wells()`](https://r-heller.github.io/cellreportR/reference/cr_summarize_wells.md),
    [`cr_fold_change()`](https://r-heller.github.io/cellreportR/reference/cr_fold_change.md),
    [`cr_compute_metrics()`](https://r-heller.github.io/cellreportR/reference/cr_compute_metrics.md)).

6.  Test
    ([`cr_test()`](https://r-heller.github.io/cellreportR/reference/cr_test.md),
    [`cr_test_all()`](https://r-heller.github.io/cellreportR/reference/cr_test_all.md),
    [`cr_effect_size()`](https://r-heller.github.io/cellreportR/reference/cr_effect_size.md)).

7.  Visualize with any `cr_plot_*` function.

8.  Report via
    [`cr_report()`](https://r-heller.github.io/cellreportR/reference/cr_report.md).

## See also

Useful links:

- <https://github.com/r-heller/cellreportR>

- <https://r-heller.github.io/cellreportR/>

- Report bugs at <https://github.com/r-heller/cellreportR/issues>

## Author

**Maintainer**: Raban Heller <raban.heller@charite.de>
([ORCID](https://orcid.org/0000-0001-8006-9742))
