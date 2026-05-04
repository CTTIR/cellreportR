# cellreportR — interactive Shiny analyser
source("global.R", local = TRUE)

ui <- bslib::page_navbar(
  title = shiny::tagList(
    shiny::tags$img(
      src = "logo.png",
      height = "32px",
      style = "margin-right: 10px;",
      onerror = "this.style.display='none'"
    ),
    "cellreportR"
  ),
  theme = cr_theme,
  id = "main_tabs",
  bslib::nav_panel("Import & Design",
                   mod_import_ui("import")),
  bslib::nav_panel("Quality Control",
                   mod_qc_ui("qc")),
  bslib::nav_panel("Normalization",
                   mod_normalize_ui("norm")),
  bslib::nav_panel("Statistical Analysis",
                   mod_analysis_ui("stats")),
  bslib::nav_panel("Dose-Response",
                   mod_doseresponse_ui("dr")),
  bslib::nav_panel("Visualization",
                   mod_visualize_ui("viz")),
  bslib::nav_panel("Report & Export",
                   mod_report_ui("rep")),
  footer = shiny::tags$div(
    style = "padding: 8px 16px; background: #f5f0f7; border-top: 1px solid #ddd;",
    shiny::uiOutput("status_bar")
  )
)

server <- function(input, output, session) {
  state <- shiny::reactiveValues(
    experiment = NULL,
    analyses = list(),
    dose_fit = NULL,
    plots = list()
  )

  # Load initial experiment from cellreportR namespace if set
  shiny::observe({
    if (exists("CR_INITIAL_EXPERIMENT",
               envir = asNamespace("cellreportR"),
               inherits = FALSE)) {
      state$experiment <- get("CR_INITIAL_EXPERIMENT",
                              envir = asNamespace("cellreportR"))
    } else {
      state$experiment <- cr_app_load_example()
    }
  })

  mod_import_server("import", state)
  mod_qc_server("qc", state)
  mod_normalize_server("norm", state)
  mod_analysis_server("stats", state)
  mod_doseresponse_server("dr", state)
  mod_visualize_server("viz", state)
  mod_report_server("rep", state)

  output$status_bar <- shiny::renderUI({
    exp <- state$experiment
    if (is.null(exp)) {
      shiny::tags$em("No experiment loaded.")
    } else {
      shiny::tags$div(
        shiny::tags$b("Experiment:"),
        sprintf(" %s cells / %s wells  |  QC steps: %s  |  Analyses queued: %s",
                nrow(exp$cells),
                length(unique(exp$cells[[exp$spatial_unit]])),
                nrow(exp$qc_log),
                length(state$analyses))
      )
    }
  })
}

shiny::shinyApp(ui, server)
