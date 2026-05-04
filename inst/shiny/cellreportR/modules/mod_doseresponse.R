mod_doseresponse_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shinyWidgets::pickerInput(ns("channel"), "Channel", choices = NULL),
      shiny::selectInput(ns("model"), "Model",
                         choices = c("4pl", "3pl", "linear")),
      shiny::checkboxInput(ns("log_dose"), "Log dose", value = TRUE),
      shiny::actionButton(ns("fit"), "Fit", class = "btn-primary")
    ),
    bslib::card(bslib::card_header("Dose-response"),
                shiny::plotOutput(ns("plot"))),
    bslib::card(bslib::card_header("Parameters"),
                DT::DTOutput(ns("params")))
  )
}

mod_doseresponse_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      shiny::req(state$experiment)
      shinyWidgets::updatePickerInput(
        session, "channel",
        choices = cellreportR::cr_channels(state$experiment)
      )
    })

    fit <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$fit, {
      shiny::req(state$experiment, input$channel)
      f <- tryCatch(
        cellreportR::cr_dose_response(
          state$experiment,
          channel = input$channel,
          model = input$model,
          log_dose = input$log_dose
        ),
        error = function(e) {
          shiny::showNotification(e$message, type = "error"); NULL
        }
      )
      if (!is.null(f)) {
        fit(f)
        state$dose_fit <- f
      }
    })

    output$plot <- shiny::renderPlot({
      shiny::req(fit())
      cellreportR::cr_plot_dose_response(fit())
    })
    output$params <- DT::renderDT({
      shiny::req(fit())
      DT::datatable(fit()$params,
                    options = list(pageLength = 5))
    })
  })
}
