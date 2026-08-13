# The Shiny server layer, driven in-process by shiny::testServer().
#
# `cr_test_app()`, `cr_ui_text()` and `cr_record_updates()` live in
# tests/testthat/helper-shiny.R. Two habits matter throughout:
#
#  * testServer() flushes on setInputs(), not on a direct write to the
#    reactive store, so a test that assigns into `state` itself calls
#    session$flushReact() before reading an output back.
#  * DT renders server-side, so the JSON an output returns carries the
#    column names but not the rows; assertions are on the header.

# ---- shared state and context -------------------------------------------

test_that(".cr_app_state starts empty", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    expect_null(state$cells)
    expect_null(state$design)
    expect_null(state$experiment)
    expect_null(state$gate)
    expect_null(state$effects)
    expect_null(state$results)
    expect_null(state$before)
    expect_equal(state$plots, list())
    expect_length(state$log, 0L)
  })
})

test_that("the context logs, timestamps and appends", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    ctx$log("first")
    ctx$log("second ", "half")
    expect_length(state$log, 2L)
    expect_match(state$log[[1]], "^\\d{2}:\\d{2}:\\d{2}  first$")
    expect_match(state$log[[2]], "second half$")
  })
})

test_that("the context reports a failure and returns NULL", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    out <- ctx$fail(simpleError("the roof fell in"), "While testing")
    expect_null(out)
    expect_match(tail(state$log, 1), "While testing: the roof fell in")
  })
})

test_that("setting an experiment fills the store and resets downstream", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    state$gate <- "stale"
    state$effects <- "stale"
    state$before <- 1:3
    ctx$set(exp)
    expect_s3_class(state$experiment, "cr_experiment")
    expect_equal(nrow(state$cells), nrow(exp$cells))
    expect_equal(nrow(state$design), nrow(exp$design))
    expect_identical(state$imported, exp)
    expect_null(state$gate)
    expect_null(state$effects)
    expect_null(state$before)
    expect_match(tail(state$log, 1), "Experiment ready")
  })
})

test_that("setting an experiment with reset = FALSE keeps the analyses", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    ctx$set(exp)
    state$gate <- "keep me"
    ctx$set(exp, reset = FALSE)
    expect_equal(state$gate, "keep me")
  })
})

test_that("an experiment passed to the app is loaded on start-up", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    expect_s3_class(state$experiment, "cr_experiment")
    expect_length(state$log, 1L)
  })
})

# ---- status and data import ---------------------------------------------

test_that("the status line invites input and then mirrors the log", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    expect_match(output$status, "load")
    ctx$log("something happened")
    session$flushReact()
    expect_match(output$status, "something happened")
  })
})

test_that("the example button loads synthetic data", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    session$setInputs(btn_example = 1)
    expect_s3_class(state$experiment, "cr_experiment")
    expect_gt(nrow(state$cells), 0)
    expect_true(any(grepl("example data", state$log)))
  })
})

test_that("a failing example load is reported, not thrown", {
  skip_if_no_app()
  local_mocked_bindings(
    .cr_app_example = function(...) stop("synthetic data unavailable"),
    .package = "cellreportR"
  )
  shiny::testServer(cr_test_app(), {
    session$setInputs(btn_example = 1)
    expect_null(state$experiment)
    expect_match(tail(state$log, 1), "Example data: synthetic data unavailable")
  })
})

test_that("uploaded exports are read and stacked", {
  skip_if_no_app()
  cells <- cr_test_experiment()$cells
  dir <- withr::local_tempdir()
  a <- file.path(dir, "a.csv")
  b <- file.path(dir, "b.csv")
  readr::write_csv(utils::head(cells, 20), a)
  readr::write_csv(utils::tail(cells, 12), b)
  shiny::testServer(cr_test_app(), {
    session$setInputs(f_cells = data.frame(
      name = c("plate_a.csv", "plate_b.csv"),
      datapath = c(a, b),
      stringsAsFactors = FALSE
    ))
    expect_equal(nrow(state$cells), 32L)
    expect_setequal(unique(state$cells$source_file),
                    c("plate_a.csv", "plate_b.csv"))
    expect_null(state$design)
    expect_match(tail(state$log, 1), "Read 32 row\\(s\\) from 2 uploaded file")
  })
})

