# The non-reactive helpers backing the Shiny application. Everything here
# is an ordinary function of ordinary data, so none of it needs a session.

# ---- table and placeholder wrappers -------------------------------------

test_that(".cr_dt wraps a data frame in a DT widget with the app defaults", {
  skip_if_not_installed("DT")
  w <- cellreportR:::.cr_dt(tibble::tibble(a = 1:3, b = letters[1:3]))
  expect_s3_class(w, "datatables")
  expect_false(attr(w$x, "rownames"))
  expect_true(w$x$options$scrollX)
  expect_equal(w$x$options$pageLength, 10L)
})

test_that(".cr_dt honours page length and editability", {
  skip_if_not_installed("DT")
  # DT only emits the `selection` element when the shiny namespace is
  # loaded, so the selection mode is asserted from inside a session in
  # test-shiny-server.R instead of here.
  w <- cellreportR:::.cr_dt(tibble::tibble(a = 1:2), page = 15L,
                            selection = "multiple", editable = "cell")
  expect_equal(w$x$options$pageLength, 15L)
  expect_equal(w$x$editable$target, "cell")
  plain <- cellreportR:::.cr_dt(tibble::tibble(a = 1:2))
  expect_false(isTRUE(plain$x$editable))
})

test_that(".cr_dt accepts a zero-row table", {
  skip_if_not_installed("DT")
  w <- cellreportR:::.cr_dt(tibble::tibble(unit = character(0)))
  expect_s3_class(w, "datatables")
})

test_that(".cr_app_blank_plot returns a ggplot carrying the message", {
  skip_if_not_installed("ggplot2")
  p <- cellreportR:::.cr_app_blank_plot("nothing here yet")
  expect_s3_class(p, "ggplot")
  expect_equal(p$layers[[1]]$aes_params$label, "nothing here yet")
})

test_that(".cr_app_example returns an experiment", {
  exp <- cellreportR:::.cr_app_example(seed = 1, n_cells_per_well = 4)
  expect_s3_class(exp, "cr_experiment")
  expect_gt(nrow(exp$cells), 0)
})

test_that(".cr_app_example falls back when the screen example fails", {
  local_mocked_bindings(cr_example_screen = function(...) stop("no screen"),
                        .package = "cellreportR")
  exp <- cellreportR:::.cr_app_example(seed = 1, n_cells_per_well = 4)
  expect_s3_class(exp, "cr_experiment")
})

# ---- reading uploads and directories ------------------------------------

test_that(".cr_app_read_one reads csv, tsv and rds", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  readr::write_csv(utils::head(cells, 20), file.path(dir, "a.csv"))
  readr::write_tsv(utils::head(cells, 10), file.path(dir, "b.tsv"))
  saveRDS(utils::head(cells, 5), file.path(dir, "c.rds"))
  expect_equal(nrow(cellreportR:::.cr_app_read_one(file.path(dir, "a.csv"))), 20)
  expect_equal(nrow(cellreportR:::.cr_app_read_one(file.path(dir, "b.tsv"))), 10)
  expect_equal(nrow(cellreportR:::.cr_app_read_one(file.path(dir, "c.rds"))), 5)
})

test_that(".cr_app_read_one takes the format from the label, not the path", {
  # An upload arrives under a temporary name with no extension at all; the
  # browser's label is the only record of the format.
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  src <- file.path(dir, "a.csv")
  readr::write_csv(utils::head(cells, 12), src)
  anon <- file.path(dir, "0abc1234")
  file.copy(src, anon)
  out <- cellreportR:::.cr_app_read_one(anon, label = "exported_cells.csv")
  expect_equal(nrow(out), 12)
  expect_s3_class(out, "tbl_df")
})

test_that(".cr_app_read_one reads Excel uploads", {
  skip_if_not_installed("writexl")
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  f <- file.path(dir, "e.xlsx")
  writexl::write_xlsx(as.data.frame(utils::head(cells, 7)), f)
  out <- cellreportR:::.cr_app_read_one(f)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 7)
})

test_that(".cr_app_read_files stacks uploads and keeps provenance", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  a <- file.path(dir, "a.csv")
  b <- file.path(dir, "b.tsv")
  readr::write_csv(utils::head(cells, 20), a)
  readr::write_tsv(utils::head(cells, 10), b)
  out <- cellreportR:::.cr_app_read_files(c(a, b))
  expect_equal(nrow(out), 30)
  expect_setequal(unique(out$source_file), c("a.csv", "b.tsv"))
  expect_true(all(c("source_file", "source_path") %in% names(out)))
  # Base names repeat across plates, so the identifier is rebuilt.
  expect_equal(anyDuplicated(out$cell_id), 0L)
})

