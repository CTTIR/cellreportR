# Degenerate inputs the pipeline has to survive: a single acquisition
# unit, a channel that is entirely missing, a batch holding no control
# and a batch holding no cells. These are the shapes a real plate takes
# on when a run goes wrong, and each of them has to either produce a
# usable answer or say plainly why it cannot.

# ---- fixtures -----------------------------------------------------------

cr_single_unit <- function() {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  cr_build_experiment(exp$cells[exp$cells$well == "A01", ],
                      exp$design[exp$design$well == "A01", ])
}

cr_all_na_channel <- function() {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  exp$cells$marker_2 <- NA_real_
  exp
}

# One batch holds every control unit, the other holds none of them.
cr_batch_without_control <- function() {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  exp$design$batch <- ifelse(exp$design$treatment == "Untreated",
                             "b_control", "b_orphan")
  exp
}

# A batch level that survives in the design after its cells were lost.
cr_empty_batch <- function() {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  dropped <- c("A01", "B01")
  exp$design$batch <- ifelse(exp$design$well %in% dropped,
                             "b_empty", "b_main")
  exp$cells <- exp$cells[!exp$cells$well %in% dropped, ]
  exp
}

# ---- a single acquisition unit -----------------------------------------

test_that("an experiment with a single unit is valid", {
  exp <- cr_single_unit()
  expect_s3_class(exp, "cr_experiment")
  expect_silent(cr_validate_experiment(exp))
  expect_equal(dplyr::n_distinct(exp$cells$well), 1L)
  expect_equal(nrow(exp$design), 1L)
})

test_that("a single unit summarises to one row", {
  exp <- cr_single_unit()
  wells <- cr_summarize_wells(exp, "marker_1")
  expect_equal(nrow(wells), 1L)
  expect_equal(wells$n_cells, cr_n_cells(exp))
  utils::capture.output(per_treatment <- summary(exp))
  expect_equal(nrow(per_treatment), 1L)
})

test_that("the gate on a single unit compares it against itself", {
  exp <- cr_single_unit()
  gate <- cr_qc_gate(exp, channel = "marker_1", control_level = "Untreated")
  expect_s3_class(gate, "cr_qc_gate")
  expect_equal(nrow(gate$units), 1L)
  # the only unit is the control, so nothing can fail against it
  expect_length(gate$excluded, 0L)
  expect_equal(nrow(gate$disputed), 0L)
})

test_that("an effect grid over a single unit says there is nothing to contrast", {
  exp <- cr_single_unit()
  expect_error(
    cr_effect_grid(exp, value = "marker_1", group_var = "treatment",
                   reference_level = "Untreated"),
    "No comparison levels"
  )
})

test_that("normalisation and figures still work on a single unit", {
  exp <- cr_single_unit()
  out <- cr_normalize(exp, "marker_1", method = "zscore")
  expect_equal(nrow(out$cells), nrow(exp$cells))
  expect_s3_class(cr_plot_intensity(exp, "marker_1"), "ggplot")
  expect_s3_class(cr_plot_spatial(exp, "marker_1"), "ggplot")
})

test_that("a single unit assembles into a report", {
  exp <- cr_single_unit()
  rep <- cr_report(exp, render = FALSE)
  expect_s3_class(rep, "cr_report")
  expect_equal(nrow(rep$summary), 0L)
  expect_equal(sum(cr_table_disposition(exp)$n_units), 2L)
})

# ---- a channel that is entirely missing ---------------------------------

test_that("an all-NA channel gates every unit to a missing statistic", {
  exp <- cr_all_na_channel()
  gate <- cr_qc_gate(exp, channel = "marker_2", control_level = "Untreated")
  expect_equal(nrow(gate$units), nrow(exp$design))
  expect_true(all(is.na(gate$units$unit_statistic)))
  # nothing can be judged to fail against a reference that is not there
  expect_length(gate$excluded, 0L)
})

test_that("an all-NA channel summarises to NA rather than erroring", {
  exp <- cr_all_na_channel()
  wells <- cr_summarize_wells(exp, "marker_2")
  expect_equal(nrow(wells), nrow(exp$design))
  expect_true(all(is.na(wells$value)))
})

test_that("an all-NA channel yields an empty effect grid", {
  exp <- cr_all_na_channel()
  grid <- cr_effect_grid(exp, value = "marker_2", group_var = "treatment",
                         reference_level = "Untreated", unit = "well",
                         min_n = 3, test = "t")
  expect_equal(nrow(grid), 0L)
})

test_that("normalising an all-NA channel keeps it all NA", {
  exp <- cr_all_na_channel()
  for (method in c("zscore", "robust_zscore", "quantile")) {
    out <- cr_normalize(exp, "marker_2", method = method)
    expect_true(all(is.na(out$cells$marker_2)))
    expect_equal(nrow(out$cells), nrow(exp$cells))
  }
})

test_that("batch correction on an all-NA channel keeps it all NA", {
  exp <- cr_all_na_channel()
  exp$design$batch <- rep(c("b1", "b2"), length.out = nrow(exp$design))
  out <- cr_correct_batch(exp, batch_var = "batch", channel = "marker_2")
  expect_true(all(is.na(out$cells$marker_2)))
  expect_equal(nrow(out$cells), nrow(exp$cells))
})

test_that("a test on an all-NA channel fails loudly", {
  exp <- cr_all_na_channel()
  expect_error(
    cr_test(exp, "marker_2", "CompoundA_high", "Untreated", level = "cell")
  )
  expect_error(
    cr_logistic(exp, "marker_2", "CompoundA_high", "Untreated"),
    "two distinct groups"
  )
})

