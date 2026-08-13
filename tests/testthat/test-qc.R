test_that("cr_qc_filter removes cells outside area range and logs", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  before <- nrow(exp$cells)
  exp2 <- cr_qc_filter(exp, min_area = 50, max_area = 2000)
  expect_lte(nrow(exp2$cells), before)
  expect_equal(nrow(exp2$qc_log), 1)
  expect_true(grepl("min_area", exp2$qc_log$parameters[1]))
})

test_that("cr_qc_filter with no thresholds does nothing", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_qc_filter(exp)
  expect_equal(nrow(exp2$cells), nrow(exp$cells))
})

test_that("cr_qc_doublets removes very large cells", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  before <- nrow(exp$cells)
  exp2 <- cr_qc_doublets(exp, k = 1.2)
  expect_lt(nrow(exp2$cells), before)
})

test_that("cr_qc_doublets can threshold a channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_qc_doublets(exp, channel = "DAPI",
                         threshold_method = "channel", k = 1.5)
  expect_lt(nrow(exp2$cells), nrow(exp$cells))
  expect_true(all(exp2$cells$DAPI <=
                    1.5 * stats::median(exp$cells$DAPI, na.rm = TRUE)))
  expect_true(grepl("variable=DAPI", exp2$qc_log$parameters[1]))
  # a channel method without a channel is a warning, not an error
  expect_warning(cr_qc_doublets(exp, threshold_method = "channel"),
                 "not applied")
  expect_error(cr_qc_doublets(exp, threshold_method = "nonsense"))
})

test_that("cr_qc_intensity gates on a channel", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  before <- nrow(exp$cells)
  exp2 <- cr_qc_intensity(exp, "DAPI", min_intensity = 100)
  expect_lte(nrow(exp2$cells), before)
  expect_error(cr_qc_intensity(exp, "nonsense"), "not found")
})

test_that("cr_qc_manual removes a well", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  w <- "A01"
  before <- nrow(exp$cells)
  exp2 <- cr_qc_manual(exp, well = w)
  expect_false(any(exp2$cells$well == w))
  expect_lt(nrow(exp2$cells), before)
})

test_that("cr_qc_summary returns the QC log", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp <- cr_qc_filter(exp, min_area = 30)
  tbl <- cr_qc_summary(exp)
  expect_s3_class(tbl, "tbl_df")
  expect_equal(nrow(tbl), 1)
  expect_true("cells_before" %in% names(tbl))
})

# ---- sub-threshold exclusion ----

test_that("cr_exclude_small drops the lowest quantile and records it", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp2 <- cr_exclude_small(exp, var = "area", probs = 0.10)
  thr <- exp2$metadata$exclude_small$threshold
  expect_length(thr, 1)
  expect_true(all(exp2$cells$area >= thr))
  expect_equal(nrow(exp2$cells) / nrow(exp$cells), 0.9, tolerance = 0.02)
  expect_equal(cr_qc_summary(exp2)$step, "cr_exclude_small")
  expect_true(grepl("threshold=", cr_qc_summary(exp2)$parameters))
})

test_that("cr_exclude_small honours an explicit threshold", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  exp2 <- cr_exclude_small(exp, threshold = 300)
  expect_true(all(exp2$cells$area >= 300))
  expect_equal(exp2$metadata$exclude_small$threshold, 300)
})

test_that("cr_exclude_small computes one threshold per batch", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp2 <- cr_exclude_small(exp, scope = "batch", batch_vars = "replicate")
  thr <- exp2$metadata$exclude_small
  expect_equal(nrow(thr), length(unique(exp$design$replicate)))
  expect_true(all(c("replicate", "n_cells", "threshold") %in% names(thr)))
  expect_gt(length(unique(thr$threshold)), 1)
  expect_lt(nrow(exp2$cells), nrow(exp$cells))
})

test_that("cr_exclude_small validates its arguments", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_exclude_small(exp, scope = "batch"), "batch_vars")
  expect_error(cr_exclude_small(exp, var = "nonsense"), "missing")
  expect_error(cr_exclude_small(exp, var = "well"), "numeric")
  expect_error(cr_exclude_small(exp, probs = 2), "between 0 and 1")
  expect_error(cr_exclude_small(exp, threshold = "big"), "finite number")
})

# ---- cell count balancing ----

test_that("cr_balance_cells caps units at n_max and is reproducible", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
  b1 <- cr_balance_cells(exp, n_max = 20, seed = 1)
  b2 <- cr_balance_cells(exp, n_max = 20, seed = 1)
  expect_identical(b1$cells$cell_id, b2$cells$cell_id)
  expect_lte(max(table(b1$cells$well)), 20)
  expect_equal(max(b1$metadata$balance_cells$n_after), 20)
  expect_equal(cr_qc_summary(b1)$step, "cr_balance_cells")
})

