# Forest plot of effect sizes with confidence intervals

Draws one row per contrast: the point estimate with its confidence
interval, a reference line at the null, and the rows ordered by the
estimate rather than alphabetically, so the ordering is computed from
the data and cannot go stale.

## Usage

``` r
cr_plot_forest(
  effects,
  estimate = "estimate",
  ci_low = "ci_low",
  ci_high = "ci_high",
  label = NULL,
  facet_by = NULL,
  colour_by = NULL,
  method = "cohens_d",
  reference = 0,
  order_by_estimate = TRUE,
  descending = FALSE,
  title = NULL,
  subtitle = NULL,
  x_lab = NULL,
  y_lab = NA
)
```

## Arguments

- effects:

  A data frame of effect sizes (for example the output of an effect-size
  grid), a `cr_result`, or a list of `cr_result`s.

- estimate, ci_low, ci_high:

  Names of the estimate and interval columns.

- label:

  Name of the column identifying each row. `NULL` (default) picks the
  first of `group`, `compound`, `treatment`, `contrast`, `label` or
  `term` that is present.

- facet_by:

  One or two column names to facet on, or `NULL`.

- colour_by:

  Column mapped to colour, fill and shape, or `NULL`.

- method:

  Effect-size method to keep when `effects` carries a `method` column
  with several methods (default `"cohens_d"`).

- reference:

  Position of the null reference line (default `0`).

- order_by_estimate:

  Order rows by the estimate (default `TRUE`). `FALSE` keeps the order
  of `label`.

- descending:

  Order largest estimate at the top (default `FALSE`, which puts the
  most negative - typically the strongest protection - at the top).

- title, subtitle, x_lab, y_lab:

  Plot labels. `NULL` uses a computed default; `NA` omits the label.

## Value

A `ggplot` object.

## Details

The default subtitle states which intervals exclude the reference. It is
computed from the interval bounds for the same reason: the equivalent
sentence written by hand in the source pipeline stopped matching the
data the first time the data changed.

## See also

[`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md),
[`cr_plot_effect_sizes()`](https://cttir.github.io/cellreportR/reference/cr_plot_effect_sizes.md)

Other screen figures:
[`cr_plot_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc_gate.md),
[`cr_plot_sample_size()`](https://cttir.github.io/cellreportR/reference/cr_plot_sample_size.md),
[`cr_plot_screen()`](https://cttir.github.io/cellreportR/reference/cr_plot_screen.md),
[`cr_plot_specificity()`](https://cttir.github.io/cellreportR/reference/cr_plot_specificity.md),
[`cr_save_plot()`](https://cttir.github.io/cellreportR/reference/cr_save_plot.md)

## Examples

``` r
effects <- data.frame(
  group = c("CompoundA", "CompoundB", "CompoundC"),
  estimate = c(-1.2, -0.35, 0.1),
  ci_low = c(-1.9, -0.95, -0.4),
  ci_high = c(-0.5, 0.25, 0.6)
)
cr_plot_forest(effects)
```
