#' cellreportR: Cell Culture Microscopy Assay Analysis and Reporting
#'
#' @description
#' The cellreportR package provides a complete pipeline for analyzing
#' cell culture-based laboratory assays evaluated by microscopy. It
#' picks up where cell segmentation tools (e.g. `segmantR`,
#' CellProfiler, QuPath) leave off, and covers experimental design,
#' quality control, normalization, hierarchical statistical testing,
#' effect size estimation, discriminability analysis, and structured
#' report generation.
#'
#' A companion interactive \pkg{shiny} application is available via
#' [cr_run_app()] for guided analysis by laboratory personnel.
#'
#' @section Typical workflow:
#' \enumerate{
#'   \item Read segmented cell data with [cr_read_cells()] or
#'     [cr_read_cellprofiler()] / [cr_read_qupath()] /
#'     [cr_read_segmantr()].
#'   \item Assemble with design and channel metadata via
#'     [cr_build_experiment()].
#'   \item Apply quality control ([cr_qc_filter()],
#'     [cr_qc_doublets()], [cr_qc_intensity()]).
#'   \item Normalize ([cr_normalize()], [cr_background_subtract()]).
#'   \item Quantify ([cr_summarize_wells()], [cr_fold_change()],
#'     [cr_compute_metrics()]).
#'   \item Test ([cr_test()], [cr_test_all()], [cr_effect_size()]).
#'   \item Visualize with any `cr_plot_*` function.
#'   \item Report via [cr_report()].
#' }
#'
#' @keywords internal
#' @name cellreportR-package
#' @aliases cellreportR
"_PACKAGE"

## usethis namespace: start
#' @importFrom rlang .data :=
#' @importFrom utils head globalVariables
## usethis namespace: end
NULL

# Avoid R CMD check notes about undefined global variables arising
# from NSE in tidy evaluation. Each symbol here is used inside a
# data-mask context (dplyr / ggplot2 aesthetics / tidyr pivots).
utils::globalVariables(c(
  "."
))
