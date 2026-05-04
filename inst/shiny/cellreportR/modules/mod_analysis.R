mod_analysis_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shinyWidgets::pickerInput(ns("channel"), "Channel", choices = NULL),
      shinyWidgets::pickerInput(ns("control"), "Control group",
                                choices = NULL),
      shiny::selectInput(ns("test"), "Test",
                         choices = c("mann_whitney", "t_test",
                                     "welch", "wilcoxon_signed")),
      shiny::radioButtons(ns("level"), "Level",
                          choices = c("replicate", "cell", "both"),
                          inline = TRUE),
      shiny::actionButton(ns("run"), "Run analysis",
                          class = "btn-primary")
    ),
    bslib::card(bslib::card_header("Summary table"),
                DT::DTOutput(ns("summary_tbl"))),
    bslib::card(bslib::card_header("Effect sizes"),
                shiny::plotOutput(ns("eff_plot"))),
    bslib::card(bslib::card_header("Fold changes"),
                shiny::plotOutput(ns("fc_plot")))
  )
}

mod_analysis_server <- function(id, state) {
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

    result <- shiny::reactiveVal(NULL)

    shiny::observeEvent(input$run, {
      shiny::req(state$experiment, input$channel, input$control)
      res <- tryCatch(
        cellreportR::cr_test_all(
          state$experiment,
          channel = input$channel,
          control_group = input$control,
          tests = input$test,
          level = input$level
        ),
        error = function(e) {
          shiny::showNotification(e$message, type = "error"); NULL
        }
      )
      if (!is.null(res)) {
        result(res)
        nm <- paste0("ch_", input$channel)
        state$analyses[[nm]] <- res
      }
    })

    output$summary_tbl <- DT::renderDT({
      shiny::req(result())
      s <- attr(result(), "summary")
      DT::datatable(s, options = list(pageLength = 10, scrollX = TRUE)) |>
        DT::formatSignif(columns = c("log2_fc", "p_value", "p_adj",
                                     "cohens_d"),
                         digits = 3)
    })

    output$eff_plot <- shiny::renderPlot({
      shiny::req(result())
      cellreportR::cr_plot_effect_sizes(result())
    })

    output$fc_plot <- shiny::renderPlot({
      shiny::req(result())
      cellreportR::cr_plot_foldchange(result())
    })
  })
}