test_that("an unreadable upload is reported and leaves the store alone", {
  skip_if_no_app()
  dir <- withr::local_tempdir()
  bad <- file.path(dir, "broken.rds")
  writeLines("this is not an rds file", bad)
  shiny::testServer(cr_test_app(), {
    session$setInputs(f_cells = data.frame(
      name = "broken.rds", datapath = bad, stringsAsFactors = FALSE
    ))
    expect_null(state$cells)
    expect_match(tail(state$log, 1), "Reading uploads")
  })
})

test_that("scanning a directory reads every matching export", {
  skip_if_no_app()
  cells <- cr_test_experiment()$cells
  dir <- withr::local_tempdir()
  readr::write_csv(utils::head(cells, 18), file.path(dir, "a.csv"))
  readr::write_csv(utils::tail(cells, 14), file.path(dir, "b.csv"))
  shiny::testServer(cr_test_app(), {
    session$setInputs(dir_path = dir, dir_pattern = "\\.csv$",
                      dir_recursive = FALSE, btn_scan = 1)
    expect_equal(nrow(state$cells), 32L)
    expect_match(tail(state$log, 1), "Read 32 row\\(s\\)")
  })
})

test_that("scanning falls back to the default pattern when none is given", {
  skip_if_no_app()
  cells <- cr_test_experiment()$cells
  dir <- withr::local_tempdir()
  readr::write_csv(utils::head(cells, 11), file.path(dir, "a.csv"))
  shiny::testServer(cr_test_app(), {
    session$setInputs(dir_path = dir, dir_pattern = "", btn_scan = 1)
    expect_equal(nrow(state$cells), 11L)
  })
})

test_that("scanning without a path warns instead of reading", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    session$setInputs(dir_path = "", btn_scan = 1)
    expect_null(state$cells)
    expect_length(state$log, 0L)
  })
})

test_that("scanning a directory with nothing in it is reported", {
  skip_if_no_app()
  dir <- withr::local_tempdir()
  shiny::testServer(cr_test_app(), {
    session$setInputs(dir_path = dir, dir_pattern = "\\.csv$",
                      dir_recursive = FALSE, btn_scan = 1)
    expect_null(state$cells)
    expect_match(tail(state$log, 1), "Reading directory")
  })
})

test_that("an uploaded design table is read", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  dir <- withr::local_tempdir()
  f <- file.path(dir, "design.csv")
  readr::write_csv(exp$design, f)
  shiny::testServer(cr_test_app(), {
    session$setInputs(f_design = data.frame(
      name = "design.csv", datapath = f, stringsAsFactors = FALSE
    ))
    expect_equal(nrow(state$design), nrow(exp$design))
    expect_match(tail(state$log, 1), "design table")
  })
})

test_that("an unreadable design table is reported", {
  skip_if_no_app()
  missing <- file.path(withr::local_tempdir(), "not-written.csv")
  shiny::testServer(cr_test_app(), {
    session$setInputs(f_design = data.frame(
      name = "design.csv", datapath = missing, stringsAsFactors = FALSE
    ))
    expect_null(state$design)
    expect_match(tail(state$log, 1), "Reading design")
  })
})

test_that("the data panel explains itself until cells arrive", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_cells), "No cells loaded yet")
    ctx$set(exp)
    session$flushReact()
    expect_null(output$msg_cells)
  })
})

