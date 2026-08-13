# Deployment shim for the cellreportR Shiny application.
#
# The user interface, the server and every helper live in the package
# namespace (R/shiny.R, R/shiny-ui.R, R/shiny-server.R,
# R/shiny-helpers.R) so that they can be driven in-process by
# shiny::testServer(). This file only assembles the app object, which is
# what a Shiny server evaluates when it runs the directory. Launch it
# from R with cellreportR::cr_run_app().
library(cellreportR)

# Segmented single-cell exports routinely exceed Shiny's 5 MB default;
# lift the cap as cr_run_app() does at runtime.
options(shiny.maxRequestSize = 512 * 1024^2)

cellreportR:::.cr_app()
