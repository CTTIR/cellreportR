# The assembly helpers behind cr_report()/cr_tables() and the branches of
# cr_render_report() that the round-trip tests never reach.

# ---- argument coercion --------------------------------------------------

test_that(".cr_as_results names a single result after its treatment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  out <- cellreportR:::.cr_as_results(res)
  expect_type(out, "list")
  expect_named(out, "CompoundA_high")
  expect_s3_class(out[[1]], "cr_result")
})

test_that(".cr_as_results passes lists and data frames through", {
  expect_equal(cellreportR:::.cr_as_results(NULL), list())
  df <- tibble::tibble(a = 1:2)
  expect_identical(cellreportR:::.cr_as_results(df), df)
  lst <- list(x = 1, y = 2)
  expect_identical(cellreportR:::.cr_as_results(lst), lst)
})

test_that(".cr_as_results rejects anything else", {
  expect_error(cellreportR:::.cr_as_results(42), "must be a")
  expect_error(cellreportR:::.cr_as_results("nope"), "must be a")
})

test_that(".cr_as_table coerces frames and single-frame lists", {
  df <- data.frame(a = 1:2)
  expect_s3_class(cellreportR:::.cr_as_table(df, "effects"), "tbl_df")
  expect_null(cellreportR:::.cr_as_table(NULL, "effects"))
  one <- cellreportR:::.cr_as_table(list(only = df), "effects")
  expect_equal(nrow(one), 2L)
})

test_that(".cr_as_table stacks several frames under a component column", {
  out <- cellreportR:::.cr_as_table(
    list(first = data.frame(a = 1), second = data.frame(a = 2)),
    "effects"
  )
  expect_equal(nrow(out), 2L)
  expect_true("component" %in% names(out))
  expect_equal(out$component, c("first", "second"))
})

test_that(".cr_as_table rejects input holding no frame at all", {
  expect_error(cellreportR:::.cr_as_table(list(1, 2), "effects"),
               "must be a data frame")
  expect_error(cellreportR:::.cr_as_table(42, "sizes"), "must be a data frame")
})

test_that(".cr_as_named_list names unnamed elements positionally", {
  out <- cellreportR:::.cr_as_named_list(list(1, 2), "plots")
  expect_named(out, c("plots_1", "plots_2"))
  half <- cellreportR:::.cr_as_named_list(list(a = 1, 2), "plots")
  expect_named(half, c("a", "plots_2"))
})

test_that(".cr_as_named_list makes duplicated names unique", {
  out <- cellreportR:::.cr_as_named_list(list(a = 1, a = 2), "tables")
  expect_equal(anyDuplicated(names(out)), 0L)
})

test_that(".cr_as_named_list rejects a non-list", {
  expect_equal(cellreportR:::.cr_as_named_list(NULL, "plots"), list())
  expect_error(cellreportR:::.cr_as_named_list(data.frame(a = 1), "plots"),
               "must be a named list")
  expect_error(cellreportR:::.cr_as_named_list(1:3, "plots"),
               "must be a named list")
})

# ---- stacking result slots ----------------------------------------------

test_that(".cr_bind_slot stacks a slot across results and labels the rows", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  results <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  out <- cellreportR:::.cr_bind_slot(results, "effect_sizes")
  expect_s3_class(out, "data.frame")
  expect_true("comparison" %in% names(out))
  expect_setequal(unique(out$comparison),
                  setdiff(unique(exp$design$treatment), "Untreated"))
  expect_equal(nrow(out),
               sum(vapply(results, function(r) nrow(r$effect_sizes),
                          integer(1))))
})

test_that(".cr_bind_slot skips entries that are not results", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  out <- cellreportR:::.cr_bind_slot(list(res, "not a result", 42),
                                     "effect_sizes")
  expect_equal(nrow(out), nrow(res$effect_sizes))
})

test_that(".cr_bind_slot returns NULL when nothing is left to stack", {
  expect_null(cellreportR:::.cr_bind_slot(list(), "effect_sizes"))
  expect_null(cellreportR:::.cr_bind_slot(list("a", 1), "effect_sizes"))
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  # a slot that is empty in every result
  res$effect_sizes <- res$effect_sizes[0, , drop = FALSE]
  expect_null(cellreportR:::.cr_bind_slot(list(res), "effect_sizes"))
  # a slot that does not exist at all
  expect_null(cellreportR:::.cr_bind_slot(list(res), "not_a_slot"))
})

test_that("cr_tables reaches .cr_bind_slot through a report", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  results <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  rep <- cr_report(exp, results = results, render = FALSE)
  tbls <- cr_tables(rep)
  expect_true("effect_sizes" %in% names(tbls))
  expect_true("comparison" %in% names(tbls$effect_sizes))
})

# ---- template parameters ------------------------------------------------

test_that(".cr_declared_params reads the bundled template", {
  template <- system.file("rmd", "cellreportR_report.Rmd",
                          package = "cellreportR")
  skip_if(!nzchar(template), "bundled template not installed")
  skip_if_not_installed("knitr")
  out <- cellreportR:::.cr_declared_params(template)
  expect_true(all(c("experiment", "results", "title", "author") %in% out))
})

test_that(".cr_declared_params reads a template's own parameters", {
  skip_if_not_installed("knitr")
  f <- withr::local_tempfile(fileext = ".Rmd")
  writeLines(c("---", "title: t", "params:", "  title: \"x\"",
               "  author: \"y\"", "---", "", "body"), f)
  expect_setequal(cellreportR:::.cr_declared_params(f), c("title", "author"))
})

test_that(".cr_declared_params falls back for a template with no params", {
  f <- withr::local_tempfile(fileext = ".Rmd")
  writeLines(c("---", "title: t", "---", "", "body"), f)
  expect_equal(cellreportR:::.cr_declared_params(f),
               c("experiment", "results", "title", "author"))
})

