#' Launch the cellreportR Shiny application
#'
#' Launches the interactive Shiny application bundled with the
#' package. When `experiment` is `NULL`, the app loads synthetic
#' example data so that all tabs are usable out of the box.
#'
#' @param experiment Optional `cr_experiment` to load on startup.
#' @param launch_browser Whether to open a browser window (default
#'   `TRUE` in interactive sessions).
#' @param ... Further arguments passed to [shiny::runApp()].
#' @return Invisible `NULL`. Launches a Shiny application.
#' @export
#' @examples
#' \donttest{
#' if (interactive()) {
#'   cr_run_app()
#' }
#' }
cr_run_app <- function(experiment = NULL,
                       launch_browser = interactive(),
                       ...) {
  needed <- c("bslib", "DT", "plotly", "shinyWidgets")
  missing <- needed[!vapply(needed, function(p) {
    requireNamespace(p, quietly = TRUE)
  }, logical(1))]
  if (length(missing)) {
    cli::cli_abort(c(
      "The Shiny app requires additional packages.",
      "i" = "Install with: {.code install.packages(c({paste(sprintf('\\'%s\\'', missing), collapse = ', ')}))}"
    ))
  }
  app_dir <- system.file("shiny", "cellreportR", package = "cellreportR")
  if (!nzchar(app_dir)) {
    cli::cli_abort("Shiny app directory not found. Install the package first.")
  }
  if (!is.null(experiment)) {
    cr_validate_experiment(experiment)
    assign("CR_INITIAL_EXPERIMENT", experiment,
           envir = asNamespace("cellreportR"))
  } else {
    if (exists("CR_INITIAL_EXPERIMENT",
               envir = asNamespace("cellreportR"),
               inherits = FALSE)) {
      rm("CR_INITIAL_EXPERIMENT", envir = asNamespace("cellreportR"))
    }
  }
  shiny::runApp(app_dir, launch.browser = launch_browser, ...)
}
