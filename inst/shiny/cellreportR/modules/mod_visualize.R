mod_visualize_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::selectInput(ns("plot"), "Plot type",
                         choices = c("plate", "intensity", "scatter",
                                     "histogram", "qc", "spatial",
                                     "heatmap")),
      shinyWidgets::pickerInput(ns("channel"), "Channel", choices = NULL),
      shinyWidgets::pickerInput(ns("channel2"), "Channel 2 (scatter)",
                                choices = NULL),
      shiny::actionButton(ns("add"), "Add to report",
                          class = "btn-primary")
    ),
    bslib::card(bslib::card_header("Plot"),
                plotly::plotlyOutput(ns("plot_out"), height = "520px"))
  )
}

mod_visualize_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      shiny::req(state$experiment)
      chs <- cellreportR::cr_channels(state$experiment)
      shinyWidgets::updatePickerInput(session, "channel", choices = chs)
      shinyWidgets::updatePickerInput(session, "channel2", choices = chs,
                                      selected = chs[min(2, length(chs))])
    })

    current_plot <- shiny::reactive({
      shiny::req(state$experiment, input$channel)
      switch(
        input$plot,
        plate = cellreportR::cr_plot_plate(state$experiment, input$channel),
        intensity = cellreportR::cr_plot_intensity(state$experiment,
                                                   input$channel),
        scatter = cellreportR::cr_plot_scatter(state$experiment,
                                                input$channel, input$channel2),
        histogram = cellreportR::cr_plot_histogram(state$experiment,
                                                    input$channel),
        qc = cellreportR::cr_plot_qc(state$experiment, input$channel),
        spatial = cellreportR::cr_plot_spatial(state$experiment,
                                                input$channel),
        heatmap = cellreportR::cr_plot_heatmap(
          state$experiment,
          cellreportR::cr_channels(state$experiment)[
            seq_len(min(4, length(cellreportR::cr_channels(state$experiment))))
          ]
        )
      )
    })

    output$plot_out <- plotly::renderPlotly({
      plotly::ggplotly(current_plot())
    })

    shiny::observeEvent(input$add, {
      shiny::req(current_plot())
      nm <- paste(input$plot, input$channel, sep = "_")
      state$plots[[nm]] <- current_plot()
      shiny::showNotification(
        sprintf("Queued %s for report.", nm),
        type = "message")
    })
  })
}