test_that("figures over an all-NA channel still return a plot", {
  exp <- cr_all_na_channel()
  expect_s3_class(cr_plot_intensity(exp, "marker_2"), "ggplot")
  expect_s3_class(cr_plot_heatmap(exp, c("marker_1", "marker_2")), "ggplot")
})

# ---- a batch with no control -------------------------------------------

test_that("cr_batch_reference flags the batch that carries no control", {
  exp <- cr_batch_without_control()
  ref <- cr_batch_reference(exp, channel = "marker_1", batch_vars = "batch",
                            control_level = "Untreated")
  expect_equal(nrow(ref), 2L)
  expect_equal(ref$has_control[ref$batch == "b_control"], TRUE)
  expect_equal(ref$has_control[ref$batch == "b_orphan"], FALSE)
  expect_equal(ref$ctrl_n[ref$batch == "b_orphan"], 0L)
  expect_true(is.na(ref$ctrl_median[ref$batch == "b_orphan"]))
})

test_that("standardising against an absent control refuses and names it", {
  exp <- cr_batch_without_control()
  expect_error(
    cr_standardize_batch(exp, channel = "marker_1", batch_var = "batch",
                         control_level = "Untreated"),
    "no control cells"
  )
  expect_error(
    cr_standardize_batch(exp, channel = "marker_1", batch_var = "batch",
                         control_level = "Untreated"),
    "b_orphan"
  )
})

test_that("median centering still runs when a batch has no control", {
  # median_center needs no control at all, only a batch key.
  exp <- cr_batch_without_control()
  out <- cr_correct_batch(exp, batch_var = "batch", channel = "marker_1")
  expect_equal(nrow(out$cells), nrow(exp$cells))
  expect_false(anyNA(out$cells$marker_1))
})

test_that("the gate still judges every unit when a batch has no control", {
  exp <- cr_batch_without_control()
  gate <- cr_qc_gate(exp, channel = "marker_1", control_level = "Untreated",
                     batch_vars = "batch")
  expect_equal(nrow(gate$units), nrow(exp$design))
  # units in the control-free batch have no reference to be judged against
  orphan <- exp$design$well[exp$design$batch == "b_orphan"]
  judged <- gate$units[gate$units$well %in% orphan, ]
  expect_true(all(is.na(judged$control_reference)))
})

# ---- a batch with no cells ---------------------------------------------

test_that("a design batch with no cells behind it is still valid", {
  exp <- cr_empty_batch()
  expect_silent(cr_validate_experiment(exp))
  expect_equal(nrow(exp$design), 96L)
  expect_equal(dplyr::n_distinct(exp$cells$well), 94L)
})

test_that("an empty batch contributes no units to the gate", {
  exp <- cr_empty_batch()
  gate <- cr_qc_gate(exp, channel = "marker_1", control_level = "Untreated",
                     batch_vars = "batch")
  expect_equal(nrow(gate$units), 94L)
  expect_false(any(c("A01", "B01") %in% gate$units$well))
})

test_that("an empty batch drops out of the batch key entirely", {
  exp <- cr_empty_batch()
  joined <- cellreportR:::.cr_batch_table(exp)
  expect_setequal(unique(cr_batch_key(joined, "batch")), "b_main")
})

test_that("batch correction ignores a batch with no cells", {
  exp <- cr_empty_batch()
  out <- cr_correct_batch(exp, batch_var = "batch", channel = "marker_1")
  expect_equal(nrow(out$cells), nrow(exp$cells))
  expect_false(anyNA(out$cells$marker_1))
})

test_that("the disposition table counts only units that carry cells", {
  exp <- cr_empty_batch()
  disp <- cr_table_disposition(exp)
  total <- disp[disp$treatment == "(total)", ]
  expect_equal(total$n_units, 94L)
  expect_equal(total$n_cells, nrow(exp$cells))
  # the two lost units came out of the control group
  untreated <- disp[disp$treatment == "Untreated", ]
  expect_equal(untreated$n_units, 14L)
})

test_that("an empty batch still assembles into a report", {
  exp <- cr_empty_batch()
  rep <- cr_report(exp, render = FALSE)
  expect_s3_class(rep, "cr_report")
  expect_equal(sum(rep$tables$disposition$n_cells), 2 * nrow(exp$cells))
})

# ---- an experiment with no cells at all ---------------------------------

test_that("filtering everything away leaves a usable, empty experiment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  empty <- cr_filter_cells(exp, marker_1 > 1e12)
  expect_equal(cr_n_cells(empty), 0L)
  expect_equal(nrow(empty$cells), 0L)
  expect_silent(cr_validate_experiment(empty))
})

test_that("the quality-control log records a filter that removed everything", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  empty <- cr_filter_cells(exp, marker_1 > 1e12)
  log <- cr_qc_summary(empty)
  expect_equal(nrow(log), 1L)
  expect_equal(log$cells_after, 0L)
  expect_equal(log$cells_removed, nrow(exp$cells))
  expect_equal(log$percent_removed, 100)
})

test_that("summarising an empty experiment says what is missing", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  empty <- cr_filter_cells(exp, marker_1 > 1e12)
  expect_error(cr_summarize_wells(empty, "marker_1"),
               "No cells carry an analysis unit identifier")
})

test_that("an empty experiment still prints and assembles", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 6)
  empty <- cr_filter_cells(exp, marker_1 > 1e12)
  txt <- paste(utils::capture.output(print(empty), type = "message"),
               collapse = "\n")
  expect_match(txt, "Cells: 0")
  expect_s3_class(cr_report(empty, render = FALSE), "cr_report")
})
