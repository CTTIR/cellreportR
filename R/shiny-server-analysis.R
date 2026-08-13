# Effect sizes, dose-response, figures and report assembly. Registered by
# .cr_app_server(); see R/shiny-server.R for the shared context object.
# Each registration function returns the reactive its tab produces, which
# R/shiny-server-export.R turns into a download, so nothing is computed
# twice.


# ---- effect sizes ------------------------------------------------------

.cr_srv_effects <- function(input, output, session, ctx) {
  state <- ctx$state

  shiny::observeEvent(input$btn_effects, {
    exp <- state$experiment
    shiny::req(exp, input$sel_channel, input$sel_control)
    level <- input$eff_level %||% "unit"
    if (identical(level, "cell")) {
      shiny::showNotification(
        paste("Single-cell intervals ignore that cells within a unit are",
              "not independent; read them as anticonservative."),
        type = "warning", duration = 8
      )
    }
    eff <- tryCatch(
      shiny::withProgress(
        message = "Estimating effect sizes", value = 0.4,
        cr_effect_grid(
          exp,
          value = input$sel_channel,
          group_var = "treatment",
          reference_level = input$sel_control,
          unit = if (identical(level, "unit")) exp$spatial_unit else NULL,
          methods = c("cohens_d", "hedges_g", "cliffs_delta"),
          conf_level = input$eff_conf %||% 0.95,
          min_n = if (identical(level, "unit")) 3 else 10,
          test = "t",
          p_adjust = c("bonferroni", "BH")
        )
      ),
      error = function(e) ctx$fail(e, "Effect sizes")
    )
    if (is.null(eff)) {
      return()
    }
    state$effects <- eff
    ctx$log(sprintf("Estimated %d contrast(s) at %s level against %s.",
                    nrow(eff), level, input$sel_control))
  })

  shiny::observe({
    eff <- state$effects
    shiny::req(eff)
    methods <- .cr_app_effect_methods(eff)
    if (length(methods)) {
      current <- shiny::isolate(input$eff_method)
      shiny::updateSelectInput(
        session, "eff_method", choices = methods,
        selected = if (!is.null(current) && current %in% methods) {
          current
        } else {
          methods[[1L]]
        }
      )
    }
  })

  output$msg_effects <- shiny::renderUI({
    if (is.null(state$experiment)) {
      return(shiny::div(class = "alert alert-secondary",
                        "Build an experiment first."))
    }
    if (is.null(state$effects)) {
      return(shiny::div(
        class = "alert alert-secondary",
        "Choose a level and press estimate. Unit-level estimates use one ",
        "value per acquisition unit, which is the unit of replication and ",
        "carries the interpretation."
      ))
    }
    NULL
  })

  output$tbl_effects <- DT::renderDT({
    shiny::req(state$effects)
    .cr_dt(state$effects, page = 15L)
  })

  forest_plot <- shiny::reactive({
    eff <- state$effects
    if (is.null(eff)) {
      return(.cr_app_blank_plot("No effect sizes estimated yet."))
    }
    method <- input$eff_method %||% "cohens_d"
    cols <- .cr_app_effect_columns(eff, method)
    label <- .cr_app_effect_label(eff)
    conf <- attr(eff, "conf_level") %||% (input$eff_conf %||% 0.95)
    tryCatch(
      cr_plot_forest(
        eff,
        estimate = cols$estimate,
        ci_low = cols$ci_low,
        ci_high = cols$ci_high,
        label = if (is.na(label)) NULL else label,
        method = method,
        title = sprintf("%s versus %s", input$sel_channel %||% "signal",
                        input$sel_control %||% "control"),
        subtitle = sprintf(
          "%s level, %.0f%% confidence intervals",
          attr(eff, "level") %||% (input$eff_level %||% "unit"),
          100 * conf
        )
      ),
      error = function(e) .cr_app_blank_plot(conditionMessage(e))
    )
  })

  output$plt_forest <- shiny::renderPlot(forest_plot())

  forest_plot
}


# ---- dose-response -----------------------------------------------------

