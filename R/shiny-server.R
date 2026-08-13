# Server of the cellreportR Shiny application: shared state, the status
# log, data import, design specification and the selectors every other
# tab reads. The remaining tabs live in R/shiny-server-qc.R and
# R/shiny-server-analysis.R; each is a plain function of
# `(input, output, session, ctx)` so the server stays readable and can be
# driven in-process by shiny::testServer().
#
# Every analytical step delegates to an exported cellreportR function, so
# the app and a scripted analysis produce the same numbers.


# Everything the app knows, in one reactive store.
.cr_app_state <- function() {
  shiny::reactiveValues(
    cells = NULL,
    design = NULL,
    experiment = NULL,
    imported = NULL,
    gate = NULL,
    effects = NULL,
    results = NULL,
    plots = list(),
    before = NULL,
    report_spec = NULL,
    lab_report = NULL,
    log = character(0)
  )
}


# The store plus the three helpers every tab needs, in a plain list of
# closures rather than an R6 object to keep the app free of dependencies.
.cr_app_context <- function(state) {
  log_msg <- function(...) {
    state$log <- c(
      state$log,
      paste0(format(Sys.time(), "%H:%M:%S"), "  ",
             paste0(..., collapse = ""))
    )
  }

  notify_error <- function(e, what) {
    log_msg(what, ": ", conditionMessage(e))
    shiny::showNotification(conditionMessage(e), type = "error",
                            duration = 8)
    NULL
  }

  set_experiment <- function(exp, reset = TRUE) {
    state$experiment <- exp
    state$cells <- exp$cells
    state$design <- exp$design
    if (isTRUE(reset)) {
      state$imported <- exp
      state$gate <- NULL
      state$effects <- NULL
      state$results <- NULL
      state$before <- NULL
    }
    log_msg(sprintf(
      "Experiment ready: %d cells across %d %ss, %d channel(s).",
      nrow(exp$cells),
      length(unique(exp$cells[[exp$spatial_unit]])),
      exp$spatial_unit,
      nrow(exp$channels)
    ))
  }

  list(state = state, log = log_msg, fail = notify_error,
       set = set_experiment)
}


.cr_app_server <- function(input, output, session, experiment = NULL,
                           report_spec = NULL) {
  # `state` stays a local of the server function so that a test driving
  # it with shiny::testServer() can read the app's whole state directly.
  state <- .cr_app_state()
  ctx <- .cr_app_context(state)
  state$report_spec <- report_spec %||% cr_report_spec()
  if (!is.null(experiment)) {
    ctx$set(experiment)
  }

  .cr_srv_data(input, output, session, ctx)
  .cr_srv_design(input, output, session, ctx)
  .cr_srv_selectors(input, output, session, ctx)
  .cr_srv_qc(input, output, session, ctx)
  .cr_srv_normalise(input, output, session, ctx)

  forest <- .cr_srv_effects(input, output, session, ctx)
  dose <- .cr_srv_dose(input, output, session, ctx)
  figure <- .cr_srv_figures(input, output, session, ctx)
  report <- .cr_srv_report(input, output, session, ctx)
  lab_report <- .cr_srv_lab_report(input, output, session, ctx)
  .cr_srv_downloads(input, output, session, ctx, forest = forest,
                    figure = figure, dose = dose, report = report,
                    lab_report = lab_report)

  # The context is returned so that a wrapper of the exact shape
  # shiny::testServer() insists on -- (input, output, session) and
  # nothing else -- can bind `state` into its own frame and read the
  # app's whole state. `.cr_app()` ignores the value.
  invisible(ctx)
}


# ---- status and data import -------------------------------------------

