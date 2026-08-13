# Quality-control and normalisation tabs of the Shiny application.
# Registered by .cr_app_server(); see R/shiny-server.R for the shared
# context object.


# ---- quality control ---------------------------------------------------

.cr_srv_qc <- function(input, output, session, ctx) {
  state <- ctx$state

  shiny::observeEvent(input$btn_gate, {
    exp <- state$experiment
    shiny::req(exp, input$sel_channel, input$sel_control)
    gate <- tryCatch(
      cr_qc_gate(
        exp,
        channel = input$sel_channel,
        control_level = input$sel_control,
        batch_vars = if (length(input$qc_batch)) input$qc_batch else NULL,
        statistic = input$qc_statistic %||% "median",
        reference = input$qc_reference %||% "median",
        direction = input$qc_direction %||% "greater",
        min_cells = max(1L, as.integer(input$qc_min_cells %||% 1L))
      ),
      error = function(e) ctx$fail(e, "Quality-control gate")
    )
    if (is.null(gate)) {
      return()
    }
    state$gate <- gate
    ctx$log(sprintf(
      "Gate evaluated: %d unit(s) fail, %d disputed by control centre.",
      length(gate$excluded), nrow(gate$disputed)
    ))
  })

  output$msg_qc <- shiny::renderUI({
    if (is.null(state$experiment)) {
      return(shiny::div(
        class = "alert alert-secondary",
        "Build an experiment first; quality control needs cells and a ",
        "design."
      ))
    }
    gate <- state$gate
    if (is.null(gate)) {
      return(shiny::div(
        class = "alert alert-secondary",
        "Evaluate the gate to compare every unit against the control of ",
        "its own batch. Median against median is the like-for-like ",
        "comparison; the mean of a right-skewed signal sits higher and ",
        "makes the gate stricter than it claims to be."
      ))
    }
    if (!length(gate$excluded)) {
      return(shiny::div(class = "alert alert-secondary",
                        "No unit fails the gate."))
    }
    shiny::div(
      class = "alert alert-warning",
      shiny::strong(sprintf("%d unit(s) fail the gate",
                            length(gate$excluded))),
      sprintf(", %d of which change verdict with the control centre. ",
              nrow(gate$disputed)),
      "Applying quality control removes their cells and records the step ",
      "in the log."
    )
  })

  output$tbl_units <- DT::renderDT({
    gate <- state$gate
    if (is.null(gate)) {
      return(.cr_dt(tibble::tibble(unit = character(0))))
    }
    .cr_dt(gate$units, page = 15L, selection = "multiple")
  })

  output$tbl_disputed <- DT::renderDT({
    gate <- state$gate
    if (is.null(gate) || !nrow(gate$disputed)) {
      return(.cr_dt(tibble::tibble(
        note = "No unit's verdict depends on the control centre."
      )))
    }
    .cr_dt(gate$disputed, page = 10L)
  })

  output$plt_gate <- shiny::renderPlot({
    gate <- state$gate
    if (is.null(gate)) {
      return(.cr_app_blank_plot("Evaluate the gate to see this figure."))
    }
    tryCatch(cr_plot_qc_gate(gate),
             error = function(e) .cr_app_blank_plot(conditionMessage(e)))
  })

  output$tbl_qc_log <- DT::renderDT({
    exp <- state$experiment
    shiny::req(exp)
    .cr_dt(cr_qc_summary(exp))
  })

  output$plt_area <- shiny::renderPlot({
    exp <- state$experiment
    if (is.null(exp) || !"area" %in% names(exp$cells)) {
      return(.cr_app_blank_plot(
        "No segmentation area column in the imported cells."))
    }
    ggplot2::ggplot(exp$cells, ggplot2::aes(x = .data$area)) +
      ggplot2::geom_histogram(bins = 60, fill = "#7b2d8e", alpha = 0.85) +
      ggplot2::scale_x_log10() +
      ggplot2::labs(x = "segmentation area", y = "cells") +
      ggplot2::theme_minimal(base_size = 12)
  })

  shiny::observeEvent(input$btn_qc_apply, {
    exp <- state$experiment
    shiny::req(exp)
    before <- nrow(exp$cells)
    out <- tryCatch({
      e <- cr_qc_filter(
        exp,
        min_area = input$qc_min_area %||% NA,
        max_area = input$qc_max_area %||% NA,
        min_circularity = input$qc_min_circ %||% NA
      )
      if (isTRUE(input$qc_doublets)) {
        e <- cr_qc_doublets(e, k = input$qc_doublet_k %||% 2.5)
      }
      gate <- state$gate
      if (!is.null(gate)) {
        picked <- input$tbl_units_rows_selected
        extra <- if (length(picked)) {
          as.character(gate$units[[gate$params$unit]][picked])
        } else {
          character(0)
        }
        drop <- unique(c(gate$excluded, extra))
        if (length(drop)) {
          e <- cr_apply_gate(e, gate, units = drop)
        }
      }
      e
    }, error = function(e) ctx$fail(e, "Quality control"))
    if (is.null(out)) {
      return()
    }
    ctx$log(sprintf("Applied quality control: %d cells remain (%d before).",
                    nrow(out$cells), before))
    ctx$set(out, reset = FALSE)
  })

  shiny::observeEvent(input$btn_qc_reset, {
    shiny::req(state$imported)
    ctx$log("Reset to the imported experiment.")
    ctx$set(state$imported, reset = FALSE)
  })

  invisible(NULL)
}