test_that("the cells and provenance tables render", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    expect_type(output$tbl_cells, "character")
    expect_match(output$tbl_cells, "cell_id")
    # An in-session experiment has no per-file provenance, so a
    # placeholder with the same two columns stands in for the count.
    expect_match(output$tbl_provenance, "source_file")
    expect_match(output$tbl_provenance, "n_cells")
    state$cells$source_file <- rep(c("a.csv", "b.csv"),
                                   length.out = nrow(state$cells))
    session$flushReact()
    expect_match(output$tbl_provenance, "n_cells")
  })
})

test_that("the channel panel reports channels, columns or nothing", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(output$txt_channels, "no data", fixed = TRUE)
    state$cells <- exp$cells
    session$flushReact()
    expect_match(output$txt_channels, "Numeric columns available")
    ctx$set(exp)
    session$flushReact()
    expect_match(output$txt_channels, "channel")
  })
})

# ---- design specification -----------------------------------------------

test_that("the unit selector is filled from the cells table", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(exp), {
    session$flushReact()
    expect_true("sel_unit_col" %in% cr_update_ids(seen))
    expect_true("well" %in% cr_last_update(seen, "sel_unit_col")$choices)
  })
})

test_that("a design skeleton is derived from the chosen unit column", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_unit_col = "well", btn_design_skeleton = 1)
    expect_equal(nrow(state$design), dplyr::n_distinct(exp$cells$well))
    expect_equal(names(state$design)[1], "well")
    expect_match(tail(state$log, 1), "design skeleton")
  })
})

test_that("deriving a design without a spatial unit is reported", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    state$cells <- tibble::tibble(cell_id = c("a", "b"), value = 1:2)
    session$setInputs(sel_unit_col = "", btn_design_skeleton = 1)
    expect_null(state$design)
    expect_match(tail(state$log, 1), "Deriving design")
  })
})

test_that("treatment, group and dose are assigned to the picked units", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_unit_col = "well", btn_design_skeleton = 1)
    picked <- as.character(state$design[[1]])[1:3]
    session$setInputs(sel_units = picked, txt_treatment = "CompoundZ",
                      txt_group = "treated", num_dose = 25, btn_assign = 1)
    hit <- as.character(state$design[[1]]) %in% picked
    expect_true(all(state$design$treatment[hit] == "CompoundZ"))
    expect_true(all(state$design$group[hit] == "treated"))
    expect_true(all(state$design$dose[hit] == 25))
    # everything else is untouched
    expect_true(all(state$design$treatment[!hit] == "untreated"))
    expect_match(tail(state$log, 1), "Assigned CompoundZ to 3 unit")
  })
})

test_that("assigning with nothing selected warns and changes nothing", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_unit_col = "well", btn_design_skeleton = 1)
    before <- state$design
    session$setInputs(sel_units = character(0), txt_treatment = "X",
                      btn_assign = 1)
    expect_identical(state$design, before)
  })
})

test_that("editing a design cell writes the value back", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_unit_col = "well", btn_design_skeleton = 1)
    session$setInputs(tbl_design_cell_edit = list(row = 1L, col = 1L,
                                                  value = "CompoundQ"))
    expect_equal(state$design$treatment[1], "CompoundQ")
  })
})

test_that("an out-of-range cell edit is ignored", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_unit_col = "well", btn_design_skeleton = 1)
    before <- state$design
    session$setInputs(tbl_design_cell_edit = list(row = 10000L, col = 1L,
                                                  value = "X"))
    expect_identical(state$design, before)
    session$setInputs(tbl_design_cell_edit = list(row = 1L, col = 99L,
                                                  value = "X"))
    expect_identical(state$design, before)
  })
})

test_that("building an experiment needs both cells and a design", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    session$setInputs(btn_build = 1)
    expect_null(state$experiment)
    expect_length(state$log, 0L)
  })
})