.cr_srv_data <- function(input, output, session, ctx) {
  state <- ctx$state

  output$status <- shiny::renderText({
    if (!length(state$log)) {
      paste("Upload segmented exports, point at a directory, or load",
            "the example data to begin.")
    } else {
      paste(state$log, collapse = "\n")
    }
  })

  shiny::observeEvent(input$btn_example, {
    exp <- tryCatch(.cr_app_example(),
                    error = function(e) ctx$fail(e, "Example data"))
    if (!is.null(exp)) {
      ctx$log("Loaded synthetic example data.")
      ctx$set(exp)
    }
  })

  shiny::observeEvent(input$f_cells, {
    up <- input$f_cells
    shiny::req(up)
    cells <- tryCatch(.cr_app_read_files(up$datapath, up$name),
                      error = function(e) ctx$fail(e, "Reading uploads"))
    if (is.null(cells)) {
      return()
    }
    state$cells <- cells
    state$design <- NULL
    ctx$log(sprintf("Read %d row(s) from %d uploaded file(s).",
                    nrow(cells), nrow(up)))
  })

  shiny::observeEvent(input$btn_scan, {
    root <- input$dir_path
    if (is.null(root) || !nzchar(root)) {
      shiny::showNotification("Give a directory path first.",
                              type = "warning")
      return()
    }
    pattern <- input$dir_pattern
    if (is.null(pattern) || !nzchar(pattern)) {
      pattern <- "\\.(csv|tsv|txt|xls|xlsx)$"
    }
    cells <- tryCatch(
      shiny::withProgress(
        message = "Reading exports", value = 0.4,
        .cr_app_read_dir(root, pattern = pattern,
                         recursive = isTRUE(input$dir_recursive))
      ),
      error = function(e) ctx$fail(e, "Reading directory")
    )
    if (is.null(cells)) {
      return()
    }
    state$cells <- cells
    state$design <- NULL
    ctx$log(sprintf("Read %d row(s) from %d file(s) under %s.",
                    nrow(cells),
                    length(unique(cells$source_path %||% root)), root))
  })

  shiny::observeEvent(input$f_design, {
    shiny::req(input$f_design)
    design <- tryCatch(cr_read_design(input$f_design$datapath),
                       error = function(e) ctx$fail(e, "Reading design"))
    if (is.null(design)) {
      return()
    }
    state$design <- design
    ctx$log(sprintf("Read a design table with %d row(s).", nrow(design)))
  })

  output$msg_cells <- shiny::renderUI({
    if (is.null(state$cells)) {
      shiny::div(
        class = "alert alert-secondary",
        "No cells loaded yet. Upload segmented exports, point at a ",
        "directory of exports, or load the example data from the ",
        "sidebar."
      )
    }
  })

  output$tbl_cells <- DT::renderDT({
    shiny::req(state$cells)
    .cr_dt(utils::head(state$cells, 200L))
  })

  output$tbl_provenance <- DT::renderDT({
    shiny::req(state$cells)
    cells <- state$cells
    if (!"source_file" %in% names(cells)) {
      return(.cr_dt(tibble::tibble(source_file = "(single table)",
                                   n_cells = nrow(cells))))
    }
    .cr_dt(dplyr::count(cells, .data$source_file, name = "n_cells"))
  })

  output$txt_channels <- shiny::renderPrint({
    exp <- state$experiment
    if (!is.null(exp)) {
      print(exp$channels)
      return(invisible(NULL))
    }
    cells <- state$cells
    if (is.null(cells)) {
      cat("(no data)")
      return(invisible(NULL))
    }
    cat("Numeric columns available:\n")
    cat(paste(names(cells)[vapply(cells, is.numeric, logical(1))],
              collapse = ", "))
  })

  invisible(NULL)
}


# ---- design specification ---------------------------------------------

