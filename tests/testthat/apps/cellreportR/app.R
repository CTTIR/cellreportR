# Returns the cellreportR Shiny app object (not run), in the layout a
# shinytest2::AppDriver harness expects.
#
# NOTE: no automated test drives this file. The server layer is covered
# in-process by tests/testthat/test-shiny-server.R via shiny::testServer(),
# which needs no browser. Keep this app only if a browser-level harness is
# actually going to be written; otherwise it and the `shinytest2` entry in
# DESCRIPTION Suggests can both go.
library(cellreportR)
# Segmented exports routinely exceed Shiny's 5 MB default; lift the cap as
# cr_run_app() does at runtime.
options(shiny.maxRequestSize = 512 * 1024^2)
cellreportR:::.cr_app()
