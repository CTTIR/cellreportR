mod_qc_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::numericInput(ns("min_area"), "Min area", 0),
      shiny::numericInput(ns("max_area"), "Max area", 1e5),
      shiny::numericInput(ns("min_circ"), "Min circularity", 0, min = 0, max = 1,
                          step = 0.05),
      shiny::numericInput(ns("dbl_k"), "Doublet multiple of median area",
                          2.5, min = 1.1, step = 0.1),
      shiny::actionButton(ns("apply_qc"), "Apply QC",
                          class = "btn-primary"),
      shiny::actionButton(ns("reset_qc"), "Reset QC"),
      shiny::hr(),
      shiny::uiOutput(ns("counter"))
    ),
    bslib::card(bslib::card_header("Area distribution"),
                shiny::plotOutput(ns("area_plot"), height = "260px")),
    bslib::card(bslib::card_header("QC log"),
                DT::DTOutput(ns("qc_log")))
  )
}

mod_qc_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    original <- shiny::reactiveVal(NULL)

    shiny::observe({
      shiny::req(state$experiment)
      if (is.null(original())) original(state$experiment)
    })

    shiny::observeEvent(input$apply_qc, {
      shiny::req(state$experiment)
      exp <- state$experiment
      exp <- cellreportR::cr_qc_filter(
        exp,
        min_area = input$min_area,
        max_area = input$max_area,
        min_circularity = input$min_circ
      )
      exp <- cellreportR::cr_qc_doublets(exp, k = input$dbl_k)
      state$experiment <- exp
    })

    shiny::observeEvent(input$reset_qc, {
      shiny::req(original())
      state$experiment <- original()
    })

    output$area_plot <- shiny::renderPlot({
      shiny::req(state$experiment)
      ggplot2::ggplot(state$experiment$cells,
                      ggplot2::aes(x = .data$area)) +
        ggplot2::geom_histogram(bins = 60, fill = "#7B2D8E",
                                alpha = 0.8) +
        ggplot2::scale_x_log10() +
        ggplot2::theme_minimal() +
        ggplot2::labs(x = "area", y = "cells")
    })

    output$qc_log <- DT::renderDT({
      shiny::req(state$experiment)
      DT::datatable(state$experiment$qc_log,
                    options = list(pageLength = 5, scrollX = TRUE))
    })

    output$counter <- shiny::renderUI({
      shiny::req(state$experiment)
      n <- nrow(state$experiment$cells)
      n0 <- if (!is.null(original())) nrow(original()$cells) else n
      shiny::tags$div(
        shiny::tags$b("Cells remaining"),
        shiny::br(),
        sprintf("%d / %d (%.1f%%)", n, n0, 100 * n / max(n0, 1))
      )
    })
  })
}