test_that("cr_balance_cells equalises units when no size is given", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
  b <- cr_balance_cells(exp, seed = 2)
  counts <- table(b$cells$well)
  expect_length(unique(as.integer(counts)), 1)
  expect_equal(as.integer(counts)[1], min(table(exp$cells$well)))
})

test_that("cr_balance_cells takes exactly n cells per unit", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
  b <- cr_balance_cells(exp, n = 15, seed = 3)
  expect_true(all(table(b$cells$well) <= 15))
  expect_equal(max(table(b$cells$well)), 15)
})

test_that("cr_balance_cells leaves the caller's RNG stream untouched", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  set.seed(99)
  state <- .Random.seed
  cr_balance_cells(exp, n_max = 10, seed = 1)
  expect_identical(state, .Random.seed)
})

test_that("cr_balance_cells validates its arguments", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_balance_cells(exp, n = 5, n_max = 5), "not both")
  expect_error(cr_balance_cells(exp, n = -1), "positive")
  expect_error(cr_balance_cells(exp, n_max = 0), "positive")
  expect_error(cr_balance_cells(exp, unit = "nonsense"), "not found")
})

# ---- the QC gate ----

test_that("cr_qc_gate scores every unit against its own batch control", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
  gate <- cr_qc_gate(exp, channel = "marker_1",
                     control_level = "Untreated", batch_vars = "replicate")
  expect_s3_class(gate, "cr_qc_gate")
  expect_equal(nrow(gate$units), nrow(exp$design))
  expect_true(all(c("raw_mean", "raw_median", "ctrl_mean", "ctrl_median",
                    "pct_of_control", "fails_vs_median", "fails_vs_mean",
                    "disputed", "verdict", "reason") %in% names(gate$units)))
  # control units are the reference arm, not gated
  expect_true(all(gate$units$verdict[gate$units$is_control] == "control"))
  expect_false(any(gate$excluded %in%
                     gate$units[[gate$params$unit]][gate$units$is_control]))
  # one control statistic per batch, shared by all units of that batch
  expect_equal(length(unique(gate$units$ctrl_median)),
               length(unique(exp$design$replicate)))
})

test_that("cr_qc_gate records both control centres and flags the disputes", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 40)
  med <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  avg <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate",
                    reference = "mean")
  # the signal is right-skewed, so the mean reference is the stricter gate
  expect_gt(length(avg$excluded), length(med$excluded))
  expect_setequal(med$excluded,
                  med$units[[med$params$unit]][med$units$fails_vs_median %in% TRUE &
                                                 med$units$gated])
  expect_setequal(avg$excluded,
                  avg$units[[avg$params$unit]][avg$units$fails_vs_mean %in% TRUE &
                                                 avg$units$gated])
  # the disputed set is exactly the difference between the two verdicts
  expect_setequal(med$disputed[[med$params$unit]],
                  setdiff(avg$excluded, med$excluded))
  expect_true(all(med$disputed$gated))
})

test_that("cr_qc_gate honours direction, gate_controls and min_cells", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  up <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  down <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate",
                     direction = "less")
  expect_equal(sum(up$units$gated), sum(down$units$gated))
  expect_setequal(c(up$excluded, down$excluded),
                  up$units[[up$params$unit]][up$units$gated])
  with_ctrl <- cr_qc_gate(exp, "marker_1", "Untreated",
                          batch_vars = "replicate", gate_controls = TRUE)
  expect_gt(sum(with_ctrl$units$gated), sum(up$units$gated))
  thin <- cr_qc_gate(exp, "marker_1", "Untreated", min_cells = 1e6)
  expect_equal(length(thin$excluded), nrow(thin$units))
  expect_true(all(grepl("fewer than", thin$units$reason)))
})

test_that("cr_qc_gate works without batch variables and validates input", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  g <- cr_qc_gate(exp, "marker_1", "Untreated")
  expect_equal(length(unique(g$units$ctrl_median)), 1)
  expect_false(".cr_batch" %in% names(g$units))
  expect_error(cr_qc_gate(exp, "marker_1", "nonsense"), "No cells belong")
  expect_error(cr_qc_gate(exp, "nonsense", "Untreated"), "missing")
  expect_error(cr_qc_gate(exp, "well", "Untreated"), "numeric")
  expect_error(cr_qc_gate(exp, "marker_1", "Untreated",
                          batch_vars = "nonsense"), "missing")
})

test_that("print.cr_qc_gate reports the gate", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  msg <- paste(testthat::capture_messages(print(gate)), collapse = "")
  expect_match(msg, "QC gate")
  expect_match(msg, "control median")
  expect_match(msg, "excluded under the chosen rule")
  expect_invisible(suppressMessages(print(gate)))
})

# ---- leverage of the exclusions ----