.cr_srv_design <- function(input, output, session, ctx) {
  state <- ctx$state

  shiny::observe({
    cells <- state$cells
    shiny::req(cells)
    choices <- .cr_app_unit_choices(cells)
    if (length(choices)) {
      current <- shiny::isolate(input$sel_unit_col)
      shiny::updateSelectInput(
        session, "sel_unit_col", choices = choices,
        selected = if (!is.null(current) && current %in% choices) {
          current
        } else {
          choices[[1L]]
        }
      )
    }
  })

  shiny::observeEvent(input$btn_design_skeleton, {
    shiny::req(state$cells)
    cells <- .cr_app_set_unit(state$cells, input$sel_unit_col)
    design <- tryCatch(.cr_app_design_skeleton(cells),
                       error = function(e) ctx$fail(e, "Deriving design"))
    if (is.null(design)) {
      return()
    }
    state$cells <- cells
    state$design <- design
    ctx$log(sprintf("Derived a design skeleton with %d unit(s) from %s.",
                    nrow(design), input$sel_unit_col %||% "well"))
  })

  shiny::observe({
    design <- state$design
    if (is.null(design) || !nrow(design)) {
      return()
    }
    shiny::updateSelectInput(session, "sel_units",
                             choices = as.character(design[[1L]]),
                             selected = shiny::isolate(input$sel_units))
  })

  shiny::observeEvent(input$btn_assign, {
    shiny::req(state$design)
    picked <- input$sel_units
    if (!length(picked)) {
      shiny::showNotification("Select one or more units first.",
                              type = "warning")
      return()
    }
    design <- state$design
    hit <- as.character(design[[1L]]) %in% picked
    if (nzchar(input$txt_treatment %||% "")) {
      design$treatment <- as.character(design$treatment)
      design$treatment[hit] <- input$txt_treatment
    }
    if ("group" %in% names(design) && nzchar(input$txt_group %||% "")) {
      design$group <- as.character(design$group)
      design$group[hit] <- input$txt_group
    }
    if ("dose" %in% names(design) && !is.null(input$num_dose) &&
        !is.na(input$num_dose)) {
      design$dose[hit] <- input$num_dose
    }
    state$design <- design
    ctx$log(sprintf("Assigned %s to %d unit(s).",
                    input$txt_treatment, sum(hit)))
  })

  shiny::observeEvent(input$tbl_design_cell_edit, {
    info <- input$tbl_design_cell_edit
    design <- state$design
    shiny::req(design)
    row <- info$row
    col <- info$col + 1L
    if (row > nrow(design) || col > ncol(design)) {
      return()
    }
    design[[col]][row] <- DT::coerceValue(info$value, design[[col]][row])
    state$design <- design
  })

  shiny::observeEvent(input$btn_build, {
    if (is.null(state$cells) || is.null(state$design)) {
      shiny::showNotification("Both a cells table and a design are needed.",
                              type = "warning")
      return()
    }
    exp <- tryCatch(cr_build_experiment(state$cells, state$design),
                    error = function(e) ctx$fail(e, "Building experiment"))
    if (!is.null(exp)) {
      ctx$set(exp)
    }
  })

  output$msg_design <- shiny::renderUI({
    if (is.null(state$design)) {
      shiny::div(
        class = "alert alert-secondary",
        "Upload a design table, or pick the column that identifies one ",
        "acquisition and derive one design row per unit. Cells in the ",
        "table can be edited in place."
      )
    }
  })

  output$tbl_design <- DT::renderDT({
    shiny::req(state$design)
    .cr_dt(state$design, page = 15L, editable = "cell")
  })

  invisible(NULL)
}


# ---- channel, control and batch selectors ------------------------------

.cr_srv_selectors <- function(input, output, session, ctx) {
  shiny::observe({
    exp <- ctx$state$experiment
    shiny::req(exp)
    channels <- cr_channels(exp)
    if (length(channels)) {
      current <- shiny::isolate(input$sel_channel)
      shiny::updateSelectInput(
        session, "sel_channel", choices = channels,
        selected = if (!is.null(current) && current %in% channels) {
          current
        } else {
          channels[[length(channels)]]
        }
      )
    }
    levels_tr <- sort(unique(as.character(exp$design$treatment)))
    current <- shiny::isolate(input$sel_control)
    shiny::updateSelectInput(
      session, "sel_control", choices = levels_tr,
      selected = if (!is.null(current) && current %in% levels_tr) {
        current
      } else {
        levels_tr[[1L]]
      }
    )
    design_vars <- setdiff(names(exp$design),
                           c(exp$spatial_unit, "treatment"))
    shiny::updateSelectInput(session, "qc_batch", choices = design_vars,
                             selected = shiny::isolate(input$qc_batch))
    shiny::updateSelectInput(session, "norm_batch",
                             choices = c("(none)" = "", design_vars))
  })

  invisible(NULL)
}

# Version 0.1.0
