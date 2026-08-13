# Distribution figure with the unit of replication overlaid

Draws width-scaled violins of the cell-level value for each group, with
the per-unit means overplotted as jittered points. Cells are the
observations; the unit (well, slide or merged acquisition) is the unit
of replication, and drawing both in one panel is what keeps a reader
from reading cell counts as replicate counts.

## Usage

``` r
cr_plot_screen(
  cells,
  value = "log2_fc",
  group_var = "treatment",
  units = NULL,
  unit_value = NULL,
  facet_by = NULL,
  colour_by = NULL,
  reference = 0,
  seed = NULL,
  title = NULL,
  subtitle = NULL,
  x_lab = NA,
  y_lab = NULL
)
```

## Arguments

- cells:

  Cell-level data: a data frame, or a `cr_experiment` whose cells are
  joined to its design.

- value:

  Name of the cell-level value column, typically a standardised value
  such as a log fold change (default `"log2_fc"`).

- group_var:

  Name of the column defining the x-axis groups (default `"treatment"`).

- units:

  Unit-level data. Either a data frame of one row per unit, or the name
  of a column in `cells` identifying the unit, in which case the
  per-unit means are computed. `NULL` draws the violins alone.

- unit_value:

  Name of the unit-level value column. Defaults to `value`.

- facet_by:

  One or two column names to facet on, or `NULL`.

- colour_by:

  Column mapped to fill and shape. `NULL` (default) draws a single
  colour, because hue that encodes nothing is decoration.

- reference:

  Horizontal reference line, or `NULL` for none (default `0`, the null
  of a log fold change).

- seed:

  Integer seed for the point jitter, so the figure reproduces.

- title, subtitle, x_lab, y_lab:

  Plot labels. `NULL` uses a computed default; `NA` omits the label.

## Value

A `ggplot` object.

## Details

The point layer is drawn with a fixed jitter seed so the figure is
reproducible, and the subtitle states which layer is the unit of
replication rather than leaving it to the caption.

## See also

[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md),
[`cr_theme()`](https://cttir.github.io/cellreportR/reference/cr_theme.md),
[`cr_scale_group()`](https://cttir.github.io/cellreportR/reference/cr_scale_group.md)

Other screen figures:
[`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md),
[`cr_plot_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_plot_qc_gate.md),
[`cr_plot_sample_size()`](https://cttir.github.io/cellreportR/reference/cr_plot_sample_size.md),
[`cr_plot_specificity()`](https://cttir.github.io/cellreportR/reference/cr_plot_specificity.md),
[`cr_save_plot()`](https://cttir.github.io/cellreportR/reference/cr_save_plot.md)

## Examples

``` r
set.seed(1)
cells <- data.frame(
  treatment = rep(c("Vehicle", "CompoundA", "CompoundB"), each = 120),
  well_id = rep(paste0("W", 1:18), each = 20),
  log2_fc = c(rnorm(120, 0, 0.5), rnorm(120, -0.8, 0.5),
              rnorm(120, -0.2, 0.5))
)
cr_plot_screen(cells, group_var = "treatment", units = "well_id", seed = 1)
```