.cr_srv_dose <- function(input, output, session, ctx) {
  state <- ctx$state
  fit <- shiny::reactiveVal(NULL)

  shiny::observe({
    exp <- state$experiment
    shiny::req(exp)
    levels_tr <- sort(unique(as.character(exp$design$treatment)))
    shiny::updateSelectInput(session, "dr_treatment",
                             choices = c("(all)" = "", levels_tr),
                             selected = shiny::isolate(input$dr_treatment))
  })

  shiny::observeEvent(input$btn_fit, {
    exp <- state$experiment
    shiny::req(exp, input$sel_channel)
    out <- tryCatch(
      cr_dose_response(
        exp,
        channel = input$sel_channel,
        treatment = if (nzchar(input$dr_treatment %||% "")) {
          input$dr_treatment
        } else {
          NULL
        },
        model = input$dr_model %||% "4pl",
        log_dose = isTRUE(input$dr_log_dose)
      ),
      error = function(e) ctx$fail(e, "Dose-response fit")
    )
    if (is.null(out)) {
      return()
    }
    fit(out)
    ctx$log(sprintf("Fitted a %s dose-response model to %s.",
                    input$dr_model %||% "4pl", input$sel_channel))
  })

  output$msg_dose <- shiny::renderUI({
    if (is.null(state$experiment)) {
      return(shiny::div(class = "alert alert-secondary",
                        "Build an experiment first."))
    }
    if (is.null(fit())) {
      return(shiny::div(
        class = "alert alert-secondary",
        "Fit a curve to summarise the channel against the dose column ",
        "of the design."
      ))
    }
    NULL
  })

  dose_plot <- shiny::reactive({
    f <- fit()
    if (is.null(f)) {
      return(.cr_app_blank_plot("No dose-response model fitted yet."))
    }
    tryCatch(cr_plot_dose_response(f),
             error = function(e) .cr_app_blank_plot(conditionMessage(e)))
  })

  output$plt_dose <- shiny::renderPlot(dose_plot())

  output$tbl_dose <- DT::renderDT({
    f <- fit()
    if (is.null(f)) {
      return(.cr_dt(tibble::tibble(parameter = character(0))))
    }
    params <- tryCatch(dplyr::bind_rows(f$params, cr_ic50(f)),
                       error = function(e) f$params)
    .cr_dt(params)
  })

  dose_plot
}


# ---- figures -----------------------------------------------------------

.cr_srv_figures <- function(input, output, session, ctx) {
  state <- ctx$state

  current_plot <- shiny::reactive({
    exp <- state$experiment
    channel <- input$sel_channel
    if (is.null(exp) || is.null(channel) ||
        !channel %in% names(exp$cells)) {
      return(.cr_app_blank_plot("Build an experiment to draw figures."))
    }
    # A normalised channel holds ratios and can be negative, so the log
    # axes the raw-intensity figures default to have to be dropped.
    positive <- all(exp$cells[[channel]] > 0, na.rm = TRUE)
    tryCatch(
      switch(
        input$plot_type %||% "intensity",
        plate = cr_plot_plate(exp, channel),
        intensity = cr_plot_intensity(exp, channel, log_y = positive),
        histogram = cr_plot_histogram(exp, channel, log_x = positive),
        qc = cr_plot_qc(exp, channel),
        spatial = cr_plot_spatial(exp, channel),
        .cr_app_blank_plot("Unknown figure type.")
      ),
      error = function(e) .cr_app_blank_plot(conditionMessage(e))
    )
  })

  output$plt_view <- shiny::renderPlot(current_plot())

  shiny::observeEvent(input$btn_queue_plot, {
    p <- current_plot()
    shiny::req(p)
    nm <- paste(input$plot_type %||% "figure", input$sel_channel %||% "",
                sep = "_")
    plots <- state$plots
    plots[[nm]] <- p
    state$plots <- plots
    ctx$log(sprintf("Queued figure %s for the report.", nm))
  })

  output$tbl_queued <- DT::renderDT({
    .cr_dt(tibble::tibble(figure = names(state$plots) %||% character(0)))
  })

  current_plot
}


# ---- report ------------------------------------------------------------

.cr_srv_report <- function(input, output, session, ctx) {
  state <- ctx$state

  shiny::observeEvent(input$btn_tests, {
    exp <- state$experiment
    shiny::req(exp, input$sel_channel, input$sel_control)
    res <- tryCatch(
      shiny::withProgress(
        message = "Running pairwise comparisons", value = 0.4,
        cr_test_all(exp, channel = input$sel_channel,
                    control_group = input$sel_control,
                    level = "replicate")
      ),
      error = function(e) ctx$fail(e, "Pairwise comparisons")
    )
    if (is.null(res)) {
      return()
    }
    state$results <- res
    ctx$log(sprintf("Ran %d pairwise comparison(s).", length(res)))
  })

  assembled_report <- function() {
    exp <- state$experiment
    shiny::req(exp)
    cr_report(
      exp,
      results = state$results,
      qc = state$gate,
      effects = state$effects,
      plots = state$plots,
      title = input$rep_title %||% "cellreportR analysis report",
      author = input$rep_author %||% "",
      render = FALSE
    )
  }

  output$msg_report <- shiny::renderUI({
    if (is.null(state$experiment)) {
      return(shiny::div(class = "alert alert-secondary",
                        "Build an experiment first."))
    }
    if (is.null(state$results)) {
      return(shiny::div(
        class = "alert alert-secondary",
        "Run the pairwise comparisons to fill the results section. The ",
        "report also renders without them, carrying the quality-control ",
        "record, the effect-size grid and the queued figures."
      ))
    }
    NULL
  })

  output$tbl_results <- DT::renderDT({
    rep <- tryCatch(assembled_report(), error = function(e) NULL)
    if (is.null(rep) || is.null(rep$summary) || !nrow(rep$summary)) {
      return(.cr_dt(tibble::tibble(note = "Nothing summarised yet.")))
    }
    .cr_dt(rep$summary, page = 15L)
  })

  assembled_report
}