# ---- normalisation -----------------------------------------------------

.cr_srv_normalise <- function(input, output, session, ctx) {
  state <- ctx$state

  shiny::observeEvent(input$btn_normalize, {
    exp <- state$experiment
    shiny::req(exp, input$sel_channel)
    before <- exp$cells[[input$sel_channel]]
    out <- tryCatch({
      e <- cr_normalize(
        exp,
        channel = input$sel_channel,
        method = input$norm_method,
        control_group = if (identical(input$norm_method, "control")) {
          input$sel_control
        } else {
          NULL
        }
      )
      if (nzchar(input$norm_batch %||% "")) {
        e <- cr_correct_batch(e, batch_var = input$norm_batch,
                              channel = input$sel_channel)
      }
      e
    }, error = function(e) ctx$fail(e, "Normalisation"))
    if (is.null(out)) {
      return()
    }
    ctx$log(sprintf("Normalised %s with method %s.",
                    input$sel_channel, input$norm_method))
    ctx$set(out, reset = FALSE)
    state$before <- before
  })

  shiny::observeEvent(input$btn_norm_reset, {
    shiny::req(state$imported)
    ctx$log("Reset to the imported experiment.")
    ctx$set(state$imported, reset = FALSE)
    state$before <- NULL
  })

  output$msg_norm <- shiny::renderUI({
    if (is.null(state$experiment)) {
      shiny::div(class = "alert alert-secondary",
                 "Build an experiment first.")
    } else if (is.null(state$before)) {
      shiny::div(
        class = "alert alert-secondary",
        "Pick a method and apply it; the panel then shows the selected ",
        "channel before and after."
      )
    }
  })

  output$plt_norm <- shiny::renderPlot({
    exp <- state$experiment
    channel <- input$sel_channel
    before <- state$before
    if (is.null(exp) || is.null(channel) ||
        !channel %in% names(exp$cells)) {
      return(.cr_app_blank_plot("Nothing normalised yet."))
    }
    if (is.null(before)) {
      return(.cr_app_blank_plot(
        "Apply a normalisation to compare before and after."))
    }
    df <- rbind(
      data.frame(stage = "before", value = as.numeric(before)),
      data.frame(stage = "after",
                 value = as.numeric(exp$cells[[channel]]))
    )
    df$stage <- factor(df$stage, levels = c("before", "after"))
    ggplot2::ggplot(df, ggplot2::aes(x = .data$stage, y = .data$value)) +
      ggplot2::geom_violin(scale = "width", fill = "#7b2d8e",
                           alpha = 0.35, colour = "#4a4a4a") +
      ggplot2::labs(x = NULL, y = channel) +
      ggplot2::theme_minimal(base_size = 12)
  })

  invisible(NULL)
}

# Version 0.1.0