test_that("a build failure is reported rather than thrown", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    state$cells <- tibble::tibble(cell_id = c("a", "b"), value = 1:2)
    state$design <- tibble::tibble(well = c("A01", "A02"),
                                   treatment = c("x", "y"))
    session$setInputs(btn_build = 1)
    expect_null(state$experiment)
    expect_match(tail(state$log, 1), "Building experiment")
  })
})

test_that("a valid cells table and design build an experiment", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    state$cells <- exp$cells
    state$design <- exp$design
    session$setInputs(btn_build = 1)
    expect_s3_class(state$experiment, "cr_experiment")
    expect_match(tail(state$log, 1), "Experiment ready")
  })
})

test_that("the design panel explains itself and then renders the table", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_design), "Upload a design table")
    ctx$set(exp)
    session$flushReact()
    expect_null(output$msg_design)
    expect_match(output$tbl_design, "treatment")
  })
})

# ---- selectors ----------------------------------------------------------

test_that("the selectors are filled from the experiment", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(exp), {
    session$flushReact()
    ids <- cr_update_ids(seen)
    expect_true(all(c("sel_channel", "sel_control", "qc_batch",
                      "norm_batch", "dr_treatment") %in% ids))
    channels <- cr_last_update(seen, "sel_channel")$choices
    expect_true(all(cr_channels(exp) %in% channels))
    controls <- cr_last_update(seen, "sel_control")$choices
    expect_setequal(controls, unique(as.character(exp$design$treatment)))
    # The batch pickers offer the design's own variables, minus the unit
    # and the treatment itself.
    batches <- cr_last_update(seen, "qc_batch")$choices
    expect_false(exp$spatial_unit %in% batches)
    expect_false("treatment" %in% batches)
    expect_true("plate" %in% batches)
  })
})

test_that("the channel selector defaults to the last channel", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(exp), {
    session$flushReact()
    channels <- cr_channels(exp)
    expect_equal(cr_last_update(seen, "sel_channel")$selected,
                 channels[[length(channels)]])
  })
})

test_that("a selection the user already made survives a refresh", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated")
    expect_equal(cr_last_update(seen, "sel_channel")$selected, "marker_1")
    expect_equal(cr_last_update(seen, "sel_control")$selected, "Untreated")
  })
})

# ---- quality control ----------------------------------------------------

test_that("the gate is evaluated and logged", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      qc_statistic = "median", qc_reference = "median",
                      qc_direction = "greater", qc_min_cells = 3,
                      btn_gate = 1)
    expect_s3_class(state$gate, "cr_qc_gate")
    expect_true(is.data.frame(state$gate$units))
    expect_match(tail(state$log, 1), "Gate evaluated")
  })
})

test_that("the gate honours a batch variable", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      qc_batch = "plate", btn_gate = 1)
    expect_s3_class(state$gate, "cr_qc_gate")
    expect_true("plate" %in% state$gate$params$batch_vars)
  })
})

test_that("a failing gate is reported and leaves the store alone", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "not_a_channel",
                      sel_control = "Untreated", btn_gate = 1)
    expect_null(state$gate)
    expect_match(tail(state$log, 1), "Quality-control gate")
  })
})

test_that("the quality-control panel walks through its states", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_qc), "Build an experiment first")
    ctx$set(exp)
    session$flushReact()
    expect_match(cr_ui_text(output$msg_qc), "Evaluate the gate")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      qc_direction = "greater", btn_gate = 1)
    txt <- cr_ui_text(output$msg_qc)
    expect_true(grepl("fail the gate", txt) || grepl("No unit fails", txt))
  })
})

test_that("the quality-control tables render with and without a gate", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    expect_match(output$tbl_units, "unit")
    expect_match(output$tbl_disputed, "note")
    expect_type(output$tbl_qc_log, "character")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_gate = 1)
    # Units are selectable so that a reviewer can drop one by hand on top
    # of whatever the gate decided.
    expect_match(output$tbl_units, "\"selection\":\\{\"mode\":\"multiple\"")
    expect_match(output$tbl_disputed, "\"selection\":\\{\"mode\":\"none\"")
  })
})

