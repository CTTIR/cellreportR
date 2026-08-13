# Small internals whose branches the round-trip tests only ever take one
# side of: argument validators, label pickers, seed bookkeeping and the
# dispatch helpers behind the plotting wrappers.

# ---- argument validators ------------------------------------------------

test_that(".cr_arg_string accepts one non-empty string and nothing else", {
  expect_invisible(cellreportR:::.cr_arg_string("ok"))
  for (bad in list(1L, NA_character_, "", c("a", "b"), character(0), NULL)) {
    expect_error(cellreportR:::.cr_arg_string(bad),
                 "single non-empty string")
  }
})

test_that(".cr_arg_string names the argument it was checking", {
  f <- function(pattern) cellreportR:::.cr_arg_string(pattern)
  expect_error(f(1), "pattern")
})

test_that(".cr_arg_flag accepts one non-missing logical and nothing else", {
  expect_invisible(cellreportR:::.cr_arg_flag(TRUE))
  expect_invisible(cellreportR:::.cr_arg_flag(FALSE))
  for (bad in list(NA, 1, "TRUE", c(TRUE, FALSE), logical(0))) {
    expect_error(cellreportR:::.cr_arg_flag(bad), "must be")
  }
})

test_that("the readers pass their arguments through the validators", {
  dir <- withr::local_tempdir()
  expect_error(cr_read_exports(dir, pattern = 1), "pattern")
  expect_error(cr_read_exports(dir, recursive = NA), "recursive")
  expect_error(cr_read_exports(dir, progress = "yes"), "progress")
  expect_error(cr_read_exports(file.path(dir, "absent")), "")
})

test_that(".cr_path_ext lowercases and tolerates a missing extension", {
  expect_equal(cellreportR:::.cr_path_ext("a/b/C.CSV"), "csv")
  expect_equal(cellreportR:::.cr_path_ext("a/b/c.xlsx"), "xlsx")
  expect_equal(cellreportR:::.cr_path_ext("a/b/noext"), "")
})

