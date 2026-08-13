# Multi-file ingest: column contracts, path grammars, markers, unit
# assignment and the cr_design / cr_dataset constructors.

# ---- fixtures --------------------------------------------------------------

.export_frame <- function(n, seed = 1) {
  set.seed(seed)
  df <- data.frame(
    "Event Label" = seq_len(n),
    "Signal - Mean Intensity" = round(stats::runif(n, 10, 100), 2),
    "Nuclei - Area (um2)" = round(stats::runif(n, 50, 150), 1),
    "Centroid X (pixels)" = seq_len(n) * 3,
    "Centroid Y (pixels)" = seq_len(n) * 5,
    check.names = FALSE
  )
  df[n + 1L, ] <- NA # the trailing blank row instruments write
  df
}

.export_tree <- function(root) {
  p1 <- file.path(root, "Run1", "CompoundA", "Plate_1")
  p2 <- file.path(root, "Run1", "CompoundA", "Plate_2 (partial)")
  dir.create(p1, recursive = TRUE, showWarnings = FALSE)
  dir.create(p2, recursive = TRUE, showWarnings = FALSE)
  spec <- list(
    c(p1, "CompoundA_vehicle_1.csv", 8),
    c(p1, "CompoundA_vehicle_3.csv", 5),
    c(p1, "CompoundA_vehicle_3 (repeat).csv", 4),
    c(p1, "CompoundA_5min_10uM_treated_1.csv", 6),
    c(p1, "CompoundA_5min_10uM_treated_1.1 (split).csv", 3),
    c(p1, "CompoundA_5min_10uM_treated_2.2.csv", 7),
    c(p2, "CompoundA_vehicle_2 (no reagent).csv", 2)
  )
  for (i in seq_along(spec)) {
    utils::write.csv(.export_frame(as.integer(spec[[i]][[3]]), seed = i),
                     file.path(spec[[i]][[1]], spec[[i]][[2]]),
                     row.names = FALSE)
  }
  invisible(root)
}

.print_text <- function(x) {
  paste(utils::capture.output(print(x), type = "message"), collapse = "\n")
}

.demo_map <- function() {
  cr_column_map(
    exact = c("Event Label" = "cell_id",
              "Signal - Mean Intensity" = "target_signal",
              "Centroid X (pixels)" = "x",
              "Centroid Y (pixels)" = "y"),
    prefix = c("^Nuclei - Area" = "area"),
    keep = c("cell_id", "target_signal", "area", "x", "y")
  )
}

.demo_grammar <- function() {
  cr_filename_grammar(
    tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM",
                  mode = "treated|vehicle"),
    defaults = list(interval = "none", dose = "vehicle"),
    core_patterns = c("^vehicle$", "^[0-9]+min_[0-9]+uM_treated$"),
    typo_fixes = c("mikroM" = "uM"),
    prefix_strip = c("CompoundA", "CompoundAB")
  )
}

.demo_markers <- function() {
  cr_marker_rules(merge_unit = "\\(split\\)",
                  partial_plate = "\\(partial\\)",
                  omitted_reagent = "\\(no reagent\\)",
                  reacquisition = "\\(repeat\\)")
}

.demo_spec <- function() {
  cr_path_spec(levels = c("run", "compound", "plate"),
               grammar = .demo_grammar(), markers = .demo_markers())
}

# ---- column contract -------------------------------------------------------

test_that("cr_column_map validates and prints", {
  map <- .demo_map()
  expect_s3_class(map, "cr_column_map")
  expect_length(map$exact, 4)
  expect_match(.print_text(map), "cr_column_map")
  expect_error(cr_column_map(exact = c("a", "b")), "fully named")
  expect_error(cr_column_map(keep = 1), "character vector")
})

test_that("the column contract renames tolerantly and keeps order", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "one.csv")
  utils::write.csv(.export_frame(3), f, row.names = FALSE)
  out <- cr_read_export(f, column_map = .demo_map())
  expect_true(all(c("cell_id", "target_signal", "area", "x", "y") %in%
                    names(out)))
  # a contract naming columns the export does not have must not error
  partial <- cr_column_map(exact = c("Not There" = "nope",
                                     "Event Label" = "cell_id"))
  expect_no_error(cr_read_export(f, column_map = partial))
})