test_that("the gate and area figures render in both states", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    expect_type(output$plt_gate, "list")
    expect_type(output$plt_area, "list")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_gate = 1)
    expect_type(output$plt_gate, "list")
    # an experiment with no segmentation area still draws a placeholder
    state$experiment$cells$area <- NULL
    session$flushReact()
    expect_type(output$plt_area, "list")
  })
})

test_that("applying quality control removes cells and logs the step", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    before <- nrow(state$experiment$cells)
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_gate = 1)
    session$setInputs(qc_min_area = stats::quantile(exp$cells$area, 0.1),
                      qc_max_area = NA, qc_min_circ = NA,
                      qc_doublets = FALSE, btn_qc_apply = 1)
    expect_lt(nrow(state$experiment$cells), before)
    expect_true(any(grepl("Applied quality control", state$log)))
  })
})

test_that("applying quality control drops the units a user picked", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_gate = 1)
    before_units <- dplyr::n_distinct(state$experiment$cells$well)
    session$setInputs(qc_doublets = TRUE, qc_doublet_k = 2.5,
                      tbl_units_rows_selected = c(1L, 2L), btn_qc_apply = 1)
    expect_lt(dplyr::n_distinct(state$experiment$cells$well), before_units)
  })
})

test_that("a failing quality-control step is reported", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  local_mocked_bindings(
    cr_qc_filter = function(...) stop("segmentation columns are missing"),
    .package = "cellreportR"
  )
  shiny::testServer(cr_test_app(exp), {
    before <- nrow(state$experiment$cells)
    session$setInputs(btn_qc_apply = 1)
    expect_equal(nrow(state$experiment$cells), before)
    expect_match(tail(state$log, 1),
                 "Quality control: segmentation columns are missing")
  })
})

test_that("resetting restores the imported experiment", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    before <- nrow(state$experiment$cells)
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      qc_min_area = stats::quantile(exp$cells$area, 0.2),
                      btn_qc_apply = 1)
    expect_lt(nrow(state$experiment$cells), before)
    session$setInputs(btn_qc_reset = 1)
    expect_equal(nrow(state$experiment$cells), before)
    expect_true(any(grepl("Reset to the imported experiment", state$log)))
  })
})

# ---- normalisation ------------------------------------------------------

test_that("normalisation rewrites the channel and keeps the original", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      norm_method = "control", btn_normalize = 1)
    expect_length(state$before, nrow(exp$cells))
    expect_false(isTRUE(all.equal(state$experiment$cells$marker_1,
                                  state$before)))
    expect_true(any(grepl("Normalised marker_1", state$log)))
  })
})

test_that("normalisation can correct a batch at the same time", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      norm_method = "zscore", norm_batch = "plate",
                      btn_normalize = 1)
    expect_s3_class(state$experiment, "cr_experiment")
    expect_length(state$before, nrow(exp$cells))
  })
})

test_that("a failing normalisation is reported", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "NoSuchGroup",
                      norm_method = "control", btn_normalize = 1)
    expect_null(state$before)
    expect_match(tail(state$log, 1), "Normalisation")
  })
})

test_that("resetting normalisation clears the before-image", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      norm_method = "zscore", btn_normalize = 1)
    expect_false(is.null(state$before))
    session$setInputs(btn_norm_reset = 1)
    expect_null(state$before)
    expect_equal(state$experiment$cells$marker_1, exp$cells$marker_1)
  })
})

test_that("the normalisation panel and figure walk through their states", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_norm), "Build an experiment first")
    expect_type(output$plt_norm, "list")
    ctx$set(exp)
    session$flushReact()
    expect_match(cr_ui_text(output$msg_norm), "Pick a method")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      norm_method = "zscore", btn_normalize = 1)
    expect_null(output$msg_norm)
    expect_type(output$plt_norm, "list")
  })
})

