# Assembly of the cr_report object and the table exporters. Rendering
# is covered in test-report.R; nothing here needs pandoc.

.report_fixture <- function(n = 12) {
  cr_example_experiment(seed = 1, n_cells_per_well = n)
}

.effects_fixture <- function() {
  tibble::tibble(
    group = c("CompoundA", "CompoundB", "CompoundC"),
    estimate = c(1.42, 0.31, -0.88),
    ci_low = c(0.55, -0.10, -1.60),
    ci_high = c(2.29, 0.72, -0.16)
  )
}

# ---- assembly ----

test_that("cr_report returns a cr_report with the documented slots", {
  exp <- .report_fixture()
  rep <- cr_report(exp, title = "Overview")
  expect_s3_class(rep, "cr_report")
  expect_true(all(c("experiment", "results", "summary", "qc", "effects",
                    "sizes", "tables", "plots", "metadata", "params") %in%
                    names(rep)))
  expect_identical(rep$params$title, "Overview")
  expect_s3_class(rep$qc, "tbl_df")
})

test_that("cr_report adds a disposition table by default", {
  exp <- .report_fixture()
  rep <- cr_report(exp)
  expect_true("disposition" %in% names(rep$tables))
  expect_gt(nrow(rep$tables$disposition), 0)

  supplied <- cr_report(exp, tables = list(disposition = tibble::tibble(a = 1)))
  expect_equal(nrow(supplied$tables$disposition), 1)
})

test_that("cr_report defaults its QC record to the experiment QC log", {
  exp <- cr_filter_cells(.report_fixture(), area > 100)
  rep <- cr_report(exp)
  expect_equal(nrow(rep$qc), 1)
  expect_equal(rep$qc$step, "cr_filter_cells")
})

test_that("cr_report joins sample sizes onto the effect grid", {
  exp <- .report_fixture()
  sizes <- tibble::tibble(
    group = c("CompoundA", "CompoundB", "CompoundC"),
    n_observed = c(9, 165, 24),
    n_conservative = c(54, NA, 210)
  )
  rep <- cr_report(exp, effects = .effects_fixture(), sizes = sizes)
  expect_true(all(c("estimate", "n_observed", "n_conservative") %in%
                    names(rep$summary)))
  expect_equal(nrow(rep$summary), 3)
})

test_that("cr_report summarises a list of cr_result objects", {
  exp <- .report_fixture()
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  rep <- cr_report(exp, res)
  expect_equal(nrow(rep$summary), 1)
  expect_true(all(c("treatment", "control", "p_value") %in% names(rep$summary)))
  expect_named(rep$results, "CompoundA_high")
})

test_that("cr_report validates its inputs", {
  exp <- .report_fixture()
  expect_error(cr_report(list(not = "an experiment")), "cr_experiment")
  expect_error(cr_report(exp, effects = 42), "data frame")
  expect_error(cr_report(exp, plots = 42), "named list")
  expect_error(cr_report(exp, render = "yes"), "render")
})

# ---- tables ----

test_that("cr_tables collects the tables of an experiment and a report", {
  exp <- .report_fixture()
  tabs <- cr_tables(exp)
  expect_type(tabs, "list")
  expect_true(all(c("design", "channels", "disposition") %in% names(tabs)))
  expect_true(all(vapply(tabs, is.data.frame, logical(1))))

  rep <- cr_report(exp, effects = .effects_fixture())
  rtabs <- cr_tables(rep)
  expect_true("effects" %in% names(rtabs))
  expect_equal(names(cr_tables(rep, which = "effects")), "effects")
})

test_that("cr_tables errors informatively on unknown selections", {
  exp <- .report_fixture()
  expect_error(cr_tables(exp, which = "nope"), "Unknown table")
  expect_error(cr_tables(42), "cr_report")
})

test_that("cr_table_qc normalises the shapes a QC record takes", {
  exp <- cr_filter_cells(.report_fixture(), area > 100)
  expect_equal(nrow(cr_table_qc(exp)), 1)
  expect_equal(nrow(cr_table_qc(cr_report(exp))), 1)

  gate <- list(units = data.frame(well = c("A01", "A02"),
                                  fails = c(TRUE, FALSE)))
  expect_equal(nrow(cr_table_qc(gate)), 2)

  parts <- list(a = data.frame(x = 1), b = data.frame(x = 2))
  stacked <- cr_table_qc(parts)
  expect_true("component" %in% names(stacked))
  expect_equal(nrow(stacked), 2)

  expect_equal(nrow(cr_table_qc(NULL)), 0)
  expect_error(cr_table_qc(42), "Cannot build a QC table")
})

# ---- exporters ----

test_that("cr_export_tables writes one CSV per table", {
  exp <- .report_fixture()
  tabs <- cr_tables(exp)
  dir <- withr::local_tempdir()
  paths <- cr_export_tables(tabs, file.path(dir, "tables"))
  expect_length(paths, length(tabs))
  expect_true(all(file.exists(paths)))
  expect_true(all(grepl("\\.csv$", paths)))
})

test_that("cr_export_tables writes one workbook per table set", {
  skip_if_not_installed("writexl")
  exp <- .report_fixture()
  tabs <- cr_tables(exp)
  dir <- withr::local_tempdir()
  one <- cr_export_tables(tabs, file.path(dir, "book"), format = "xlsx")
  expect_true(file.exists(one))
  expect_match(one, "\\.xlsx$")

  many <- cr_export_tables(tabs, file.path(dir, "sheets"), format = "xlsx",
                           one_file = FALSE)
  expect_length(many, length(tabs))
  expect_true(all(file.exists(many)))
})

test_that("cr_export_tables validates its inputs", {
  dir <- withr::local_tempdir()
  expect_error(cr_export_tables(list(), dir), "non-empty")
  expect_error(cr_export_tables(list(a = 1), dir), "data frame")
  expect_error(cr_export_tables(data.frame(x = 1), ""), "path")
})

test_that("cr_export_results accepts a cr_report", {
  exp <- .report_fixture()
  rep <- cr_report(exp, effects = .effects_fixture())
  f <- withr::local_tempfile(fileext = ".csv")
  cr_export_results(rep, f)
  expect_equal(nrow(readr::read_csv(f, show_col_types = FALSE)), 3)
})

test_that("cr_export_plots accepts a bare ggplot and sanitises names", {
  exp <- .report_fixture()
  p <- cr_plot_intensity(exp, "marker_1")
  dir <- withr::local_tempdir()
  one <- cr_export_plots(p, dir, width = 3, height = 2)
  expect_true(file.exists(one))

  named <- cr_export_plots(list(`marker 1/raw` = p), dir, width = 3, height = 2)
  expect_true(file.exists(named))
  expect_false(grepl("/raw", basename(named), fixed = TRUE))
  expect_error(cr_export_plots(list(), dir), "non-empty")
})

# ---- rendering guards ----

test_that("cr_render_report rejects objects that are not reports", {
  expect_error(cr_render_report(list(a = 1)), "cr_report")
})

test_that("cr_report renders only when a destination is given", {
  exp <- .report_fixture()
  expect_s3_class(cr_report(exp), "cr_report")
  dir <- withr::local_tempdir()
  expect_error(
    cr_report(exp, template = file.path(dir, "nope.Rmd")),
    "Template not found"
  )
})
