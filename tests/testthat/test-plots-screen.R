# Tests for the screen figure set: distributions with the unit of replication
# overlaid, the effect-size forest plot, and the design diagnostics.

# Local fixtures, so these tests do not depend on the example generators.
.cells_fixture <- function(seed = 1) {
  withr::with_seed(seed, {
    data.frame(
      treatment = rep(c("Vehicle", "CompoundA", "CompoundB"), each = 120),
      interval = rep(rep(c("5 min", "60 min"), each = 60), times = 3),
      well_id = rep(paste0("W", seq_len(18)), each = 20),
      class = rep(c("control", "donor", "donor"), each = 120),
      log2_fc = c(stats::rnorm(120, 0, 0.5), stats::rnorm(120, -0.8, 0.5),
                  stats::rnorm(120, -0.2, 0.5))
    )
  })
}

.effects_fixture <- function() {
  data.frame(
    group = rep(c("CompoundA", "CompoundB", "CompoundC"), 2),
    timing = rep(c("5 min", "60 min"), each = 3),
    class = rep(c("donor", "donor", "other"), 2),
    estimate = c(-1.2, -0.35, 0.1, -0.4, -0.1, 0.05),
    ci_low = c(-1.9, -0.95, -0.4, -1.1, -0.8, -0.5),
    ci_high = c(-0.5, 0.25, 0.6, 0.3, 0.6, 0.6)
  )
}

# ---- cr_plot_screen --------------------------------------------------------

test_that("cr_plot_screen overlays units aggregated from a cell column", {
  cells <- .cells_fixture()
  p <- cr_plot_screen(cells, units = "well_id", seed = 1)
  expect_s3_class(p, "ggplot")
  built <- ggplot2::ggplot_build(p)
  # reference line, violins, unit points
  expect_length(p$layers, 3L)
  # one point per unit, not one per cell
  expect_equal(nrow(built$data[[3]]), dplyr::n_distinct(cells$well_id))
})

test_that("cr_plot_screen states the unit of replication in the subtitle", {
  p <- cr_plot_screen(.cells_fixture(), units = "well_id", seed = 1)
  expect_match(p$labels$subtitle, "unit of replication", fixed = TRUE)
  expect_match(p$labels$subtitle, "well_id", fixed = TRUE)
})

test_that("cr_plot_screen works without units, with facets and with colour", {
  cells <- .cells_fixture()
  bare <- cr_plot_screen(cells, units = NULL)
  expect_length(bare$layers, 2L)
  expect_no_match(bare$labels$subtitle, "unit of replication", fixed = TRUE)

  faceted <- cr_plot_screen(cells, units = "well_id", facet_by = "interval",
                            colour_by = "class", seed = 2)
  expect_s3_class(faceted, "ggplot")
  expect_no_error(ggplot2::ggplot_build(faceted))

  grid <- cr_plot_screen(cells, units = "well_id",
                         facet_by = c("interval", "class"), seed = 2)
  expect_no_error(ggplot2::ggplot_build(grid))
})

test_that("cr_plot_screen accepts a unit table and a cr_experiment", {
  cells <- .cells_fixture()
  units <- data.frame(treatment = rep(c("Vehicle", "CompoundA"), each = 4),
                      lfc = withr::with_seed(3, stats::rnorm(8)))
  p <- cr_plot_screen(cells[cells$treatment != "CompoundB", ], units = units,
                      unit_value = "lfc")
  expect_equal(nrow(ggplot2::ggplot_build(p)$data[[3]]), nrow(units))

  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  p2 <- cr_plot_screen(exp, value = "marker_1", units = "well",
                       reference = NULL)
  expect_s3_class(p2, "ggplot")
  expect_length(p2$layers, 2L)
})

test_that("cr_plot_screen fails informatively on bad columns", {
  cells <- .cells_fixture()
  expect_error(cr_plot_screen(cells, units = "nope"), "not in")
  expect_error(cr_plot_screen(cells, value = "nope"), "required column")
  expect_error(cr_plot_screen("x"), "must be a data frame")
})

test_that("labels follow the NULL-default / NA-omit contract", {
  cells <- .cells_fixture()
  default <- cr_plot_screen(cells, units = "well_id", seed = 1)
  expect_null(default$labels$x)
  expect_equal(default$labels$y, "log2_fc")
  expect_null(default$labels$title)

  custom <- cr_plot_screen(cells, units = "well_id", seed = 1,
                           title = "Screen", x_lab = "group",
                           y_lab = NA, subtitle = NA)
  expect_equal(custom$labels$title, "Screen")
  expect_equal(custom$labels$x, "group")
  expect_null(custom$labels$y)
  expect_null(custom$labels$subtitle)
})