test_that("a contract that collapses two headers is an error", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "one.csv")
  utils::write.csv(.export_frame(3), f, row.names = FALSE)
  bad <- cr_column_map(exact = c("Event Label" = "dup",
                                 "Signal - Mean Intensity" = "dup"))
  expect_error(cr_read_export(f, column_map = bad), "duplicated names")
})

# ---- single-file reader ----------------------------------------------------

test_that("cr_read_export adds provenance and drops the blank row", {
  dir <- withr::local_tempdir()
  f <- file.path(dir, "CompoundA_vehicle_1.csv")
  utils::write.csv(.export_frame(5), f, row.names = FALSE)
  out <- cr_read_export(f, column_map = .demo_map())
  expect_identical(names(out)[1:2], c("source_file", "source_path"))
  expect_identical(unique(out$source_file), "CompoundA_vehicle_1.csv")
  expect_equal(nrow(out), 5)
  expect_equal(nrow(cr_read_export(f, drop_empty_rows = FALSE)), 6)
})

test_that("cr_read_export rejects missing files and unknown formats", {
  dir <- withr::local_tempdir()
  expect_error(cr_read_export(file.path(dir, "nope.csv")), "not found")
  f <- file.path(dir, "x.dat")
  writeLines("a,b", f)
  expect_error(cr_read_export(f), "Unsupported export format")
})

test_that("cr_read_export reads Excel exports", {
  skip_if_not_installed("writexl")
  dir <- withr::local_tempdir()
  f <- file.path(dir, "one.xlsx")
  writexl::write_xlsx(.export_frame(4), f)
  out <- cr_read_export(f, column_map = .demo_map())
  expect_equal(nrow(out), 4)
  expect_true("target_signal" %in% names(out))
})

# ---- directory reader ------------------------------------------------------

test_that("cr_read_exports binds a tree and joins parsed design facts", {
  root <- withr::local_tempdir()
  .export_tree(root)
  cells <- cr_read_exports(root, column_map = .demo_map(),
                           spec = .demo_spec(), progress = FALSE)
  expect_equal(nrow(cells), 8 + 5 + 4 + 6 + 3 + 7 + 2)
  expect_true(all(c("run", "compound", "plate", "interval", "dose", "mode",
                    "replicate", "merge_unit") %in% names(cells)))
  expect_length(attr(cells, "files"), 7)
  expect_identical(sort(unique(cells$dose)), c("10uM", "vehicle"))
})

test_that("cr_read_exports accepts an arbitrary parser function", {
  root <- withr::local_tempdir()
  .export_tree(root)
  cells <- cr_read_exports(
    root, column_map = .demo_map(), progress = FALSE,
    parser = function(paths) {
      tibble::tibble(source_path = paths, batch = "B1")
    }
  )
  expect_identical(unique(cells$batch), "B1")
})

test_that("cr_read_exports errors informatively", {
  root <- withr::local_tempdir()
  expect_error(cr_read_exports(root, progress = FALSE), "No export files")
  .export_tree(root)
  expect_error(cr_read_exports(root, parser = "nope", progress = FALSE),
               "must be a function")
  expect_error(
    cr_read_exports(root, progress = FALSE,
                    parser = function(paths) tibble::tibble(a = 1)),
    "one row per file"
  )
  expect_error(cr_read_exports(file.path(root, "nowhere"), progress = FALSE),
               "existing directory")
})

# ---- markers ---------------------------------------------------------------

test_that("markers separate the file marker from the container marker", {
  files <- tibble::tibble(
    source_file = c("CompoundA_1.1 (split).csv", "CompoundA_2.csv",
                    "CompoundA_3 (weekend).csv"),
    plate = c("Plate_1", "Plate_2 (partial)", "Plate_1")
  )
  out <- cr_extract_markers(files, container_col = "plate",
                            rules = .demo_markers(), stem_col = "stem")
  expect_true(out$merge_unit[[1]])
  expect_false(out$partial_plate[[1]])
  expect_true(out$partial_plate[[2]])
  expect_false(out$merge_unit[[2]])
  # an undocumented marker is captured, not guessed at or dropped
  expect_identical(out$variant[[3]], "weekend")
  expect_identical(out$stem[[1]], "CompoundA_1.1")
  expect_true(all(is.na(out$variant[1:2])))
})

