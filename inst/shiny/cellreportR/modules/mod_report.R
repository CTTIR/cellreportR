mod_report_ui <- function(id) {
  ns <- shiny::NS(id)
  bslib::layout_sidebar(
    sidebar = bslib::sidebar(
      shiny::textInput(ns("title"), "Title",
                       value = "cellreportR analysis"),
      shiny::textInput(ns("author"), "Author", value = ""),
      shiny::selectInput(ns("format"), "Format",
                         choices = c("html", "pdf")),
      shiny::downloadButton(ns("render"), "Download report",
                            class = "btn-primary"),
      shiny::hr(),
      shiny::downloadButton(ns("csv"), "Export results CSV"),
      shiny::downloadButton(ns("rds"), "Export experiment RDS"),
      shiny::downloadButton(ns("plots"), "Export queued plots")
    ),
    bslib::card(bslib::card_header("Queued plots"),
                DT::DTOutput(ns("plot_list"))),
    bslib::card(bslib::card_header("Analyses"),
                shiny::verbatimTextOutput(ns("analysis_list")))
  )
}

mod_report_server <- function(id, state) {
  shiny::moduleServer(id, function(input, output, session) {
    output$plot_list <- DT::renderDT({
      DT::datatable(
        data.frame(name = names(state$plots) %||% character()),
        options = list(pageLength = 8))
    })
    output$analysis_list <- shiny::renderPrint({
      if (!length(state$analyses)) cat("(none)")
      else cat(names(state$analyses), sep = "\n")
    })

    output$render <- shiny::downloadHandler(
      filename = function() paste0("cellreportR-report.", input$format),
      content = function(file) {
        shiny::req(state$experiment)
        out_dir <- tempdir()
        out <- cellreportR::cr_report(
          experiment = state$experiment,
          results = state$analyses,
          output_dir = out_dir,
          format = input$format,
          title = input$title,
          author = input$author
        )
        file.copy(out, file, overwrite = TRUE)
      }
    )

    output$csv <- shiny::downloadHandler(
      filename = function() "cellreportR-results.csv",
      content = function(file) {
        cellreportR::cr_export_results(state$analyses, file)
      }
    )

    output$rds <- shiny::downloadHandler(
      filename = function() "cellreportR-experiment.rds",
      content = function(file) saveRDS(state$experiment, file)
    )

    output$plots <- shiny::downloadHandler(
      filename = function() "cellreportR-plots.zip",
      content = function(file) {
        tmp <- tempfile("plots"); dir.create(tmp)
        cellreportR::cr_export_plots(state$plots, tmp)
        utils::zip(file,
                   files = list.files(tmp, full.names = TRUE),
                   flags = "-j")
      }
    )
  })
}