test_that(".cr_app_read_files labels rows with the browser's file name", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  tmp <- file.path(dir, "0000upload")
  readr::write_csv(utils::head(cells, 6), tmp)
  out <- cellreportR:::.cr_app_read_files(tmp, labels = "plate_one.csv")
  expect_equal(unique(out$source_file), "plate_one.csv")
})

test_that(".cr_app_read_files rejects no files and mismatched labels", {
  expect_error(cellreportR:::.cr_app_read_files(character(0)),
               "No files to read")
  expect_error(
    cellreportR:::.cr_app_read_files(c("a.csv", "b.csv"), labels = "a.csv"),
    "as long as"
  )
})

test_that(".cr_app_read_dir reads a directory of exports", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  readr::write_csv(utils::head(cells, 20), file.path(dir, "a.csv"))
  readr::write_csv(utils::tail(cells, 15), file.path(dir, "b.csv"))
  out <- cellreportR:::.cr_app_read_dir(dir, pattern = "\\.csv$",
                                        recursive = FALSE)
  expect_s3_class(out, "tbl_df")
  expect_equal(nrow(out), 35)
  expect_true("cell_id" %in% names(out))
})

test_that(".cr_app_read_dir falls back to per-file reading", {
  # The package reader is allowed to reject a tree it does not recognise;
  # the app then reads each file in turn rather than giving up.
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  dir <- withr::local_tempdir()
  readr::write_csv(utils::head(cells, 9), file.path(dir, "a.csv"))
  local_mocked_bindings(
    cr_read_exports = function(...) stop("unsupported vendor layout"),
    .package = "cellreportR"
  )
  out <- cellreportR:::.cr_app_read_dir(dir, pattern = "\\.csv$",
                                        recursive = FALSE)
  expect_equal(nrow(out), 9)
})

test_that(".cr_app_read_dir errors when nothing matches the pattern", {
  dir <- withr::local_tempdir()
  expect_error(cellreportR:::.cr_app_read_dir(dir), "No files matching")
})

# ---- shaping the cells table --------------------------------------------

test_that(".cr_app_prepare_cells supplies a cell identifier", {
  out <- cellreportR:::.cr_app_prepare_cells(data.frame(a = 1:3))
  expect_equal(out$cell_id, c("c0000001", "c0000002", "c0000003"))
  expect_s3_class(out, "tbl_df")
})

test_that(".cr_app_prepare_cells rebuilds duplicated or missing identifiers", {
  dup <- cellreportR:::.cr_app_prepare_cells(
    data.frame(cell_id = c("a", "a", "b"), v = 1:3)
  )
  expect_equal(anyDuplicated(dup$cell_id), 0L)
  na <- cellreportR:::.cr_app_prepare_cells(
    data.frame(cell_id = c("a", NA, "b"), v = 1:3)
  )
  expect_false(anyNA(na$cell_id))
})

test_that(".cr_app_prepare_cells keeps identifiers that are already unique", {
  out <- cellreportR:::.cr_app_prepare_cells(
    data.frame(cell_id = c("x", "y"), v = 1:2)
  )
  expect_equal(out$cell_id, c("x", "y"))
})

test_that(".cr_app_prepare_cells handles a zero-row table", {
  out <- cellreportR:::.cr_app_prepare_cells(
    tibble::tibble(cell_id = character(0), v = numeric(0))
  )
  expect_equal(nrow(out), 0L)
})

test_that(".cr_app_unit_choices offers discrete columns, preferred first", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  choices <- cellreportR:::.cr_app_unit_choices(cells)
  expect_true("well" %in% choices)
  expect_false("cell_id" %in% choices)
  expect_equal(choices[[1L]], "well")
})

test_that(".cr_app_unit_choices returns nothing for empty input", {
  expect_length(cellreportR:::.cr_app_unit_choices(NULL), 0L)
  expect_length(cellreportR:::.cr_app_unit_choices(tibble::tibble()), 0L)
})

test_that(".cr_app_unit_choices skips constant and all-distinct columns", {
  cells <- tibble::tibble(
    cell_id = as.character(1:4),
    constant = "same",
    distinct = letters[1:4],
    unit = c("a", "a", "b", "b")
  )
  choices <- cellreportR:::.cr_app_unit_choices(cells)
  expect_equal(choices, "unit")
})

test_that(".cr_app_set_unit promotes a chosen column to `well`", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  cells$acquisition <- cells$well
  cells$well <- NULL
  out <- cellreportR:::.cr_app_set_unit(cells, "acquisition")
  expect_true("well" %in% names(out))
  expect_equal(out$well, as.character(cells$acquisition))
  # the original column stays in place
  expect_true("acquisition" %in% names(out))
})

