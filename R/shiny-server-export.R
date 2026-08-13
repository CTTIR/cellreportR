# Every download handler of the Shiny application, in one place.
# Registered by .cr_app_server() with the reactives the analysis tabs
# returned, so a figure a user is looking at is the figure they get.

.cr_srv_downloads <- function(input, output, session, ctx,
                              forest, figure, dose, report) {
  state <- ctx$state

  stamp <- function(ext) {
    paste0("cellreportR_", format(Sys.time(), "%Y%m%d_%H%M%S"), ext)
  }

  save_png <- function(plot, file) {
    ggplot2::ggsave(file, plot, device = "png",
                    width = input$plot_w_in %||% 10,
                    height = input$plot_h_in %||% 6,
                    dpi = input$plot_dpi %||% 300, units = "in")
  }

  output$dl_experiment <- shiny::downloadHandler(
    filename = function() stamp("_experiment.rds"),
    content = function(file) {
      shiny::req(state$experiment)
      saveRDS(state$experiment, file)
    }
  )

  output$dl_units <- shiny::downloadHandler(
    filename = function() stamp("_qc_units.csv"),
    content = function(file) {
      gate <- state$gate
      readr::write_csv(
        if (is.null(gate)) {
          tibble::tibble(note = "no gate evaluated")
        } else {
          cr_table_qc(gate)
        },
        file
      )
    }
  )

  output$dl_effects <- shiny::downloadHandler(
    filename = function() stamp("_effect_sizes.csv"),
    content = function(file) {
      shiny::req(state$effects)
      readr::write_csv(state$effects, file)
    }
  )

  output$dl_forest <- shiny::downloadHandler(
    filename = function() stamp("_forest.png"),
    content = function(file) save_png(forest(), file)
  )

  output$dl_dose <- shiny::downloadHandler(
    filename = function() stamp("_dose_response.png"),
    content = function(file) save_png(dose(), file)
  )

  output$dl_plot <- shiny::downloadHandler(
    filename = function() {
      stamp(paste0("_", input$plot_type %||% "figure", ".png"))
    },
    content = function(file) save_png(figure(), file)
  )

  output$dl_results <- shiny::downloadHandler(
    filename = function() stamp("_results.csv"),
    content = function(file) {
      rep <- tryCatch(report(), error = function(e) NULL)
      tbl <- if (!is.null(rep) && !is.null(rep$summary) &&
                 nrow(rep$summary)) {
        rep$summary
      } else if (!is.null(state$effects)) {
        state$effects
      } else {
        tibble::tibble(note = "no results yet")
      }
      readr::write_csv(tbl, file)
    }
  )

  output$dl_plots_zip <- shiny::downloadHandler(
    filename = function() stamp("_figures.zip"),
    content = function(file) {
      plots <- state$plots
      shiny::req(length(plots) > 0)
      tmp <- tempfile("cr_figures_")
      dir.create(tmp)
      on.exit(unlink(tmp, recursive = TRUE), add = TRUE)
      for (nm in names(plots)) {
        save_png(plots[[nm]],
                 file.path(tmp, paste0(gsub("[^A-Za-z0-9_-]", "_", nm),
                                       ".png")))
      }
      utils::zip(file, files = list.files(tmp, full.names = TRUE),
                 flags = "-j")
    }
  )

  output$dl_report <- shiny::downloadHandler(
    filename = function() {
      stamp(paste0("_report.", input$rep_format %||% "html"))
    },
    content = function(file) {
      out_dir <- tempfile("cr_report_")
      dir.create(out_dir)
      on.exit(unlink(out_dir, recursive = TRUE), add = TRUE)
      out <- cr_render_report(report(), output_dir = out_dir,
                              format = input$rep_format %||% "html")
      file.copy(out, file, overwrite = TRUE)
    }
  )

  invisible(NULL)
}

# Version 0.1.0