test_that("cr_qc_gate_impact re-estimates contrasts with and without", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp$cells$signal <- log2(exp$cells$marker_1)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate",
                     reference = "mean")
  imp <- cr_qc_gate_impact(exp, gate, value = "signal",
                           group_var = "treatment",
                           reference_level = "Untreated")
  expect_s3_class(imp, "tbl_df")
  expect_gt(nrow(imp), 0)
  expect_true(all(c("estimate_with_excluded", "estimate_without_excluded",
                    "magnitude_with_excluded", "magnitude_without_excluded",
                    "magnitude_changed", "sign_changed") %in% names(imp)))
  # contrasts that lost no unit are unchanged; the others move
  untouched <- imp$n_units_excluded == 0
  expect_equal(imp$estimate_with_excluded[untouched],
               imp$estimate_without_excluded[untouched])
  expect_false(any(imp$estimate_with_excluded[!untouched] ==
                     imp$estimate_without_excluded[!untouched]))
})

test_that("cr_qc_gate_impact returns a typed empty result when nothing is excluded", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp$cells$signal <- log2(exp$cells$marker_1)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  gate$excluded <- character()
  imp <- cr_qc_gate_impact(exp, gate, value = "signal",
                           group_var = "treatment",
                           reference_level = "Untreated", by = "group")
  expect_s3_class(imp, "tbl_df")
  expect_equal(nrow(imp), 0)
  expect_equal(names(imp)[1], "group")
})

test_that("cr_qc_gate_impact warns when called after the gate was applied", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  exp$cells$signal <- log2(exp$cells$marker_1)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate",
                     reference = "mean")
  applied <- cr_apply_gate(exp, gate)
  expect_warning(
    imp <- cr_qc_gate_impact(applied, gate, value = "signal",
                             group_var = "treatment",
                             reference_level = "Untreated"),
    "before"
  )
  expect_equal(nrow(imp), 0)
})

test_that("cr_qc_gate_impact validates its arguments", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  expect_error(cr_qc_gate_impact(exp, "not a gate", value = "marker_1",
                                 group_var = "treatment",
                                 reference_level = "Untreated"),
               "cr_qc_gate")
  expect_error(cr_qc_gate_impact(exp, gate, value = "marker_1",
                                 group_var = "treatment",
                                 reference_level = "nonsense"),
               "not found")
  expect_error(cr_qc_gate_impact(exp, gate, value = "well",
                                 group_var = "treatment",
                                 reference_level = "Untreated"),
               "numeric")
})

# ---- applying the gate and auditing it ----

test_that("cr_apply_gate removes the failing units and logs the step", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate",
                     reference = "mean")
  exp2 <- cr_apply_gate(exp, gate)
  expect_false(any(exp2$cells$well %in% gate$excluded))
  expect_lt(nrow(exp2$cells), nrow(exp$cells))
  expect_equal(cr_qc_summary(exp2)$step, "cr_apply_gate")
  expect_s3_class(exp2$metadata$qc_gate, "cr_qc_gate")
  expect_true(grepl("median vs mean", cr_qc_summary(exp2)$parameters))
})

test_that("cr_apply_gate can drop disputed units and explicit units", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  strict <- cr_apply_gate(exp, gate, drop_disputed = TRUE)
  expect_lt(nrow(strict$cells), nrow(cr_apply_gate(exp, gate)$cells))
  manual <- cr_apply_gate(exp, gate, units = "A01")
  expect_false(any(manual$cells$well == "A01"))
  expect_error(cr_apply_gate(exp, list()), "cr_qc_gate")
})

test_that("cr_qc_report keeps excluded units in the record", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate",
                     reference = "mean")
  exp2 <- cr_apply_gate(exp, gate)
  rep <- cr_qc_report(exp2)
  expect_s3_class(rep, "tbl_df")
  expect_equal(nrow(rep), nrow(gate$units))
  expect_true(all(c("n_cells_gated", "n_cells", "retained", "verdict",
                    "reason", "pct_of_control") %in% names(rep)))
  # every excluded unit is still listed, with zero cells left
  expect_setequal(rep$well[!rep$retained], gate$excluded)
  expect_true(all(rep$n_cells[!rep$retained] == 0))
  expect_equal(rep$verdict[1], "fail")
  expect_true(all(nzchar(rep$reason[rep$verdict == "fail"])))
})

test_that("cr_qc_report works without a gate and with extra columns", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  plain <- cr_qc_report(exp)
  expect_equal(nrow(plain), nrow(exp$design))
  expect_true(all(plain$verdict == "not gated"))
  expect_true(all(plain$retained))
  expect_true("treatment" %in% names(plain))

  gate <- cr_qc_gate(exp, "marker_1", "Untreated", batch_vars = "replicate")
  picked <- cr_qc_report(exp, gate = gate, vars = c("replicate", "group"))
  expect_true(all(c("replicate", "group") %in% names(picked)))
  expect_equal(nrow(picked), nrow(gate$units))
})