# ---- effect sizes -------------------------------------------------------

test_that("unit-level effect sizes are estimated", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "unit", eff_conf = 0.95, btn_effects = 1)
    expect_true(is.data.frame(state$effects))
    expect_gt(nrow(state$effects), 0)
    expect_true("cohens_d" %in% names(state$effects))
    expect_match(tail(state$log, 1), "at unit level against Untreated")
  })
})

test_that("cell-level effect sizes warn about the unit of replication", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "cell", btn_effects = 1)
    expect_true(is.data.frame(state$effects))
    expect_match(tail(state$log, 1), "at cell level")
  })
})

test_that("a failing effect-size estimate is reported", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "NoSuchGroup",
                      eff_level = "unit", btn_effects = 1)
    expect_null(state$effects)
    expect_match(tail(state$log, 1), "Effect sizes")
  })
})

test_that("the method picker offers the methods the grid carries", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "unit", btn_effects = 1)
    methods <- cr_last_update(seen, "eff_method")$choices
    expect_setequal(methods, c("cohens_d", "hedges_g", "cliffs_delta"))
  })
})

test_that("the effects panel, table and forest plot render", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_effects), "Build an experiment first")
    ctx$set(exp)
    session$flushReact()
    expect_match(cr_ui_text(output$msg_effects), "Choose a level")
    expect_type(output$plt_forest, "list")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "unit", eff_method = "cohens_d",
                      btn_effects = 1)
    expect_null(output$msg_effects)
    expect_match(output$tbl_effects, "cohens_d")
    expect_type(output$plt_forest, "list")
  })
})

test_that("the forest plot degrades to a placeholder on a bad method", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "unit", btn_effects = 1)
    session$setInputs(eff_method = "not_a_method")
    expect_type(output$plt_forest, "list")
  })
})

# ---- dose-response ------------------------------------------------------

test_that("a dose-response model is fitted and logged", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", dr_model = "4pl",
                      dr_log_dose = FALSE, dr_treatment = "", btn_fit = 1)
    expect_match(tail(state$log, 1), "Fitted a 4pl dose-response model")
    expect_match(output$tbl_dose, "parameter|term|estimate")
    expect_type(output$plt_dose, "list")
    expect_null(output$msg_dose)
  })
})

test_that("the treatment picker is filled for the dose tab", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(exp), {
    session$flushReact()
    choices <- cr_last_update(seen, "dr_treatment")$choices
    expect_true("" %in% choices)
    expect_true("Untreated" %in% choices)
  })
})

test_that("a failing dose-response fit is reported", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1",
                      dr_treatment = "NoSuchTreatment", btn_fit = 1)
    expect_match(tail(state$log, 1), "Dose-response fit")
    expect_match(cr_ui_text(output$msg_dose), "Fit a curve")
  })
})

test_that("the dose panel asks for an experiment first", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_dose), "Build an experiment first")
    expect_type(output$plt_dose, "list")
    expect_match(output$tbl_dose, "parameter")
  })
})

# ---- figures ------------------------------------------------------------

test_that("every figure type draws", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1")
    for (type in c("plate", "intensity", "histogram", "qc", "spatial")) {
      session$setInputs(plot_type = type)
      expect_type(output$plt_view, "list")
    }
    session$setInputs(plot_type = "something_else")
    expect_type(output$plt_view, "list")
  })
})

test_that("figures fall back to a placeholder without an experiment", {
  skip_if_no_app()
  shiny::testServer(cr_test_app(), {
    expect_type(output$plt_view, "list")
    expect_match(output$tbl_queued, "figure")
  })
})

test_that("a figure can be queued for the report", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", plot_type = "intensity",
                      btn_queue_plot = 1)
    expect_named(state$plots, "intensity_marker_1")
    expect_s3_class(state$plots[[1]], "ggplot")
    expect_match(tail(state$log, 1), "Queued figure intensity_marker_1")
    expect_type(output$tbl_queued, "character")
  })
})