test_that(".cr_read_table dispatches on the file extension", {
  cells <- cr_example_experiment(seed = 1, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  readr::write_csv(utils::head(cells, 6), file.path(dir, "a.csv"))
  readr::write_tsv(utils::head(cells, 5), file.path(dir, "b.tsv"))
  readr::write_tsv(utils::head(cells, 4), file.path(dir, "c.txt"))
  expect_equal(nrow(cellreportR:::.cr_read_table(file.path(dir, "a.csv"))), 6L)
  expect_equal(nrow(cellreportR:::.cr_read_table(file.path(dir, "b.tsv"))), 5L)
  expect_equal(nrow(cellreportR:::.cr_read_table(file.path(dir, "c.txt"))), 4L)
})

# ---- relative path components -------------------------------------------

test_that(".cr_rel_parts returns the directories between root and file", {
  root <- withr::local_tempdir()
  deep <- file.path(root, "run1", "compound", "plate.csv")
  dir.create(dirname(deep), recursive = TRUE)
  file.create(deep)
  expect_equal(cellreportR:::.cr_rel_parts(deep, root)[[1L]],
               c("run1", "compound"))
})

test_that(".cr_rel_parts returns nothing for a file sitting at the root", {
  root <- withr::local_tempdir()
  f <- file.path(root, "plate.csv")
  file.create(f)
  expect_length(cellreportR:::.cr_rel_parts(f, root)[[1L]], 0L)
})

test_that(".cr_rel_parts re-anchors on the root's own name", {
  # A path recorded before the tree was moved no longer starts with the
  # root, but the root's base name still appears inside it.
  parts <- cellreportR:::.cr_rel_parts(
    "/elsewhere/study/run1/compound/plate.csv", "/somewhere/study"
  )
  expect_equal(parts[[1L]], c("run1", "compound"))
})

test_that(".cr_rel_parts falls back to the bare file name", {
  parts <- cellreportR:::.cr_rel_parts("/nothing/in/common/plate.csv",
                                       "/a/different/root")
  expect_length(parts[[1L]], 0L)
})

# ---- effect-size magnitude ----------------------------------------------

test_that(".cr_gate_magnitude bands an effect size", {
  expect_equal(cellreportR:::.cr_gate_magnitude(0.1), "negligible")
  expect_equal(cellreportR:::.cr_gate_magnitude(-0.1), "negligible")
  expect_equal(cellreportR:::.cr_gate_magnitude(0.3), "small")
  expect_equal(cellreportR:::.cr_gate_magnitude(0.6), "medium")
  expect_equal(cellreportR:::.cr_gate_magnitude(-1.2), "large")
})

test_that(".cr_gate_magnitude is NA where there is no estimate", {
  expect_true(is.na(cellreportR:::.cr_gate_magnitude(numeric(0))))
  expect_true(is.na(cellreportR:::.cr_gate_magnitude(NA_real_)))
  expect_true(is.na(cellreportR:::.cr_gate_magnitude(Inf)))
})

# ---- pooled spread and seed bookkeeping ---------------------------------

test_that(".cr_pooled_sd needs two observations in each group", {
  expect_true(is.na(cellreportR:::.cr_pooled_sd(1, c(1, 2, 3))))
  expect_true(is.na(cellreportR:::.cr_pooled_sd(c(1, 2, 3), 2)))
  expect_true(is.na(cellreportR:::.cr_pooled_sd(numeric(0), c(1, 2))))
})

test_that(".cr_pooled_sd equals the classical pooled estimate", {
  x <- c(1, 2, 3, 4)
  y <- c(2, 4, 6, 8)
  n1 <- length(x)
  n2 <- length(y)
  expected <- sqrt(((n1 - 1) * var(x) + (n2 - 1) * var(y)) / (n1 + n2 - 2))
  expect_equal(cellreportR:::.cr_pooled_sd(x, y), expected)
})

test_that("the seed is captured and restored around a bootstrap", {
  set.seed(42)
  before <- get(".Random.seed", envir = globalenv())
  captured <- cellreportR:::.cr_capture_seed()
  expect_identical(captured, before)
  runif(5)
  cellreportR:::.cr_restore_seed(captured)
  expect_identical(get(".Random.seed", envir = globalenv()), before)
})

test_that("an absent seed is captured as NULL and restored by removal", {
  # A fresh session has no .Random.seed until a random number is drawn;
  # the bootstrap must leave it that way.
  withr::local_seed(NULL)
  suppressWarnings(rm(".Random.seed", envir = globalenv()))
  expect_null(cellreportR:::.cr_capture_seed())
  runif(1)
  expect_true(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
  cellreportR:::.cr_restore_seed(NULL)
  expect_false(exists(".Random.seed", envir = globalenv(), inherits = FALSE))
})

# ---- comparison levels --------------------------------------------------

test_that(".cr_comparison_levels honours an explicit list", {
  expect_equal(
    cellreportR:::.cr_comparison_levels(c("a", "b", "c"), "a", c("b")),
    "b"
  )
})

test_that(".cr_comparison_levels drops the reference from a factor's levels", {
  g <- factor(c("ctrl", "hi"), levels = c("ctrl", "lo", "hi"))
  expect_equal(cellreportR:::.cr_comparison_levels(g, "ctrl", NULL),
               c("lo", "hi"))
})

test_that(".cr_comparison_levels drops the reference from a character vector", {
  g <- c("ctrl", "hi", "hi", "lo")
  expect_setequal(cellreportR:::.cr_comparison_levels(g, "ctrl", NULL),
                  c("hi", "lo"))
})

# ---- macro formatting ---------------------------------------------------

test_that(".cr_macro_scalar formats numbers, flags and strings for JSON", {
  expect_equal(cellreportR:::.cr_macro_scalar(1.23456, 2), "1.23")
  expect_equal(cellreportR:::.cr_macro_scalar(1e-8, 3), "0")
  expect_equal(cellreportR:::.cr_macro_scalar(TRUE, 2), "true")
  expect_equal(cellreportR:::.cr_macro_scalar(FALSE, 2), "false")
  expect_equal(cellreportR:::.cr_macro_scalar("plain", 2), "\"plain\"")
})

test_that(".cr_macro_scalar writes a non-finite number as null", {
  expect_equal(cellreportR:::.cr_macro_scalar(NA_real_, 2), "null")
  expect_equal(cellreportR:::.cr_macro_scalar(Inf, 2), "null")
  expect_equal(cellreportR:::.cr_macro_scalar(NaN, 2), "null")
})

test_that(".cr_macro_scalar escapes embedded quotes", {
  expect_equal(cellreportR:::.cr_macro_scalar("say \"hi\"", 2),
               "\"say \\\"hi\\\"\"")
})

test_that(".cr_label_cols prefers the naming columns, in order", {
  expect_equal(
    cellreportR:::.cr_label_cols(
      tibble::tibble(group = "a", treatment = "b", level = "c")
    ),
    c("group", "level")
  )
  expect_equal(
    cellreportR:::.cr_label_cols(tibble::tibble(term = "a", contrast = "b")),
    c("term", "contrast")
  )
})

test_that(".cr_label_cols falls back to the first character column", {
  expect_equal(
    cellreportR:::.cr_label_cols(tibble::tibble(n = 1, label = "x", z = "y")),
    "label"
  )
})

test_that(".cr_label_cols returns nothing when no column can label a row", {
  expect_length(cellreportR:::.cr_label_cols(tibble::tibble(a = 1, b = 2)), 0L)
})

# ---- plotting dispatch --------------------------------------------------

test_that(".cr_fc_dataframe accepts each shape cr_plot_foldchange takes", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  df <- tibble::tibble(treatment = "x", median_log2_fc = 1)
  expect_identical(cellreportR:::.cr_fc_dataframe(df), df)
  expect_identical(cellreportR:::.cr_fc_dataframe(res), res$fold_change)
  # a bare list of results, with no summary attribute to short-circuit on
  bare <- list(a = res)
  attr(bare, "summary") <- NULL
  expect_gt(nrow(cellreportR:::.cr_fc_dataframe(bare)), 0)
})

test_that(".cr_fc_dataframe reads the summary attribute of cr_test_all", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  all_res <- cr_test_all(exp, "marker_1", "Untreated", level = "replicate")
  skip_if(is.null(attr(all_res, "summary")$log2_fc),
          "cr_test_all did not attach a fold-change summary")
  out <- cellreportR:::.cr_fc_dataframe(all_res)
  expect_true(all(c("treatment", "median_log2_fc") %in% names(out)))
})

