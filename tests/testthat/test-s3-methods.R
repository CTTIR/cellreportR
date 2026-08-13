test_that("print.cr_experiment runs without error", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_no_error(print(exp))
})

test_that("summary.cr_experiment returns tibble", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  s <- suppressMessages(summary(exp))
  expect_s3_class(s, "tbl_df")
})

test_that("print.cr_result runs without error", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  expect_no_error(print(res))
})

test_that("print.cr_report runs without error", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  rep <- cellreportR:::.cr_new_report(exp)
  expect_no_error(print(rep))
})

# --- return values -------------------------------------------------------

test_that("the print methods return their argument invisibly", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "cell")
  rep <- cr_report(exp, render = FALSE)
  for (obj in list(exp, res, rep)) {
    out <- withVisible(suppressMessages(print(obj)))
    expect_identical(out$value, obj)
    expect_false(out$visible)
  }
})

test_that("summary.cr_experiment counts wells and cells per treatment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  s <- suppressMessages(summary(exp))
  expect_named(s, c("treatment", "n_wells", "n_cells"))
  expect_setequal(s$treatment, unique(exp$design$treatment))
  expect_equal(sum(s$n_cells), nrow(exp$cells))
  expect_equal(sum(s$n_wells), dplyr::n_distinct(exp$design$well))
})

test_that("summary.cr_result returns the result invisibly", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  out <- withVisible(suppressMessages(summary(res)))
  expect_identical(out$value, res)
  expect_false(out$visible)
  expect_s3_class(out$value, "cr_result")
})

test_that("summary.cr_report returns the report invisibly", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  rep <- cr_report(exp, render = FALSE)
  out <- withVisible(suppressMessages(summary(rep)))
  expect_identical(out$value, rep)
  expect_false(out$visible)
  expect_s3_class(out$value, "cr_report")
})

test_that("summary.cr_report prints the summary table when it has rows", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  eff <- data.frame(group = c("CompoundA_low", "CompoundA_high"),
                    estimate = c(0.31, 1.42),
                    ci_low = c(-0.10, 0.55),
                    ci_high = c(0.72, 2.29))
  rep <- cr_report(exp, effects = eff, render = FALSE)
  expect_gt(nrow(rep$summary), 0)
  txt <- paste(utils::capture.output(summary(rep), type = "message"),
               collapse = "\n")
  expect_match(txt, "Analyses")
})

# --- printed output, pinned by snapshot ----------------------------------

test_that("print.cr_experiment output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  expect_snapshot(print(exp))
})

test_that("summary.cr_experiment output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  expect_snapshot(summary(exp))
})

test_that("print.cr_result output is stable at cell level", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  expect_snapshot(print(res))
})

test_that("print.cr_result output is stable at both levels", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "welch", level = "both")
  expect_snapshot(print(res))
})

test_that("print.cr_result reports an AUC when the result carries one", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
  expect_false(is.null(res$roc))
  expect_snapshot(print(res))
})

test_that("summary.cr_result output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 test = "mann_whitney", level = "cell")
  expect_snapshot(summary(res))
})

test_that("print.cr_report output is stable when empty", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  expect_snapshot(print(cr_report(exp, render = FALSE)))
})

test_that("print.cr_report output is stable with a summary and plots", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  eff <- data.frame(group = c("CompoundA_low", "CompoundA_high"),
                    estimate = c(0.31, 1.42),
                    ci_low = c(-0.10, 0.55),
                    ci_high = c(0.72, 2.29))
  rep <- cr_report(exp, effects = eff,
                   plots = list(intensity = cr_plot_intensity(exp, "marker_1")),
                   render = FALSE)
  expect_snapshot(print(rep))
})

test_that("summary.cr_report output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  expect_snapshot(summary(cr_report(exp, render = FALSE)))
})

test_that("print.cr_qc_gate output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  gate <- cr_qc_gate(exp, channel = "marker_1", control_level = "Untreated")
  expect_snapshot(print(gate))
})

test_that("print.cr_design output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  design <- cr_design(exp$design, unit = "well", control_level = "Untreated",
                      batch_vars = "plate")
  expect_snapshot(print(design))
})

test_that("print.cr_dataset output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  ds <- cr_dataset(exp$cells, design = exp$design, unit_var = "well")
  expect_snapshot(print(ds))
})

test_that("summary.cr_dataset output is stable", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  ds <- cr_dataset(exp$cells, design = exp$design, unit_var = "well")
  expect_snapshot(summary(ds))
})

test_that("print.cr_column_map output is stable", {
  map <- cr_column_map(
    exact = c("Event Label" = "cell_id", "Signal - Mean" = "target_signal"),
    prefix = c("^Nuclei - Area" = "area"),
    keep = c("cell_id", "target_signal", "area")
  )
  expect_snapshot(print(map))
})

test_that("print.cr_filename_grammar output is stable", {
  grammar <- cr_filename_grammar(
    tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM"),
    defaults = list(interval = "none"),
    typo_fixes = c("mikroM" = "uM")
  )
  expect_snapshot(print(grammar))
})

test_that("print.cr_merge_rules output is stable", {
  expect_snapshot(print(cr_merge_rules()))
})

test_that("print.cr_path_spec output is stable for named levels", {
  spec <- cr_path_spec(levels = c("run", "compound", "plate"))
  expect_snapshot(print(spec))
})

test_that("print.cr_path_spec output is stable for indexed levels", {
  # An integer vector maps a level name onto its position in the path,
  # which prints differently from the plain character form.
  spec <- cr_path_spec(
    levels = c(run = 1L, compound = 2L),
    grammar = cr_filename_grammar(tokens = list(dose = "[0-9]+uM")),
    markers = cr_marker_rules(merge_unit = "\\(split\\)"),
    strict = FALSE
  )
  expect_snapshot(print(spec))
})

test_that("print.cr_path_spec output is stable with nothing set", {
  expect_snapshot(print(cr_path_spec()))
})