test_that("cr_extract_markers validates its inputs", {
  files <- tibble::tibble(source_file = "a.csv")
  expect_error(cr_extract_markers(files, rules = list()), "cr_marker_rules")
  expect_error(cr_extract_markers(files, name_col = "nope"), "missing required")
  expect_error(cr_extract_markers("not a frame"), "must be a data frame")
})

# ---- grammar and path parsing ---------------------------------------------

test_that("cr_filename_grammar validates its arguments", {
  expect_error(cr_filename_grammar(tokens = list("[0-9]+")), "fully named")
  expect_error(
    cr_filename_grammar(tokens = list(a = "x"), defaults = list(b = "y")),
    "must be token names"
  )
  expect_error(cr_filename_grammar(core_patterns = 1), "character vector")
  expect_match(.print_text(.demo_grammar()), "cr_filename_grammar")
})

test_that("cr_parse_paths recovers levels, markers and tokens", {
  root <- withr::local_tempdir()
  .export_tree(root)
  files <- sort(list.files(root, pattern = "\\.csv$", recursive = TRUE,
                           full.names = TRUE))
  meta <- cr_parse_paths(files, root = root, spec = .demo_spec())
  expect_equal(nrow(meta), 7)
  expect_identical(unique(meta$run), "Run1")
  expect_true(all(meta$parse_ok))
  # the absence of a token is meaningful and falls back to the default
  veh <- meta[meta$source_file == "CompoundA_vehicle_1.csv", ]
  expect_identical(veh$interval, "none")
  expect_identical(veh$dose, "vehicle")
  expect_identical(veh$replicate, "1")
  # the half-scan replicate keeps its full token
  split <- meta[meta$merge_unit, ]
  expect_identical(split$replicate, "1.1")
})

test_that("cr_parse_paths accepts index-mapped levels", {
  root <- withr::local_tempdir()
  .export_tree(root)
  files <- sort(list.files(root, pattern = "\\.csv$", recursive = TRUE,
                           full.names = TRUE))
  meta <- cr_parse_paths(files, root = root,
                         levels = c(run = 1L, compound = 2L, plate = -1L),
                         grammar = .demo_grammar(),
                         markers = .demo_markers())
  expect_identical(unique(meta$compound), "CompoundA")
  expect_true(all(grepl("^Plate_", meta$plate)))
})

test_that("an unparseable name is a hard error, not a silent default", {
  root <- withr::local_tempdir()
  .export_tree(root)
  bad <- file.path(root, "Run1", "CompoundA", "Plate_1",
                   "CompoundA_5min_10uM_treatd_9.csv")
  utils::write.csv(.export_frame(2), bad, row.names = FALSE)
  files <- sort(list.files(root, pattern = "\\.csv$", recursive = TRUE,
                           full.names = TRUE))
  expect_error(cr_parse_paths(files, root = root, spec = .demo_spec()),
               "does not match the grammar")
  lax <- cr_parse_paths(files, root = root, spec = .demo_spec(),
                        strict = FALSE)
  expect_equal(sum(!lax$parse_ok), 1L)
  expect_true(all(!is.na(lax$parse_error[!lax$parse_ok])))
})

test_that("the typo repair table runs before the grammar check", {
  g <- .demo_grammar()
  out <- cr_parse_paths("CompoundA_5min_10mikroM_treated_1.csv",
                        grammar = g)
  expect_identical(out$dose, "10uM")
  expect_true(out$parse_ok)
})

test_that("prefixes are stripped longest-first", {
  g <- cr_filename_grammar(tokens = list(mode = "treated|vehicle"),
                           prefix_strip = c("CompoundA", "CompoundAB"))
  out <- cr_parse_paths("CompoundAB_treated_1.csv", grammar = g)
  expect_identical(out$core, "treated")
})

test_that("cr_parse_paths and cr_path_spec validate their inputs", {
  expect_error(cr_parse_paths(character()), "non-empty character")
  expect_error(cr_parse_paths("a.csv", levels = c("run")), "root")
  expect_error(cr_parse_paths("a.csv", spec = list()), "cr_path_spec")
  expect_error(cr_path_spec(levels = c(run = "1")), "must be unnamed")
  expect_error(cr_path_spec(levels = 1), "fully named")
  expect_error(cr_path_spec(grammar = list()), "cr_filename_grammar")
  expect_error(cr_path_spec(markers = list()), "cr_marker_rules")
  expect_match(.print_text(.demo_spec()), "cr_path_spec")
})

# ---- unit assignment -------------------------------------------------------