test_that(".cr_fc_dataframe rejects an unsupported type", {
  expect_error(cellreportR:::.cr_fc_dataframe(42), "Unsupported result type")
})

test_that(".cr_effect_sizes_df accepts each shape it is documented for", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 12)
  res <- cr_test(exp, "marker_1", "CompoundA_high", "Untreated",
                 level = "replicate")
  from_result <- cellreportR:::.cr_effect_sizes_df(res, "cohens_d")
  expect_equal(nrow(from_result), 1L)
  expect_equal(from_result$treatment, "CompoundA_high")
  from_df <- cellreportR:::.cr_effect_sizes_df(res$effect_sizes, "cohens_d")
  expect_equal(nrow(from_df), 1L)
  from_list <- cellreportR:::.cr_effect_sizes_df(list(a = res), "cohens_d")
  expect_equal(nrow(from_list), 1L)
})

test_that(".cr_effect_sizes_df rejects an unsupported type", {
  expect_error(cellreportR:::.cr_effect_sizes_df(42, "cohens_d"),
               "Unsupported input")
})

# ---- theme and toggle ---------------------------------------------------

test_that(".cr_app_theme builds a light and a dark bslib theme", {
  skip_if_not_installed("bslib")
  light <- cellreportR:::.cr_app_theme(dark = FALSE)
  dark <- cellreportR:::.cr_app_theme(dark = TRUE)
  expect_s3_class(light, "bs_theme")
  expect_s3_class(dark, "bs_theme")
  expect_false(identical(light, dark))
})

test_that(".cr_dark_toggle returns a control when bslib provides one", {
  skip_if_not_installed("bslib")
  skip_if_not("input_dark_mode" %in% getNamespaceExports("bslib"),
              "this bslib has no dark-mode control")
  expect_false(is.null(cellreportR:::.cr_dark_toggle()))
})

test_that(".cr_dark_toggle is absent on a bslib that has no dark mode", {
  local_mocked_bindings(getNamespaceExports = function(...) character(0),
                        .package = "base")
  expect_null(cellreportR:::.cr_dark_toggle())
})

test_that(".cr_app_resources registers the www directory when it exists", {
  skip_if_not_installed("shiny")
  dir <- system.file("shiny", "cellreportR", "www", package = "cellreportR")
  if (nzchar(dir) && dir.exists(dir)) {
    expect_true(cellreportR:::.cr_app_resources())
  } else {
    expect_false(cellreportR:::.cr_app_resources())
  }
})

test_that(".cr_app_resources reports a missing www directory", {
  # The package can be loaded from source with no inst/ alongside it; the
  # user interface then has to stay usable, only unstyled. `system.file()`
  # itself is shimmed by pkgload under load_all(), so the absence is
  # staged through dir.exists() instead.
  skip_if_not_installed("shiny")
  local_mocked_bindings(dir.exists = function(...) FALSE, .package = "base")
  expect_false(cellreportR:::.cr_app_resources())
})