# ---- cr_plot_forest --------------------------------------------------------

test_that("cr_plot_forest orders rows by the estimate", {
  eff <- .effects_fixture()[1:3, ]
  p <- cr_plot_forest(eff)
  expect_s3_class(p, "ggplot")
  expect_identical(levels(p$data$group),
                   c("CompoundA", "CompoundB", "CompoundC"))
  desc <- cr_plot_forest(eff, descending = TRUE)
  expect_identical(levels(desc$data$group),
                   c("CompoundC", "CompoundB", "CompoundA"))
  kept <- cr_plot_forest(eff, order_by_estimate = FALSE)
  expect_identical(levels(kept$data$group), as.character(eff$group))
})

test_that("cr_plot_forest computes the exclude-zero sentence from the data", {
  eff <- .effects_fixture()
  # only CompoundA's interval sits wholly below zero
  expect_match(cr_plot_forest(eff[1:3, ])$labels$subtitle,
               "CompoundA's interval excludes the reference", fixed = TRUE)
  expect_match(cr_plot_forest(eff[4:6, ])$labels$subtitle,
               "no interval excludes the reference", fixed = TRUE)
  per_facet <- cr_plot_forest(eff, facet_by = "timing")$labels$subtitle
  expect_match(per_facet, "5 min: CompoundA", fixed = TRUE)
  expect_match(per_facet, "60 min: no interval", fixed = TRUE)
  expect_null(cr_plot_forest(eff, subtitle = NA)$labels$subtitle)
})

test_that("cr_plot_forest supports facets, colour and method filtering", {
  eff <- .effects_fixture()
  p <- cr_plot_forest(eff, facet_by = "timing", colour_by = "class")
  expect_no_error(ggplot2::ggplot_build(p))

  multi <- data.frame(
    group = rep(c("A", "B"), 2),
    method = rep(c("cohens_d", "hedges_g"), each = 2),
    estimate = c(1, 2, 3, 4) / 4,
    ci_low = c(0, 1, 2, 3) / 4,
    ci_high = c(2, 3, 4, 5) / 4
  )
  expect_equal(nrow(cr_plot_forest(multi)$data), 2L)
  expect_equal(nrow(cr_plot_forest(multi, method = "hedges_g")$data), 2L)
  expect_error(cr_plot_forest(multi, method = "nope"), "No rows left")
})

test_that("cr_plot_forest fails informatively", {
  eff <- .effects_fixture()
  expect_error(cr_plot_forest(eff[, -1]), "labels the rows")
  expect_error(cr_plot_forest(eff, ci_low = "lo"), "required column")
  expect_error(cr_plot_forest("x"), "must be a data frame")
})

test_that("cr_plot_effect_sizes still accepts cr_result objects", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 15)
  all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  p <- cr_plot_effect_sizes(all_res)
  expect_s3_class(p, "ggplot")
  expect_match(p$labels$x, "cohens_d", fixed = TRUE)
  expect_no_error(ggplot2::ggplot_build(p))
})

# ---- cr_plot_sample_size ---------------------------------------------------

test_that("cr_plot_sample_size draws both bars and drops missing ones", {
  sizes <- data.frame(
    group = c("CompoundA", "CompoundB", "CompoundC"),
    n_observed = c(12, 84, 640),
    n_conservative = c(46, NA, NA),
    n_available = c(6, 6, 6)
  )
  p <- cr_plot_sample_size(sizes, available = "n_available")
  expect_s3_class(p, "ggplot")
  # 3 observed + 1 conservative, the two NA rows are dropped
  expect_equal(nrow(p$data), 4L)
  expect_match(p$labels$caption, "1 of 3 groups", fixed = TRUE)
  built <- ggplot2::ggplot_build(p)
  expect_true(any(grepl("(6)", built$layout$panel_params[[1]]$x$get_labels(),
                        fixed = TRUE)))
})

test_that("cr_plot_sample_size supports colour and a linear axis", {
  sizes <- data.frame(group = c("A", "B"), n_observed = c(10, 20),
                      n_conservative = c(30, 40),
                      class = c("donor", "other"))
  p <- cr_plot_sample_size(sizes, colour_by = "class", log_y = FALSE)
  expect_no_error(ggplot2::ggplot_build(p))
  expect_error(
    cr_plot_sample_size(data.frame(group = "A", n_observed = NA,
                                   n_conservative = NA)),
    "No finite sample sizes"
  )
  expect_error(cr_plot_sample_size(data.frame(x = 1)), "labels the groups")
})