test_that("half-scan files merge, look-alike suffixes do not", {
  files <- tibble::tibble(
    compound = "CompoundA",
    plate = "Plate_1",
    mode = "treated",
    replicate = c("1", "1.1", "2", "2.2"),
    merge_unit = c(FALSE, TRUE, FALSE, FALSE),
    reacquisition = FALSE
  )
  out <- cr_assign_units(files, key_vars = c("compound", "plate", "mode"))
  expect_identical(out$replicate_merged, c("1", "1", "2", "2.2"))
  expect_equal(attr(out, "n_units"), 3L)
  expect_identical(out$well_id[[1]], out$well_id[[2]])
  expect_false(identical(out$well_id[[3]], out$well_id[[4]]))
})

test_that("the merge marker gates suffix merging", {
  files <- tibble::tibble(compound = "CompoundA",
                          replicate = c("1", "1.1"),
                          merge_unit = c(FALSE, FALSE))
  out <- cr_assign_units(files, key_vars = "compound")
  expect_equal(attr(out, "n_units"), 2L)
  # without the marker column nothing merges, and that is said out loud
  no_marker <- files[, c("compound", "replicate")]
  expect_message(
    out2 <- cr_assign_units(no_marker, key_vars = "compound"),
    "left unmerged"
  )
  expect_equal(attr(out2, "n_units"), 2L)
  # merging on the suffix alone is opt-in
  out3 <- cr_assign_units(no_marker, key_vars = "compound",
                          rules = cr_merge_rules(merge_marker = NULL))
  expect_equal(attr(out3, "n_units"), 1L)
})

test_that("repeated reads fold in or stay apart on request", {
  files <- tibble::tibble(compound = "CompoundA",
                          replicate = c("3", "3"),
                          merge_unit = FALSE,
                          reacquisition = c(FALSE, TRUE))
  merged <- cr_assign_units(files, key_vars = "compound")
  expect_equal(attr(merged, "n_units"), 1L)
  apart <- cr_assign_units(
    files, key_vars = "compound",
    rules = cr_merge_rules(merge_reacquisition = FALSE)
  )
  expect_equal(attr(apart, "n_units"), 2L)
  expect_match(apart$replicate_merged[[2]], "_re$")
})

test_that("cr_assign_units validates its inputs", {
  files <- tibble::tibble(compound = "CompoundA", replicate = "1")
  expect_error(cr_assign_units(files, key_vars = "nope"), "missing required")
  expect_error(cr_assign_units(files, key_vars = character()), "non-empty")
  expect_error(cr_assign_units(files, key_vars = "compound", rules = list()),
               "cr_merge_rules")
  expect_error(cr_assign_units("not a frame", key_vars = "a"),
               "must be a data frame")
  expect_match(.print_text(cr_merge_rules()), "cr_merge_rules")
})

test_that("cr_unit_map reports which units were assembled from many files", {
  cells <- tibble::tibble(
    source_path = rep(c("a.csv", "b.csv", "c.csv"), times = c(3, 2, 4)),
    compound = "CompoundA",
    replicate = rep(c("1", "1.1", "2"), times = c(3, 2, 4)),
    merge_unit = rep(c(FALSE, TRUE, FALSE), times = c(3, 2, 4))
  )
  units <- cr_assign_units(cells, key_vars = "compound")
  map <- cr_unit_map(units)
  expect_equal(nrow(map), 3)
  expect_identical(map$n_files, c(2L, 2L, 1L))
  expect_identical(map$merged, c(TRUE, TRUE, FALSE))
  expect_equal(sum(map$n_cells), nrow(cells))
  expect_error(cr_unit_map(units, id_col = "nope"), "missing required")
})

test_that("cr_centroid_overlap is the evidence test for merging", {
  cells <- tibble::tibble(
    well_id = rep(c("u1", "u2", "u3"), each = 4),
    x = c(1, 2, 3, 4, 1, 2, 3, 90, 500, 600, 700, 800),
    y = c(1, 2, 3, 4, 1, 2, 3, 90, 500, 600, 700, 800)
  )
  same <- cr_centroid_overlap(cells, "u1", "u2")
  expect_equal(as.numeric(same), 0.75)
  expect_equal(attr(same, "n_matched"), 3L)
  different <- cr_centroid_overlap(cells, "u1", "u3")
  expect_equal(as.numeric(different), 0)
  expect_error(cr_centroid_overlap(cells, "u1", "nope"), "must have cells")
  expect_error(cr_centroid_overlap(cells, "u1", "u2", coords = "x"),
               "exactly two")
  expect_error(cr_centroid_overlap(cells, "u1", "u2", tol = 0),
               "positive number")
})

