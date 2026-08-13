# Tests for R/example-data.R and R/example-screen.R: the synthetic data
# every example, test and vignette in the package runs on.

# ---- cr_example_experiment -------------------------------------------------

test_that("cr_example_experiment produces a valid experiment", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
  expect_s3_class(exp, "cr_experiment")
  expect_true(cr_validate_experiment(exp))
  expect_gt(nrow(exp$cells), 100)
  expect_equal(length(unique(exp$design$treatment)), 6)
  expect_true(all(c("DAPI", "marker_1") %in% cr_channels(exp)))
})

test_that("cr_example_experiment carries batch structure", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  expect_equal(exp$batch_vars, c("plate", "interval"))
  expect_setequal(unique(exp$design$plate), c("Plate_1", "Plate_2"))
  expect_setequal(unique(exp$design$interval), c("15min", "60min"))
  # Every batch holds untreated units to standardise against.
  ctrl <- exp$design[exp$design$treatment == "Untreated", ]
  expect_equal(nrow(unique(ctrl[, c("plate", "interval")])), 4L)
})

test_that("cr_example_experiment is reproducible and leaves the RNG alone", {
  a <- cr_example_experiment(seed = 7, n_cells_per_well = 10)
  b <- cr_example_experiment(seed = 7, n_cells_per_well = 10)
  expect_equal(a$cells$marker_1, b$cells$marker_1)

  set.seed(99)
  expected <- stats::runif(1)
  set.seed(99)
  invisible(cr_example_experiment(seed = 3, n_cells_per_well = 10))
  expect_equal(stats::runif(1), expected)
})

test_that("cr_example_experiment accepts a NULL seed", {
  set.seed(11)
  exp <- cr_example_experiment(seed = NULL, n_cells_per_well = 10)
  expect_s3_class(exp, "cr_experiment")
})

# ---- cr_example_design -----------------------------------------------------

test_that("cr_example_design generates 96-well layout", {
  d <- cr_example_design(96)
  expect_equal(nrow(d), 96)
  expect_true(all(c("well", "treatment", "dose", "plate", "interval") %in%
                    names(d)))
  expect_length(unique(d$dose), 4L)
  expect_false(anyDuplicated(d$well) > 0)
})

test_that("cr_example_design supports 384-well layout", {
  d <- cr_example_design(384, n_wells_per_replicate = 8)
  expect_equal(nrow(d), 6 * 4 * 8)
  expect_true(all(c("well", "treatment", "dose") %in% names(d)))
})

test_that("cr_example_design rejects unsupported formats", {
  expect_error(cr_example_design(42), "96 and 384")
  expect_error(cr_example_design(96, n_wells_per_replicate = 12),
               "plate only has")
})

# ---- cr_example_files / cr_example_path ------------------------------------

test_that("cr_example_files writes expected files", {
  dir <- withr::local_tempdir()
  files <- cr_example_files(dir, seed = 1)
  expect_gte(length(files), 3)
  expect_true(all(file.exists(files)))
  expect_true(any(grepl("cellprofiler", files)))
  expect_true(any(grepl("qupath", files)))
})

test_that("cr_example_files creates a missing directory", {
  dir <- file.path(withr::local_tempdir(), "nested", "deeper")
  files <- cr_example_files(dir, seed = 1)
  expect_true(all(file.exists(files)))
})

test_that("cr_example_path resolves the shipped fixtures", {
  all_files <- cr_example_path()
  expect_true(all(file.exists(all_files)))
  expect_setequal(basename(all_files),
                  c("example-export.csv", "example-export.xlsx",
                    "example-design.csv"))
})

test_that("cr_example_path reads back through the importers", {
  cells <- cr_read_export(cr_example_path("example-export.csv"))
  expect_s3_class(cells, "tbl_df")
  expect_equal(nrow(cells), 20L)
  # The trailing all-blank row instruments write is dropped, not carried.
  expect_false(any(is.na(cells[["Event Label"]])))
  expect_true(all(c("source_file", "source_path") %in% names(cells)))

  xlsx <- cr_read_export(cr_example_path("example-export.xlsx"))
  expect_equal(nrow(xlsx), 20L)

  design <- cr_read_design(cr_example_path("example-design.csv"))
  expect_true(all(c("well_id", "treatment", "compound") %in% names(design)))
})