# ---- report -------------------------------------------------------------

test_that("pairwise comparisons are run and counted", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_tests = 1)
    expect_type(state$results, "list")
    expect_gt(length(state$results), 0)
    expect_match(tail(state$log, 1), "pairwise comparison")
  })
})

test_that("a failing comparison run is reported", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "not_a_channel",
                      sel_control = "Untreated", btn_tests = 1)
    expect_null(state$results)
    expect_match(tail(state$log, 1), "Pairwise comparisons")
  })
})

test_that("the report panel walks through its states", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(), {
    expect_match(cr_ui_text(output$msg_report), "Build an experiment first")
    expect_match(output$tbl_results, "note")
    ctx$set(exp)
    session$flushReact()
    expect_match(cr_ui_text(output$msg_report), "Run the pairwise")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_tests = 1)
    expect_null(output$msg_report)
    expect_type(output$tbl_results, "character")
  })
})

# ---- downloads ----------------------------------------------------------

test_that("the experiment downloads as an rds", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    f <- output$dl_experiment
    expect_match(basename(f), "_experiment\\.rds$")
    expect_s3_class(readRDS(f), "cr_experiment")
  })
})

test_that("the unit table downloads with and without a gate", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    empty <- readr::read_csv(output$dl_units, show_col_types = FALSE)
    expect_equal(empty$note, "no gate evaluated")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_gate = 1)
    filled <- readr::read_csv(output$dl_units, show_col_types = FALSE)
    expect_gt(nrow(filled), 0)
  })
})

test_that("the effect-size grid downloads as a csv", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "unit", btn_effects = 1)
    out <- readr::read_csv(output$dl_effects, show_col_types = FALSE)
    expect_equal(nrow(out), nrow(state$effects))
  })
})

test_that("the results download prefers the report summary", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    none <- readr::read_csv(output$dl_results, show_col_types = FALSE)
    expect_equal(none$note, "no results yet")
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      btn_tests = 1)
    out <- readr::read_csv(output$dl_results, show_col_types = FALSE)
    expect_gt(nrow(out), 0)
  })
})

test_that("the results download falls back to the effect grid", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      eff_level = "unit", btn_effects = 1)
    out <- readr::read_csv(output$dl_results, show_col_types = FALSE)
    expect_gt(nrow(out), 0)
  })
})

test_that("the figures download as png files", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", plot_type = "intensity",
                      plot_w_in = 4, plot_h_in = 3, plot_dpi = 72)
    for (id in c("dl_plot", "dl_forest", "dl_dose")) {
      f <- output[[id]]
      expect_true(file.exists(f))
      expect_gt(file.size(f), 0)
    }
    expect_match(basename(output$dl_plot), "_intensity\\.png$")
  })
})

test_that("the queued figures download as a zip", {
  skip_if_no_app()
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", plot_type = "intensity",
                      plot_w_in = 4, plot_h_in = 3, plot_dpi = 72,
                      btn_queue_plot = 1)
    f <- NULL
    utils::capture.output(f <- output$dl_plots_zip)
    expect_true(file.exists(f))
    expect_match(basename(f), "_figures\\.zip$")
    expect_true(any(grepl("intensity_marker_1\\.png",
                          utils::unzip(f, list = TRUE)$Name)))
  })
})

test_that("the report downloads as a rendered document", {
  skip_on_cran()
  skip_if_no_app()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  exp <- cr_test_experiment()
  shiny::testServer(cr_test_app(exp), {
    session$setInputs(sel_channel = "marker_1", sel_control = "Untreated",
                      rep_title = "Marker 1 overview", rep_author = "tester",
                      rep_format = "html", btn_tests = 1)
    f <- suppressMessages(output$dl_report)
    expect_match(basename(f), "_report\\.html$")
    expect_gt(file.size(f), 0)
  })
})