# ---- design ----------------------------------------------------------------

test_that("cr_design collapses a cell table to one row per unit", {
  cells <- tibble::tibble(
    well = rep(c("A01", "A02"), each = 3),
    treatment = rep(c("Vehicle", "CompoundA"), each = 3),
    plate = "Plate_1",
    target_signal = 1:6
  )
  d <- cr_design(cells, control_level = "Vehicle", batch_vars = "plate",
                 keep = c("plate"))
  expect_s3_class(d, "cr_design")
  expect_equal(nrow(d$table), 2)
  expect_identical(d$unit, "well")
  expect_identical(d$control_level, "Vehicle")
  expect_match(.print_text(d), "cr_design")
})

test_that("an ambiguous design names the offending column", {
  cells <- tibble::tibble(well = c("A01", "A01"),
                          treatment = c("Vehicle", "CompoundA"))
  expect_error(cr_design(cells), "exactly one design row")
  expect_error(cr_design(cells), "treatment")
})

test_that("cr_design validates levels, control level and unit", {
  units <- tibble::tibble(well = c("A01", "A02"),
                          treatment = c("Vehicle", "CompoundA"))
  expect_error(cr_design(units, control_level = "nope"),
               "must be a value of")
  expect_error(cr_design(units, levels = list(treatment = "Vehicle")),
               "does not cover")
  d <- cr_design(units, levels = list(treatment = c("Vehicle", "CompoundA")))
  expect_identical(levels(d$table$treatment), c("Vehicle", "CompoundA"))
  expect_error(cr_design(units, unit = "nope"), "missing required")
  expect_error(cr_design(units, batch_vars = "nope"), "missing required")
  expect_error(cr_design(tibble::tibble(well = "A01")), "missing required")
  expect_error(cr_design("not a frame"), "must be a data frame")
})

test_that("cr_design finds a derived unit column", {
  units <- tibble::tibble(well_id = c("u1", "u2"), treatment = c("a", "b"))
  expect_identical(cr_design(units)$unit, "well_id")
  expect_error(cr_design(tibble::tibble(id = "x", treatment = "a")),
               "No spatial unit column")
})

# ---- dataset ---------------------------------------------------------------

test_that("cr_dataset derives provenance from the cells", {
  cells <- tibble::tibble(
    source_path = rep(c("a.csv", "b.csv"), times = c(3, 2)),
    source_file = rep(c("a.csv", "b.csv"), times = c(3, 2)),
    well = rep(c("A01", "A02"), times = c(3, 2)),
    treatment = rep(c("Vehicle", "CompoundA"), times = c(3, 2)),
    target_signal = c(10, 12, 11, 30, 33)
  )
  ds <- cr_dataset(cells)
  expect_s3_class(ds, "cr_dataset")
  expect_equal(nrow(ds$provenance), 2)
  expect_identical(ds$provenance$n_cells, c(3L, 2L))
  # per-cell measurements are not design facts and must not be promoted
  expect_false("target_signal" %in% names(ds$provenance))
  expect_identical(ds$unit_var, "well")
  expect_match(.print_text(ds), "cr_dataset")
  expect_identical(summary(ds), ds$provenance)
})

test_that("cr_dataset accepts a design table or object", {
  cells <- tibble::tibble(well = c("A01", "A02"),
                          treatment = c("Vehicle", "CompoundA"),
                          target_signal = c(1, 2))
  ds <- cr_dataset(cells, design = cells[, c("well", "treatment")])
  expect_s3_class(ds$design, "cr_design")
  ds2 <- cr_dataset(cells, design = cr_design(cells, keep = character()))
  expect_identical(ds2$design$unit, "well")
  expect_error(cr_dataset(cells, design = 1), "cr_design")
  expect_error(cr_dataset("not a frame"), "must be a data frame")
  expect_error(cr_dataset(cells, provenance = 1), "data frame")
})

test_that("a data set with no provenance column still builds", {
  cells <- tibble::tibble(well = "A01", treatment = "Vehicle", value = 1)
  ds <- cr_dataset(cells)
  expect_null(ds$provenance)
})

