# Balance the number of cells per analysis unit

Randomly subsamples each analysis unit to a common cell count. A unit
acquired in several passes otherwise contributes several times as many
cells as its single-pass neighbour and is silently over-weighted in
every pooled quantity they share — including the control statistics of
their own batch.

## Usage

``` r
cr_balance_cells(experiment, unit = NULL, n_max = NULL, n = NULL, seed = NULL)
```

## Arguments

- experiment:

  A `cr_experiment`.

- unit:

  Column in `cells` identifying the analysis unit. Defaults to the
  experiment's unit column, falling back to its spatial unit (`well` /
  `slide`).

- n_max:

  Optional maximum number of cells per unit.

- n:

  Optional exact number of cells per unit. Cannot be combined with
  `n_max`.

- seed:

  Optional integer seed.

## Value

A modified `cr_experiment`. Per-unit counts before and after are stored
in `metadata$balance_cells`.

## Details

Three modes:

- `n_max`:

  cap each unit at `n_max` cells, leaving smaller units untouched. This
  is the usual choice for large acquisitions.

- `n`:

  take exactly `n` cells per unit (units with fewer cells keep all of
  theirs).

- neither:

  take the smallest unit's cell count from every unit, which equalises
  the units exactly at the cost of discarding the most data.

Subsampling is random, so pass `seed` for a reproducible result. The RNG
state of the calling session is saved and restored, so a seeded stream
outside this function is never disturbed.

## See also

[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
which should run first.

Other quality control:
[`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md),
[`cr_exclude_small()`](https://cttir.github.io/cellreportR/reference/cr_exclude_small.md),
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
exp2 <- cr_balance_cells(exp, n_max = 20, seed = 1)
max(exp2$metadata$balance_cells$n_after)
#> [1] 20

# equalise every unit at the smallest unit's count
exp3 <- cr_balance_cells(exp, seed = 1)
length(unique(exp3$metadata$balance_cells$n_after))
#> [1] 1
```
