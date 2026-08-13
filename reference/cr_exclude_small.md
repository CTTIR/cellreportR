# Exclude sub-threshold objects with a data-derived cut-off

Removes objects whose segmentation size falls below a quantile of the
observed size distribution. Unlike
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
which applies an absolute threshold, the cut-off here is derived from
the data, so it adapts to magnification and segmentation settings. The
realised threshold is recorded, because a data-derived cut-off is only
reproducible if the value it resolved to is reported.

## Usage

``` r
cr_exclude_small(
  experiment,
  var = "area",
  probs = 0.1,
  threshold = NULL,
  scope = c("pooled", "batch"),
  batch_vars = NULL
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- var:

  Name of the size column in `cells`. Default `"area"`.

- probs:

  Quantile of the `var` distribution used as the threshold (0-1).
  Default `0.10`, i.e. the lowest tenth is dropped. Ignored when
  `threshold` is supplied.

- threshold:

  Optional absolute threshold. When supplied it overrides `probs` and is
  used for every batch.

- scope:

  `"pooled"` (default) computes a single threshold from all cells;
  `"batch"` computes one threshold per batch.

- batch_vars:

  Character vector of columns (from `cells` or `design`) that define a
  batch. Required when `scope = "batch"`.

## Value

A modified `cr_experiment`. The realised threshold(s) are stored in
`metadata$exclude_small` as a tibble and summarised in the QC log.

## Details

Cells with a non-finite value in `var` are always removed: they cannot
be placed on either side of the threshold.

`scope = "pooled"` computes one threshold from all cells. That is the
right choice when the segmentation settings were shared across the whole
study. `scope = "batch"` computes one threshold per combination of
`batch_vars`, which protects a batch acquired at a different
magnification from being trimmed against a pool it does not belong to —
at the cost of a threshold that is no longer comparable between batches.

Run this step *before*
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md):
balancing changes how many cells each unit contributes to the pool, so a
threshold computed afterwards is taken on a differently weighted
distribution.

## See also

[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md).

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_balance_cells()`](https://cttir.github.io/cellreportR/reference/cr_balance_cells.md),
[`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md),
[`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md),
[`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md),
[`cr_qc_gate_impact()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate_impact.md),
[`cr_qc_intensity()`](https://cttir.github.io/cellreportR/reference/cr_qc_intensity.md),
[`cr_qc_manual()`](https://cttir.github.io/cellreportR/reference/cr_qc_manual.md),
[`cr_qc_report()`](https://cttir.github.io/cellreportR/reference/cr_qc_report.md),
[`cr_qc_summary()`](https://cttir.github.io/cellreportR/reference/cr_qc_summary.md),
[`print.cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/print.cr_qc_gate.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
exp2 <- cr_exclude_small(exp, var = "area", probs = 0.10)
exp2$metadata$exclude_small
#> # A tibble: 1 × 2
#>   n_cells threshold
#>     <int>     <dbl>
#> 1    3852      253.

# one threshold per replicate block
exp3 <- cr_exclude_small(exp, scope = "batch", batch_vars = "replicate")
exp3$metadata$exclude_small
#> # A tibble: 4 × 3
#>   replicate n_cells threshold
#>       <int>   <int>     <dbl>
#> 1         1    1017      243.
#> 2         2     957      266.
#> 3         3     939      267.
#> 4         4     939      215.
```
