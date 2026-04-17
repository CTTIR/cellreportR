# Launch the cellreportR Shiny application

Launches the interactive Shiny application bundled with the package.
When `experiment` is `NULL`, the app loads synthetic example data so
that all tabs are usable out of the box.

## Usage

``` r
cr_run_app(experiment = NULL, launch_browser = interactive(), ...)
```

## Arguments

- experiment:

  Optional `cr_experiment` to load on startup.

- launch_browser:

  Whether to open a browser window (default `TRUE` in interactive
  sessions).

- ...:

  Further arguments passed to
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html).

## Value

Invisible `NULL`. Launches a Shiny application.

## Examples

``` r
# \donttest{
if (interactive()) {
  cr_run_app()
}
# }
```
