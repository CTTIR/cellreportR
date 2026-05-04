mod_normalize_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shinyWidgets::pickerInput(ns("channel"), "Channel", choices = NULL),
      shiny::selectInput(ns("method"), "Method",
                         choices = c("robust_zscore", "zscore",
                                     "background", "control", "quantile")),
      shinyWidgets::pickerInput(ns("control"), "Control group (if control)",
                                choices = NULL),
      shiny::actionButton(ns("apply"), "Apply normalization",
                          class = "btn-primary")
    ),
    bslib::card(bslib::card_header("Before / after"),
                shiny::plotOutput(ns("compare")))
  )
}

mod_normalize_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    shiny::observe({
      shiny::req(state$experiment)
      shinyWidgets::updatePickerInput(
        session, "channel",
        choices = cellreportR::cr_channels(state$experiment)
      )
      shinyWidgets::updatePickerInput(
        session, "control",
        choices = unique(state$experiment$design$treatment)
      )
    })

    before <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$apply, {
      shiny::req(state$experiment, input$channel)
      before(state$experiment$cells[[input$channel]])
      ctrl <- input$control
      state$experiment <- tryCatch(
        cellreportR::cr_normalize(
          state$experiment,
          channel = input$channel,
          method = input$method,
          control_group = if (input$method == "control") ctrl else NULL
        ),
        error = function(e) { shiny::showNotification(e$message,
                                                      type = "error")
          state$experiment })
    })

    output$compare <- shiny::renderPlot({
      shiny::req(state$experiment, input$channel)
      after <- state$experiment$cells[[input$channel]]
      bef <- before() %||% after
      df <- rbind(
        data.frame(stage = "before", value = bef),
        data.frame(stage = "after",  value = after)
      )
      ggplot2::ggplot(df, ggplot2::aes(x = .data$stage, y = .data$value,
                                       fill = .data$stage)) +
        ggplot2::geom_violin(scale = "width") +
        ggplot2::scale_fill_manual(values = c("#9B59B6", "#7B2D8E")) +
        ggplot2::theme_minimal() +
        ggplot2::labs(x = NULL, y = input$channel) +
        ggplot2::theme(legend.position = "none")
    })
  })
}

`%||%` <- function(a, b) if (is.null(a)) b else a