# ---- cr_plot_specificity ---------------------------------------------------

test_that("cr_plot_specificity draws violins for cell-level input", {
  spec <- withr::with_seed(1, data.frame(
    arm = rep(c("omitted + vehicle", "omitted + exposed",
                "present + vehicle", "present + exposed"), each = 40),
    value = c(stats::rlnorm(40, 3, 0.3), stats::rlnorm(40, 3.05, 0.3),
              stats::rlnorm(40, 4.5, 0.3), stats::rlnorm(40, 6.2, 0.3))
  ))
  p <- cr_plot_specificity(spec)
  expect_s3_class(p, "ggplot")
  expect_length(p$layers, 2L)
  expect_null(p$labels$subtitle)

  ratio <- cr_plot_specificity(
    spec, ratio_arms = c("present + exposed", "omitted + exposed")
  )
  expect_match(ratio$labels$subtitle, "signal-to-background", fixed = TRUE)
  expect_identical(levels(p$data$arm)[[1]], "omitted + vehicle")
})

test_that("cr_plot_specificity draws columns for a summarised table", {
  tab <- data.frame(arm = c("omitted", "present"),
                    median_signal = c(20, 480), n_units = c(4L, 12L))
  attr(tab, "signal_to_background") <- 24
  p <- cr_plot_specificity(tab)
  expect_length(p$layers, 1L)
  expect_match(p$labels$subtitle, "24.0 times higher", fixed = TRUE)
  expect_error(cr_plot_specificity(data.frame(arm = c("a", "b"),
                                              k = c("x", "y"))),
               "holds the signal")
})

# ---- cr_plot_qc_gate -------------------------------------------------------

test_that("cr_plot_qc_gate classifies units against their own control", {
  units <- data.frame(
    well_id = paste0("W", seq_len(6)),
    unit_median = c(200, 300, 400, 50, 60, 500),
    ctrl_median = rep(100, 6)
  )
  units$unit_median[4:5] <- c(50, 60)
  p <- cr_plot_qc_gate(units, label = "well_id")
  expect_s3_class(p, "ggplot")
  expect_equal(sum(p$data$.verdict == "excluded"), 2L)
  expect_match(p$labels$subtitle, "2 excluded", fixed = TRUE)
  # the failing units get a text layer; passing ones do not
  expect_length(p$layers, 3L)
})

test_that("cr_plot_qc_gate separates verdicts that depend on the centre", {
  units <- data.frame(
    well_id = paste0("W", seq_len(4)),
    unit_median = c(200, 90, 105, 50),
    ctrl_median = rep(100, 4),
    fails_vs_median = c(FALSE, TRUE, FALSE, TRUE),
    fails_vs_mean = c(FALSE, TRUE, TRUE, TRUE)
  )
  p <- cr_plot_qc_gate(list(units = units))
  expect_equal(as.integer(table(p$data$.verdict)),
               c(1L, 1L, 2L))
  expect_match(p$labels$subtitle, "1 verdict depend", fixed = TRUE)
})

test_that("cr_plot_qc_gate honours direction and fails informatively", {
  units <- data.frame(unit_median = c(200, 50), ctrl_median = c(100, 100))
  less <- cr_plot_qc_gate(units, direction = "less", log_scale = FALSE)
  expect_equal(sum(less$data$.verdict == "excluded"), 1L)
  expect_error(cr_plot_qc_gate(data.frame(a = 1, b = 2)),
               "unit and control statistic")
})

# ---- cr_save_plot ----------------------------------------------------------

test_that("cr_save_plot writes one non-empty file per format", {
  p <- cr_plot_forest(.effects_fixture()[1:3, ])
  dir <- withr::local_tempdir()
  paths <- cr_save_plot(p, file.path(dir, "figure-1.png"), width = 5,
                        formats = c("png", "pdf"), quiet = TRUE)
  expect_message(
    cr_save_plot(p, file.path(dir, "figure-2"), width = 5, formats = "png"),
    "Wrote 1 file"
  )
  expect_length(paths, 2L)
  expect_true(all(file.exists(paths)))
  expect_true(all(file.size(paths) > 0))
  expect_identical(tools::file_ext(paths), c("png", "pdf"))
  expect_error(cr_save_plot(p, file.path(dir, "x"), formats = character()),
               "at least one file format")
})
