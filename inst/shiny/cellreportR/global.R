# cellreportR shiny app — global setup

# Namespace-qualify every call; no library() here.
cr_theme <- bslib::bs_theme(
  version = 5,
  bg = "#FFFFFF",
  fg = "#2C2C2C",
  primary = "#7B2D8E",
  secondary = "#9B59B6",
  base_font = bslib::font_google("Inter"),
  heading_font = bslib::font_google("Inter")
)

cr_app_load_example <- function() {
  cellreportR::cr_example_experiment(seed = 42, n_cells_per_well = 60)
}

# Source modules
for (m in c("mod_import.R", "mod_qc.R", "mod_normalize.R",
            "mod_analysis.R", "mod_doseresponse.R",
            "mod_visualize.R", "mod_report.R")) {
  source(file.path("modules", m), local = FALSE, chdir = TRUE)
}
