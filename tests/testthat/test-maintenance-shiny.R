test_that("screen selectors retain the declared control and compound identity", {
  e <- cr_example_screen(seed = 42, n_compounds = 2, n_cells_per_well = 4)
  seen <- cr_record_updates()
  shiny::testServer(cr_test_app(e), {
    session$flushReact()
    expect_equal(cr_last_update(seen, "sel_control")$selected, "Vehicle")
    expect_equal(cr_last_update(seen, "eff_by")$selected, "compound")
    session$setInputs(eff_by = "")
    refreshed <- e
    refreshed$metadata$refresh <- TRUE
    ctx$set(refreshed, reset = FALSE)
    session$flushReact()
    expect_equal(cr_last_update(seen, "eff_by")$selected, "")
  })
})

test_that("stratified effects retain groups through downloads and reject stale targets", {
  e <- cr_example_screen(seed = 42, n_compounds = 2, n_cells_per_well = 4)
  shiny::testServer(cr_test_app(e), {
    session$setInputs(sel_channel = "target_signal", sel_control = "Vehicle",
                      eff_level = "unit", eff_by = "compound", eff_conf = .95)
    session$setInputs(btn_effects = 1)
    expect_equal(nrow(state$effects), 6)
    expect_setequal(state$effects$compound, c("CompoundA", "CompoundB"))
    expect_equal(attr(state$effects, "strata"), "compound")
    exported <- readr::read_csv(output$dl_effects, show_col_types = FALSE)
    expect_equal(nrow(exported), 6)
    expect_setequal(exported$compound, c("CompoundA", "CompoundB"))
    session$setInputs(eff_by = "")
    expect_null(state$effects)
    expect_error(output$dl_effects, class = "shiny.silent.error")
    session$setInputs(btn_effects = 2)
    expect_equal(nrow(state$effects), 3)
    session$setInputs(sel_control = "Dose_10")
    expect_null(state$effects)
  })
})
