# Quality-control gate diagnostic plot

Plots each unit's statistic against the statistic of the control it is
gated on, with the line of equality. Points above the line pass a
`"greater"` gate; points below it fail and are excluded.

## Usage

``` r
cr_plot_qc_gate(
  gate,
  statistic = NULL,
  reference = NULL,
  fails_median = NULL,
  fails_mean = NULL,
  direction = c("greater", "less"),
  log_scale = TRUE,
  label = NULL,
  title = NULL,
  subtitle = NULL,
  x_lab = NULL,
  y_lab = NULL
)
```

## Arguments

- gate:

  A `cr_qc_gate` object, a list carrying a `units` data frame, or a data
  frame with one row per unit.

- statistic:

  Name of the unit statistic column. `NULL` (default) auto-detects.

- reference:

  Name of the control statistic column. `NULL` (default) auto-detects.

- fails_median, fails_mean:

  Names of the logical verdict columns under the two centres. `NULL`
  (default) auto-detects; when neither is present the verdict is
  computed from `statistic`, `reference` and `direction`.

- direction:

  `"greater"` (default) when a unit must exceed its control to pass,
  `"less"` when it must fall below.

- log_scale:

  Draw both axes on a log scale when every value is positive (default
  `TRUE`).

- label:

  Optional column whose values annotate the failing units.

- title, subtitle, x_lab, y_lab:

  Plot labels. `NULL` uses a computed default; `NA` omits the label.

## Value

A `ggplot` object.

## Details

Where the input carries a verdict under both centres, median and mean,
the units whose verdict *depends* on which centre was used are drawn as
their own class. That distinction matters because a right-skewed signal
has a mean above its median, so gating a raw median against a control
mean is silently stricter than the stated rule, and a gate that can only
drop low units manufactures apparent effects when it is too strict.

## See also

[`cr_plot_qc()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc.md)
for the distribution dashboard.

Other screen figures:
[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md),
[`cr_plot_sample_size()`](https://cttir.github.io/cellreportR/reference/cr_plot_sample_size.md),
[`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md),
[`cr_plot_specificity()`](https://cttir.github.io/cellreportR/reference/cr_plot_specificity.md),
[`cr_save_plot()`](https://cttir.github.io/cellreportR/reference/cr_save_plot.md)

## Examples

``` r
set.seed(1)
units <- data.frame(
  well_id = paste0("W", 1:24),
  unit_median = c(rlnorm(20, 5, 0.3), rlnorm(4, 3.9, 0.2)),
  ctrl_median = rlnorm(24, 4.2, 0.1)
)
cr_plot_qc_gate(units, label = "well_id")
```
