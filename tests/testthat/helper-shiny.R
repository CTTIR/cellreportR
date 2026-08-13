# Scaffolding shared by the Shiny tests.
#
# shiny::testServer() evaluates its expression inside the frame of the
# server function it is handed, and rejects a server function taking any
# argument beyond (input, output, session). `.cr_app_server()` takes an
# `experiment` too, so the tests drive it through a wrapper of exactly the
# shape testServer() insists on. The wrapper binds the returned context
# and its reactive store into its own frame, which is what makes `ctx`
# and `state` readable from the test expression.
cr_test_app <- function(experiment = NULL, report_spec = NULL,
                        report_profile = NULL) {
  force(experiment)
  force(report_spec)
  force(report_profile)
  function(input, output, session) {
    ctx <- cellreportR:::.cr_app_server(input, output, session,
                                        experiment = experiment,
                                        report_spec = report_spec,
                                        report_profile = report_profile)
    state <- ctx$state
    invisible(list(ctx = ctx, state = state))
  }
}

# The app leans on three Suggests; skip rather than fail where they are
# not installed.
skip_if_no_app <- function() {
  testthat::skip_if_not_installed("shiny")
  testthat::skip_if_not_installed("DT")
  testthat::skip_if_not_installed("ggplot2")
}

# A small experiment that still carries several treatments, batches and a
# dose column, so every tab of the app has something to work on without
# the tests paying for a full plate of cells.
cr_test_experiment <- function(seed = 1, n_cells_per_well = 6) {
  cr_example_experiment(seed = seed, n_cells_per_well = n_cells_per_well)
}

# A renderUI() output arrives as list(html =, deps =), or as NULL when the
# panel has nothing to say. Both collapse to a plain string here.
cr_ui_text <- function(x) {
  if (is.null(x)) {
    return("")
  }
  paste(as.character(x$html), collapse = "\n")
}

# MockShinySession swallows updateSelectInput() -- its sendInputMessage()
# is a documented no-op -- so the selector observers are observed by
# recording the calls themselves. Returns an environment whose `calls`
# element accumulates one entry per update.
cr_record_updates <- function(env = parent.frame()) {
  seen <- new.env(parent = emptyenv())
  seen$calls <- list()
  testthat::local_mocked_bindings(
    updateSelectInput = function(session, inputId, ...) {
      seen$calls[[length(seen$calls) + 1L]] <- list(id = inputId,
                                                    args = list(...))
      invisible(NULL)
    },
    .package = "shiny",
    .env = env
  )
  seen
}

# The ids a recorder saw, in order.
cr_update_ids <- function(seen) {
  vapply(seen$calls, function(x) x$id, character(1))
}

# The arguments of the most recent update of one input, or NULL.
cr_last_update <- function(seen, id) {
  hits <- Filter(function(x) identical(x$id, id), seen$calls)
  if (!length(hits)) {
    return(NULL)
  }
  hits[[length(hits)]]$args
}