# ---- experiment ------------------------------------------------------------

test_that("cr_build_experiment consumes a cr_dataset and a cr_design", {
  cells <- tibble::tibble(
    cell_id = sprintf("c%02d", 1:6),
    well_id = rep(c("u1", "u2"), each = 3),
    compound = "CompoundA",
    plate = "Plate_1",
    mode = rep(c("vehicle", "treated"), each = 3),
    target_signal = c(10, 12, 11, 30, 33, 29)
  )
  design <- cr_design(cells, unit = "well_id", treatment = "mode",
                      control_level = "vehicle",
                      batch_vars = c("compound", "plate"),
                      keep = c("compound", "plate"))
  ds <- cr_dataset(cells, design = design, unit_var = "well_id")
  exp <- cr_build_experiment(ds)
  expect_s3_class(exp, "cr_experiment")
  expect_identical(exp$spatial_unit, "well_id")
  expect_identical(exp$unit_var, "well_id")
  expect_identical(exp$batch_vars, c("compound", "plate"))
  # the rest of the package looks for a column called `treatment`
  expect_true("treatment" %in% names(exp$design))
  expect_identical(exp$design$treatment, exp$design$mode)
  expect_true(cr_validate_experiment(exp))
})

test_that("cr_build_experiment keeps the classic well/design contract", {
  cells <- tibble::tibble(cell_id = c("c1", "c2"), well = c("A01", "A02"),
                          area = c(10, 20), target_signal = c(1, 2))
  design <- tibble::tibble(well = c("A01", "A02"),
                           treatment = c("Vehicle", "CompoundA"))
  exp <- cr_build_experiment(cells, design)
  expect_identical(exp$spatial_unit, "well")
  expect_identical(exp$batch_vars, character())
  expect_null(exp$provenance)
  expect_false("area" %in% exp$channels$channel)
  expect_true("target_signal" %in% exp$channels$channel)
})

test_that("cr_build_experiment requires a design", {
  cells <- tibble::tibble(cell_id = "c1", well = "A01", target_signal = 1)
  expect_error(cr_build_experiment(cells), "`design` is required")
})

test_that("cr_validate_experiment checks the structural slots", {
  cells <- tibble::tibble(cell_id = c("c1", "c2"), well = c("A01", "A02"),
                          target_signal = c(1, 2))
  design <- tibble::tibble(well = c("A01", "A02"),
                           treatment = c("Vehicle", "CompoundA"))
  exp <- cr_build_experiment(cells, design)
  expect_error(cr_validate_experiment(list()), "cr_experiment")

  broken <- exp
  broken$unit_var <- "slide"
  expect_error(cr_validate_experiment(broken), "disagree")

  broken2 <- exp
  broken2$batch_vars <- "nowhere"
  expect_error(cr_validate_experiment(broken2), "design or cell columns")

  broken3 <- exp
  broken3$provenance <- "not a table"
  expect_error(cr_validate_experiment(broken3), "data frame")

  broken4 <- exp
  broken4$channels <- NULL
  expect_error(cr_validate_experiment(broken4), "missing slots")
})

test_that("the ingest chain runs end to end", {
  root <- withr::local_tempdir()
  .export_tree(root)
  cells <- cr_read_exports(root, column_map = .demo_map(),
                           spec = .demo_spec(), progress = FALSE)
  cells$cell_id <- sprintf("c%04d", seq_len(nrow(cells)))
  units <- cr_assign_units(
    cells, key_vars = c("compound", "plate", "interval", "dose", "mode")
  )
  # the specificity arm leaves the analysis pool before anything else
  analysis <- units[!units$omitted_reagent, ]
  aside <- units[units$omitted_reagent, ]
  expect_equal(nrow(aside), 2)

  design <- cr_design(analysis, unit = "well_id", treatment = "mode",
                      control_level = "vehicle",
                      batch_vars = c("compound", "plate", "interval"),
                      keep = c("compound", "plate", "interval", "dose"))
  ds <- cr_dataset(analysis, design = design, unit_var = "well_id")
  exp <- cr_build_experiment(ds, set_aside = aside)
  expect_true(cr_validate_experiment(exp))
  expect_equal(nrow(exp$design), 4)
  expect_equal(nrow(exp$provenance), 6)
  expect_equal(nrow(exp$set_aside), 2)
  expect_identical(exp$channels$channel, "target_signal")
})