test_that(".cr_declared_params falls back when the front matter is broken", {
  f <- withr::local_tempfile(fileext = ".Rmd")
  writeLines(c("---", "params:", "  - this: [is", "---", "body"), f)
  expect_equal(cellreportR:::.cr_declared_params(f),
               c("experiment", "results", "title", "author"))
})

test_that(".cr_pkg_version reports a version string", {
  v <- cellreportR:::.cr_pkg_version()
  expect_type(v, "character")
  expect_length(v, 1L)
})

# ---- assembly -----------------------------------------------------------

test_that("cr_report keeps absent slots as documented NULLs", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  rep <- cr_report(exp, render = FALSE)
  for (slot in c("qc", "effects", "sizes", "tables")) {
    expect_true(slot %in% names(rep))
  }
  expect_null(rep$effects)
  expect_null(rep$sizes)
  expect_true("disposition" %in% names(rep$tables))
})

test_that("cr_report keeps a caller-supplied disposition table", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  mine <- tibble::tibble(note = "mine")
  rep <- cr_report(exp, tables = list(disposition = mine), render = FALSE)
  expect_identical(rep$tables$disposition, mine)
})

test_that("cr_report rejects a non-logical render argument", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_error(cr_report(exp, render = "yes"), "must be")
  expect_error(cr_report(exp, render = NA), "must be")
  expect_error(cr_report(exp, render = c(TRUE, FALSE)), "must be")
})

test_that(".cr_report_summary joins sample sizes on shared key columns", {
  effects <- tibble::tibble(group = c("a", "b"), estimate = c(1, 2))
  sizes <- tibble::tibble(group = c("a", "b"), n_per_group = c(10, 20))
  out <- cellreportR:::.cr_report_summary(list(), effects, sizes)
  expect_equal(out$n_per_group, c(10, 20))
})

test_that(".cr_report_summary binds sizes columnwise without a shared key", {
  effects <- tibble::tibble(estimate = c(1, 2))
  sizes <- tibble::tibble(n_per_group = c(10, 20))
  out <- cellreportR:::.cr_report_summary(list(), effects, sizes)
  expect_equal(out$n_per_group, c(10, 20))
})

test_that(".cr_report_summary returns an empty tibble with nothing to show", {
  out <- cellreportR:::.cr_report_summary(list(), NULL, NULL)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
})

test_that(".cr_report_summary summarises results without a summary attribute", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  out <- cellreportR:::.cr_report_summary(list(CompoundA_high = res))
  expect_equal(nrow(out), 1L)
  expect_equal(out$treatment, "CompoundA_high")
  expect_true(is.numeric(out$p_value))
})

test_that(".cr_results_summary drops entries that are not results", {
  out <- cellreportR:::.cr_results_summary(list("nope", 42))
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 0L)
})

# ---- rendering ----------------------------------------------------------

test_that("cr_render_report rejects anything that is not a report", {
  expect_error(cr_render_report(list(a = 1)), "must be a")
  expect_error(cr_render_report(42), "must be a")
})

test_that("report formats include HTML, PDF and Word", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 4)
  expect_identical(cr_report(exp, format = "html")$params$format, "html")
  expect_identical(cr_report(exp, format = "pdf")$params$format, "pdf")
  expect_identical(cr_report(exp, format = "docx")$params$format, "docx")
  expect_error(cr_report(exp, format = "odt"), "arg")
})

test_that("cr_render_report errors on a template that does not exist", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  rep <- cr_report(exp, render = FALSE)
  dir <- withr::local_tempdir()
  expect_error(
    cr_render_report(rep, output_dir = dir,
                     template = file.path(dir, "absent.Rmd")),
    "Template not found"
  )
})

test_that("cr_render_report needs rmarkdown and knitr", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  rep <- cr_report(exp, render = FALSE)
  local_mocked_bindings(requireNamespace = function(...) FALSE,
                        .package = "base")
  expect_error(cr_render_report(rep), "rmarkdown")
})

test_that("cr_render_report assembles a report from a bare experiment", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  dir <- file.path(withr::local_tempdir(), "created", "on", "demand")
  out <- suppressMessages(cr_render_report(exp, output_dir = dir))
  expect_true(file.exists(out))
  expect_true(dir.exists(dir))
})

test_that("cr_render_report passes only the parameters a template declares", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  dir <- withr::local_tempdir()
  template <- file.path(dir, "minimal.Rmd")
  writeLines(c(
    "---",
    "title: \"`r params$title`\"",
    "output: html_document",
    "params:",
    "  title: \"placeholder\"",
    "  author: \"\"",
    "---",
    "",
    "Author: `r params$author`"
  ), template)
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  rep <- cr_report(exp, title = "stored title", author = "stored author",
                   render = FALSE)
  out <- suppressMessages(
    cr_render_report(rep, output_dir = dir, template = template,
                     title = "overridden", author = "override author")
  )
  expect_true(file.exists(out))
  html <- paste(readLines(out, warn = FALSE), collapse = "\n")
  expect_match(html, "overridden")
  expect_match(html, "override author")
  expect_false(grepl("stored title", html))
})

test_that("cr_report renders in place when an output directory is given", {
  skip_on_cran()
  skip_if_not_installed("rmarkdown")
  skip_if_not_installed("knitr")
  skip_if_not(rmarkdown::pandoc_available(), "pandoc is not available")
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 8)
  dir <- withr::local_tempdir()
  out <- suppressMessages(cr_report(exp, output_dir = dir))
  expect_true(file.exists(out))
  # the assembled object travels with the path
  expect_s3_class(attr(out, "report"), "cr_report")
})