test_that("cr_example_path validates its argument", {
  expect_error(cr_example_path("nope.csv"), "No example file")
  expect_error(cr_example_path(c("a", "b")), "single file name")
})

# ---- cr_example_screen -----------------------------------------------------

test_that("cr_example_screen builds a valid screen", {
  screen <- cr_example_screen(seed = 1, n_compounds = 3,
                              n_cells_per_well = 10)
  expect_s3_class(screen, "cr_experiment")
  expect_true(cr_validate_experiment(screen))
  expect_equal(screen$unit_var, "well_id")
  expect_equal(screen$batch_vars,
               c("compound", "experiment", "plate", "interval"))
  expect_setequal(unique(screen$design$compound),
                  c("CompoundA", "CompoundB", "CompoundC"))
  expect_setequal(unique(screen$design$interval), c("15min", "60min"))
  expect_length(unique(screen$design$dose), 4L)
  expect_setequal(cr_channels(screen),
                  c("nuclear_signal", "target_signal"))
  expect_true(all(c("area", "circularity", "source_file", "source_path") %in%
                    names(screen$cells)))
})

test_that("cr_example_screen puts a control in every batch", {
  screen <- cr_example_screen(seed = 1, n_compounds = 2,
                              n_cells_per_well = 10)
  bv <- screen$batch_vars
  batches <- unique(screen$design[, bv])
  ctrl <- unique(screen$design[screen$design$treatment == "Vehicle", bv])
  expect_equal(nrow(ctrl), nrow(batches))
})

test_that("cr_example_screen plants the multi-file units", {
  screen <- cr_example_screen(seed = 1, n_compounds = 2,
                              n_cells_per_well = 12)
  prov <- screen$provenance
  expect_true(all(c("source_file", "well_id", "n_files") %in% names(prov)))
  expect_equal(sum(prov$merge_unit), 1L)
  expect_equal(sum(prov$reacquisition), 1L)
  expect_length(unique(prov$well_id[prov$n_files > 1L]), 2L)
  # A look-alike suffix that must stay a unit of its own.
  expect_true(any(grepl("_2\\.2\\.csv$", prov$source_file)))
  expect_equal(sum(prov$n_cells), nrow(screen$cells))
})

test_that("cr_example_screen plants a gate failure", {
  screen <- cr_example_screen(seed = 1, n_compounds = 2,
                              n_cells_per_well = 30)
  d <- screen$design
  failing <- d$well_id[d$compound == "CompoundA" & d$experiment == "Exp_1" &
                         d$interval == "60min" & d$dose == 250 &
                         d$replicate == 1]
  batch <- d$well_id[d$compound == "CompoundA" & d$experiment == "Exp_1" &
                       d$interval == "60min" & d$treatment == "Vehicle" &
                       d$plate == d$plate[d$well_id == failing][1]]
  med <- function(ids) {
    stats::median(screen$cells$target_signal[screen$cells$well_id %in% ids])
  }
  expect_lt(med(failing), med(batch))
})

test_that("cr_example_screen sets the specificity arm aside", {
  screen <- cr_example_screen(seed = 1, n_compounds = 2,
                              n_cells_per_well = 10)
  aside <- screen$set_aside$reagent_omitted
  expect_s3_class(aside, "tbl_df")
  expect_true(all(c("arm", "target_signal", "well_id") %in% names(aside)))
  expect_length(unique(aside$arm), 2L)
  # None of the set-aside units leaks into the analysis pool.
  expect_length(intersect(aside$well_id, screen$cells$well_id), 0L)
  # Reagent omitted means background only.
  expect_lt(stats::median(aside$target_signal),
            stats::median(screen$cells$target_signal))
})