test_that(".cr_app_set_unit only coerces an existing spatial unit", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  cells$well <- factor(cells$well)
  out <- cellreportR:::.cr_app_set_unit(cells, "well")
  expect_type(out$well, "character")
})

test_that(".cr_app_set_unit is a no-op for an absent or empty column", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  expect_identical(cellreportR:::.cr_app_set_unit(cells, "nope"), cells)
  expect_identical(cellreportR:::.cr_app_set_unit(cells, NULL), cells)
  expect_identical(cellreportR:::.cr_app_set_unit(cells, ""), cells)
})

test_that(".cr_app_design_skeleton gives one row per unit", {
  cells <- cr_example_experiment(seed = 3, n_cells_per_well = 4)$cells
  out <- cellreportR:::.cr_app_design_skeleton(cells)
  expect_equal(nrow(out), dplyr::n_distinct(cells$well))
  expect_equal(names(out)[1], "well")
  expect_setequal(
    names(out),
    c("well", "treatment", "dose", "dose_unit", "group", "replicate")
  )
  expect_true(all(out$treatment == "untreated"))
})

test_that(".cr_app_design_skeleton handles a single unit", {
  cells <- tibble::tibble(cell_id = as.character(1:3), well = "A01",
                          marker = 1:3)
  out <- cellreportR:::.cr_app_design_skeleton(cells)
  expect_equal(nrow(out), 1L)
  expect_equal(out$well, "A01")
})

test_that(".cr_app_design_skeleton errors without a spatial unit column", {
  expect_error(
    cellreportR:::.cr_app_design_skeleton(tibble::tibble(x = 1:3)),
    "no spatial unit column"
  )
})

# ---- reading an effect-size grid ----------------------------------------

test_that(".cr_app_effect_columns finds a wide grid's estimate and bounds", {
  exp <- cr_test_experiment(seed = 3, n_cells_per_well = 5)
  eff <- cr_effect_grid(exp, value = "marker_1", group_var = "treatment",
                        reference_level = "Untreated",
                        unit = exp$spatial_unit, methods = "cohens_d",
                        min_n = 3, test = "t")
  cols <- cellreportR:::.cr_app_effect_columns(eff, "cohens_d")
  expect_equal(cols$estimate, "cohens_d")
  expect_equal(cols$ci_low, "cohens_d_ci_low")
  expect_equal(cols$ci_high, "cohens_d_ci_high")
})

test_that(".cr_app_effect_columns accepts a long table", {
  long <- tibble::tibble(method = "cohens_d", estimate = 1, ci_low = 0,
                         ci_high = 2)
  cols <- cellreportR:::.cr_app_effect_columns(long, "cohens_d")
  expect_equal(cols$estimate, "estimate")
  expect_equal(cols$ci_low, "ci_low")
})

test_that(".cr_app_effect_columns reports missing bounds as NA", {
  bare <- tibble::tibble(cohens_d = c(1, 2), contrast = c("x", "y"))
  cols <- cellreportR:::.cr_app_effect_columns(bare, "cohens_d")
  expect_equal(cols$estimate, "cohens_d")
  expect_true(is.na(cols$ci_low))
  expect_true(is.na(cols$ci_high))
  # a method the table does not carry at all
  none <- cellreportR:::.cr_app_effect_columns(bare, "hedges_g")
  expect_true(is.na(none$estimate))
})

test_that(".cr_app_effect_methods lists what a grid actually carries", {
  exp <- cr_test_experiment(seed = 3, n_cells_per_well = 5)
  eff <- cr_effect_grid(exp, value = "marker_1", group_var = "treatment",
                        reference_level = "Untreated",
                        unit = exp$spatial_unit,
                        methods = c("cohens_d", "cliffs_delta"),
                        min_n = 3, test = "t")
  expect_setequal(cellreportR:::.cr_app_effect_methods(eff),
                  c("cohens_d", "cliffs_delta"))
})

test_that(".cr_app_effect_methods reads a long table's method column", {
  long <- tibble::tibble(method = c("a", "b", "a"), estimate = 1:3)
  expect_equal(cellreportR:::.cr_app_effect_methods(long), c("a", "b"))
})

test_that(".cr_app_effect_methods returns nothing for NULL", {
  expect_length(cellreportR:::.cr_app_effect_methods(NULL), 0L)
})

test_that(".cr_app_effect_label picks the contrast column", {
  expect_equal(
    cellreportR:::.cr_app_effect_label(
      tibble::tibble(contrast = "a", treatment = "b")
    ),
    "contrast"
  )
  expect_equal(
    cellreportR:::.cr_app_effect_label(tibble::tibble(treatment = "b")),
    "treatment"
  )
})

test_that(".cr_app_effect_label is NA when no label column exists", {
  expect_true(is.na(cellreportR:::.cr_app_effect_label(tibble::tibble(a = 1))))
})
