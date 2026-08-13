# Interactive Analysis with the cellreportR Shiny App

The bundled application walks the same pipeline as the package functions
— read segmented exports, specify the design, apply quality control at
cell and unit level, standardize, estimate effect sizes with confidence
intervals at both levels, export a report — in a browser rather than in
a script. It is meant for laboratory personnel without an R background,
and for anyone who wants to look at a data set before writing the
script.

Every analytical step in the app delegates to an exported `cr_*`
function, so the app and a scripted analysis produce the same numbers.

## Launching

``` r

library(cellreportR)

cr_run_app()                      # starts empty; example data is one click away
cr_run_app(experiment = my_exp)   # start from an experiment already in session
```

[`cr_run_app()`](https://cttir.github.io/cellreportR/reference/cr_run_app.md)
needs `shiny`, `bslib`, `DT` and `ggplot2`, all of which are listed
under `Suggests`; a missing one raises an error naming it. The upload
limit is raised to 512 MB for the duration of the session, because
segmented single-cell exports routinely exceed the Shiny default of 5
MB, and the previous value is restored on exit.

``` r

args(cr_run_app)
#> function (experiment = NULL, max_upload_mb = 512, launch_browser = interactive(), 
#>     ...) 
#> NULL
```

## Layout

The page has four fixed regions:

- a **sidebar**, always visible, holding the three things every tab
  depends on — where the data comes from, which marker channel the
  analysis targets, and which level of the design is the control;
- a **status card** with a running log of what the app has done, so an
  analysis can be reconstructed afterwards;
- the **tab strip**, in analysis order;
- an **About** card.

### The sidebar

1.  **Data source** — upload one or more segmented exports, or type the
    path of a directory and let the app read it with a file pattern and
    an optional recursive scan. `Load example data` fills the app with a
    synthetic multi-compound screen
    ([`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md))
    when there is nothing to hand.
2.  **Design** — upload a design table (`.csv`, `.tsv` or `.xlsx`), or
    build one in the Design tab.
3.  **Analysis target** — the marker channel and the control level.
    Every tab downstream reads these two selectors, so changing the
    control level here changes what every later tab compares against.

The whole experiment can be downloaded as an `.rds` from the sidebar at
any point, which is the bridge from the app back to a script.

### The tabs

| Tab | What it does | Backed by |
|----|----|----|
| **Data** | Cell table, the files that were read, detected channels | [`cr_read_cells()`](https://cttir.github.io/cellreportR/reference/cr_read_cells.md), [`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md) |
| **Design** | Derive one design row per unit, assign treatment levels, build the experiment | [`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md) |
| **Quality control** | Cell filters, doublet removal, and the per-unit gate against each unit’s own control | [`cr_qc_filter()`](https://cttir.github.io/cellreportR/reference/cr_qc_filter.md), [`cr_qc_doublets()`](https://cttir.github.io/cellreportR/reference/cr_qc_doublets.md), [`cr_qc_gate()`](https://cttir.github.io/cellreportR/reference/cr_qc_gate.md), [`cr_apply_gate()`](https://cttir.github.io/cellreportR/reference/cr_apply_gate.md) |
| **Normalisation** | Robust z-score, z-score, control ratio, background subtraction or quantile, optionally within a batch variable | [`cr_normalize()`](https://cttir.github.io/cellreportR/reference/cr_normalize.md), [`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md) |
| **Effect sizes** | Forest plot and effect table at unit or cell level | [`cr_effect_grid()`](https://cttir.github.io/cellreportR/reference/cr_effect_grid.md), [`cr_plot_forest()`](https://cttir.github.io/cellreportR/reference/cr_plot_forest.md) |
| **Dose-response** | 4PL / 3PL / linear fit with the fitted parameters | [`cr_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_dose_response.md), [`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md) |
| **Figures** | Plate map, intensity by treatment, histogram, QC dashboard, spatial map | [`cr_plot_plate()`](https://cttir.github.io/cellreportR/reference/cr_plot_plate.md) and friends |
| **Report** | Pairwise comparisons, queued figures, and the exported report | [`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md), [`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md) |

The Quality control tab is the one worth spending time in. Its
sub-panels are the exclusion table, the disputed verdicts (units whose
verdict depends on whether the control’s median or mean is used as the
threshold), the gate figure, the area distribution and the QC log. Rows
selected in the exclusion table are dropped together with the units that
fail the gate, which is the interactive form of the reviewed exclusion
list shown in
[`vignette("end-to-end")`](https://cttir.github.io/cellreportR/articles/end-to-end.md).

## Cross-tab state

The app keeps everything it knows in one
[`shiny::reactiveValues()`](https://rdrr.io/pkg/shiny/man/reactiveValues.html)
store: the cells, the design, the assembled experiment, the state it was
imported in, the gate, the effect grid, the results and the queued
figures. Quality control, normalisation and analysis replace the
experiment in that store, so every downstream tab reacts without any tab
reaching into another.

Two consequences worth knowing:

- **Reset is real.** `Reset to imported state` in the Quality control
  and Normalisation tabs restores the experiment as it was imported, not
  the previous step.
- **Figures are queued, not saved.** `Queue for report` adds the current
  figure to the report assembly; the Report tab exports the queue.

## Deployment

The user interface, the server and every helper live inside the package
namespace, so the app can be driven in-process by
[`shiny::testServer()`](https://rdrr.io/pkg/shiny/man/testServer.html)
as well as from a browser. `inst/shiny/cellreportR/` holds only the
`www/` assets and a thin `app.R` shim for deployment on a Shiny server.