test_that("cr_example_screen is reproducible and leaves the RNG alone", {
  a <- cr_example_screen(seed = 5, n_compounds = 2, n_cells_per_well = 10)
  b <- cr_example_screen(seed = 5, n_compounds = 2, n_cells_per_well = 10)
  expect_equal(a$cells$target_signal, b$cells$target_signal)

  set.seed(4)
  expected <- stats::runif(1)
  set.seed(4)
  invisible(cr_example_screen(seed = 6, n_compounds = 2,
                              n_cells_per_well = 10))
  expect_equal(stats::runif(1), expected)
})

test_that("cr_example_screen validates its arguments", {
  expect_error(cr_example_screen(n_compounds = 0), "whole number")
  expect_error(cr_example_screen(n_compounds = 11), "whole number")
  expect_error(cr_example_screen(n_experiments = 3), "whole number")
  expect_error(cr_example_screen(n_cells_per_well = 2.5), "whole number")
})

test_that("cr_example_screen feeds the batch standardisation", {
  screen <- cr_example_screen(seed = 2, n_compounds = 2,
                              n_cells_per_well = 15)
  ref <- cr_batch_reference(screen, "target_signal", "Vehicle",
                            screen$batch_vars)
  expect_true(all(ref$has_control))
  expect_true(all(ref$ctrl_n > 0))
})

# ---- cr_example_exports ----------------------------------------------------

test_that("cr_example_exports writes a nested export tree", {
  dir <- withr::local_tempdir()
  files <- cr_example_exports(dir, seed = 1, n_cells = 4)
  expect_length(files, 10L)
  expect_true(all(file.exists(files)))
  # Design facts live in the path, not inside the file.
  rel <- sub(paste0("^", dir, .Platform$file.sep), "", files)
  expect_true(all(grepl("^Run1", rel)))
  expect_true(any(grepl("Plate_1 \\(partial\\)", rel)))
  # Markers that change the analysis.
  expect_true(any(grepl("\\(split\\)", basename(files))))
  expect_true(any(grepl("\\(repeat\\)", basename(files))))
  expect_true(any(grepl("\\(no reagent\\)", basename(files))))
  # A vehicle control is a name without an exposure token.
  expect_true(any(grepl("vehicle", basename(files))))
})

test_that("cr_example_exports round-trips through the ingest functions", {
  dir <- withr::local_tempdir()
  cr_example_exports(dir, seed = 1, n_cells = 4)
  map <- cr_column_map(
    exact = c("Event Label" = "cell_id",
              "Target - Signal Mean" = "target_signal"),
    prefix = c("^Nuclei - Area" = "area")
  )
  cells <- cr_read_exports(dir, column_map = map, progress = FALSE)
  expect_s3_class(cells, "tbl_df")
  expect_equal(nrow(cells), 40L)
  expect_true(all(c("source_file", "source_path", "cell_id", "target_signal",
                    "area") %in% names(cells)))
  expect_false(anyNA(cells$cell_id))
  expect_length(unique(cells$source_path), 10L)
})

test_that("cr_example_exports can write workbooks", {
  skip_if_not_installed("writexl")
  dir <- withr::local_tempdir()
  files <- cr_example_exports(dir, seed = 1, n_cells = 3, format = "xlsx")
  expect_true(all(grepl("\\.xlsx$", files)))
  first <- cr_read_export(files[[1]])
  expect_equal(nrow(first), 3L)
})

test_that("cr_example_exports validates its arguments", {
  dir <- withr::local_tempdir()
  expect_error(cr_example_exports(dir, n_cells = 0), "whole number")
  expect_error(cr_example_exports(dir, format = "parquet"), "should be one of")
})

test_that("cr_example_exports aborts without writexl", {
  dir <- withr::local_tempdir()
  testthat::local_mocked_bindings(
    requireNamespace = function(package, ...) FALSE,
    .package = "base"
  )
  expect_error(cr_example_exports(dir, format = "xlsx"), "writexl")
})
