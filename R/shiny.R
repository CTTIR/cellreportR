#' Launch the cellreportR Shiny application
#'
#' Starts the interactive front-end bundled with the package. The app
#' covers the whole analysis path in one place: point it at a
#' directory of segmented exports (or upload the files), specify or
#' edit the design, review quality control with a per-unit exclusion
#' table, choose a normalisation, estimate effect sizes as a table
#' plus forest plot, and export a report.
#'
#' The user interface, the server and every helper live inside the
#' package namespace, so the app can be driven in-process by
#' [shiny::testServer()] as well as from a browser. The directory under
#' `inst/shiny/cellreportR/` holds the `www/` assets and a thin `app.R`
#' shim for deployment on a Shiny server.
#'
#' Requires the `shiny`, `bslib`, `DT` and `ggplot2` packages, all
#' listed under `Suggests`. An informative error naming the missing
#' package is raised when any of them is unavailable.
#'
#' @param experiment Optional `cr_experiment` to load on start-up. It
#'   is validated with [cr_validate_experiment()] before the app is
#'   built and handed to the server through the app object, so no
#'   global state is involved. When `NULL` (default) the app starts
#'   empty and offers synthetic example data.
#' @param report_spec Optional [cr_report_spec()] used to pre-populate the
#'   laboratory-report workflow.
#' @param max_upload_mb Numeric. Maximum upload size per request, in
#'   megabytes. Segmented single-cell exports routinely exceed the
#'   Shiny default of 5 MB; this argument raises the limit for the
#'   duration of the running app and restores the previous value on
#'   exit. Default `512` MB.
#' @param launch_browser Whether to open a browser window. Defaults to
#'   `TRUE` in interactive sessions.
#' @param ... Further arguments passed to [shiny::runApp()].
#'
#' @return Invoked for its side effect of running the app. Returns
#'   whatever [shiny::runApp()] returns, invisibly.
#'
#' @examples
#' if (interactive()) {
#'   cr_run_app()
#' }
#'
#' # Start from an experiment that is already in the session:
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' if (interactive()) {
#'   cr_run_app(exp)
#' }
#'
#' @seealso [cr_build_experiment()], [cr_report()]
#' @family cellreportR-app
#' @export
cr_run_app <- function(experiment = NULL,
                       report_spec = NULL,
                       max_upload_mb = 512,
                       launch_browser = interactive(),
                       ...) {
  for (pkg in c("shiny", "bslib", "DT", "ggplot2")) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      cli::cli_abort(c(
        "Package {.pkg {pkg}} is required to run {.fn cr_run_app}.",
        i = "Install it with {.code install.packages(\"{pkg}\")}."
      ))
    }
  }
  if (!is.numeric(max_upload_mb) || length(max_upload_mb) != 1L ||
      is.na(max_upload_mb) || max_upload_mb <= 0) {
    cli::cli_abort(c(
      "{.arg max_upload_mb} must be a single positive number.",
      "x" = "Got {.cls {class(max_upload_mb)[[1L]]}} of length {length(max_upload_mb)}."
    ))
  }
  if (!is.null(experiment)) {
    cr_validate_experiment(experiment)
  }
  if (!is.null(report_spec)) cr_validate_report_spec(report_spec, strict = FALSE)
  old <- options(shiny.maxRequestSize = max_upload_mb * 1024^2)
  on.exit(options(old), add = TRUE)
  invisible(shiny::runApp(.cr_app(experiment, report_spec),
                          launch.browser = launch_browser, ...))
}


# Build (but do not run) the Shiny app object. Shared by cr_run_app(),
# by the deployment shim in inst/shiny/cellreportR/app.R and by the
# shinytest2 harness under tests/testthat/apps/cellreportR/.
.cr_app <- function(experiment = NULL, report_spec = NULL) {
  shiny::shinyApp(
    ui = .cr_app_ui(),
    server = function(input, output, session) {
      .cr_app_server(input, output, session, experiment = experiment,
                     report_spec = report_spec)
    }
  )
}


# Register inst/shiny/cellreportR/www under the "cr_www" prefix so the
# logo and the stylesheet resolve from a browser. Returns TRUE when the
# directory was found; the UI stays functional (unstyled) if it was not,
# which happens when the package is loaded from source without inst/.
.cr_app_resources <- function() {
  dir <- system.file("shiny", "cellreportR", "www", package = "cellreportR")
  if (!nzchar(dir) || !dir.exists(dir)) {
    return(FALSE)
  }
  shiny::addResourcePath("cr_www", dir)
  TRUE
}


# bslib theme. The light variant is the default; the dark variant backs
# the navbar toggle on bslib versions that provide input_dark_mode().
.cr_app_theme <- function(dark = FALSE) {
  base <- list(
    version = 5,
    base_font = bslib::font_collection(
      "system-ui", "-apple-system", "BlinkMacSystemFont",
      "Segoe UI", "Roboto", "Helvetica Neue", "Arial", "sans-serif"
    ),
    code_font = bslib::font_collection(
      "SF Mono", "Consolas", "Liberation Mono", "Menlo", "monospace"
    ),
    "border-radius" = "0.25rem"
  )
  extra <- if (isTRUE(dark)) {
    list(
      bg = "#1e1b21", fg = "#e6e1e9",
      primary = "#c49ad4", secondary = "#9e8fa6",
      success = "#8fbf9f", info = "#8fa9bf",
      warning = "#d8b98a", danger = "#d89a9a",
      "border-color" = "#3a3440",
      "card-border-color" = "#3a3440",
      "card-cap-bg" = "#282430",
      "body-bg" = "#1e1b21",
      "body-color" = "#e6e1e9"
    )
  } else {
    list(
      bg = "#fdfcfe", fg = "#2c2c2c",
      primary = "#7b2d8e", secondary = "#6b6b6b",
      success = "#2f6b46", info = "#2f556b",
      warning = "#8a6100", danger = "#8e2d2d",
      "border-color" = "#e2dde6",
      "card-border-color" = "#e2dde6",
      "card-cap-bg" = "#f5f0f7",
      "body-bg" = "#fdfcfe",
      "body-color" = "#2c2c2c"
    )
  }
  do.call(bslib::bs_theme, c(base, extra))
}


# Dark-mode switch, only on bslib versions that ship one.
.cr_dark_toggle <- function(id = "dark_mode") {
  if (!"input_dark_mode" %in% getNamespaceExports("bslib")) {
    return(NULL)
  }
  bslib::input_dark_mode(id = id, mode = "light")
}

# Version 0.1.0
