mod_import_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::fileInput(ns("cells_file"),
                       "Cells (CSV/TSV/RDS)",
                       accept = c(".csv", ".tsv", ".rds")),
      shiny::fileInput(ns("design_file"),
                       "Design (CSV/XLSX)",
                       accept = c(".csv", ".xlsx")),
      shiny::actionButton(ns("load_example"),
                          "Load Example Data",
                          class = "btn-primary"),
      shiny::hr(),
      shiny::uiOutput(ns("status"))
    ),
    bslib::card(
      bslib::card_header("Cells preview"),
      DT::DTOutput(ns("cells_tbl"))
    ),
    bslib::card(
      bslib::card_header("Design preview"),
      DT::DTOutput(ns("design_tbl"))
    ),
    bslib::card(
      bslib::card_header("Detected channels"),
      shiny::verbatimTextOutput(ns("channels"))
    )
  )
}

mod_import_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    ns <- session$ns

    shiny::observeEvent(input$load_example, {
      state$experiment <- cr_app_load_example()
    })

    shiny::observeEvent(input$cells_file, {
      shiny::req(input$cells_file)
      cells <- tryCatch(
        cellreportR::cr_read_cells(input$cells_file$datapath),
        error = function(e) NULL
      )
      if (is.null(cells)) {
        shiny::showNotification("Failed to read cells file.", type = "error")
        return(NULL)
      }
      if (is.null(input$design_file)) {
        shiny::showNotification(
          "Upload a design file to assemble the experiment.",
          type = "warning")
        return(NULL)
      }
      design <- tryCatch(
        cellreportR::cr_read_design(input$design_file$datapath),
        error = function(e) NULL
      )
      if (is.null(design)) {
        shiny::showNotification("Failed to read design file.", type = "error")
        return(NULL)
      }
      exp <- tryCatch(
        cellreportR::cr_build_experiment(cells, design),
        error = function(e) e
      )
      if (inherits(exp, "error")) {
        shiny::showNotification(
          paste0("Validation failed: ", exp$message),
          type = "error", duration = 8
        )
        return(NULL)
      }
      state$experiment <- exp
    })

    output$cells_tbl <- DT::renderDT({
      shiny::req(state$experiment)
      DT::datatable(utils::head(state$experiment$cells, 100),
                    options = list(scrollX = TRUE, pageLength = 10))
    })

    output$design_tbl <- DT::renderDT({
      shiny::req(state$experiment)
      DT::datatable(state$experiment$design,
                    options = list(scrollX = TRUE, pageLength = 10))
    })

    output$channels <- shiny::renderPrint({
      shiny::req(state$experiment)
      print(state$experiment$channels)
    })

    output$status <- shiny::renderUI({
      if (is.null(state$experiment)) {
        shiny::tags$em("No experiment loaded.")
      } else {
        shiny::tags$div(
          shiny::tags$b(style = "color:#7B2D8E;", "Loaded"),
          shiny::br(),
          sprintf("%s cells / %s wells",
                  nrow(state$experiment$cells),
                  length(unique(state$experiment$cells[[state$experiment$spatial_unit]])))
        )
      }
    })
  })
}
