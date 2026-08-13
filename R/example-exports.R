# The synthetic on-disk export tree.
#
# One acquisition per file, every design fact in the directory layout
# and the file name, and raw instrument headers inside. This is the
# input the multi-file ingest functions were written for.

# Header of the area column in the synthetic exports. Written with
# escapes so that the package sources stay ASCII, while the files
# themselves carry the unit glyph that makes prefix matching necessary.
.cr_export_area_header <- "Nuclei - Area [\u00b5m\u00b2]"


#' Write a synthetic export tree
#'
#' Writes a nested directory of single-acquisition export files whose
#' design information lives in the directory layout and the file names
#' rather than inside the files. This is the input the multi-file ingest
#' functions were written for, so that [cr_read_exports()],
#' [cr_parse_paths()] and [cr_extract_markers()] can be demonstrated on
#' real files.
#'
#' The layout below `dir` is
#' `Run1/<compound>/<experiment>/<plate>/<file>`, and the file names
#' follow the grammar `<compound>_<interval>_<dose>_<mode>_<replicate>`
#' in which an absent token is meaningful: a name carrying no exposure
#' token is a vehicle control. Parenthetical markers are attached to
#' three files -- a two-pass acquisition, a repeated read and a
#' reagent-omitted acquisition -- and one directory is marked as a partly
#' filled plate.
#'
#' Column headers are raw instrument names rather than analysis names,
#' and one of them carries a unit glyph, so that a [cr_column_map()] is
#' genuinely required to read them.
#'
#' @param dir Directory to write the tree into. Created when it does not
#'   exist.
#' @param seed Random seed. `NULL` uses the current RNG state.
#' @param n_cells Number of cells written per file.
#' @param format File format, `"csv"` (default) or `"xlsx"`. Writing
#'   `"xlsx"` needs the `writexl` package.
#'
#' @return A character vector of the written file paths, invisibly.
#'
#' @seealso [cr_read_exports()], [cr_path_spec()], [cr_example_screen()],
#'   [cr_example_path()].
#' @family example data
#' @export
#' @examples
#' d <- file.path(tempdir(), "cr_example_exports")
#' files <- cr_example_exports(d, seed = 1, n_cells = 5)
#' basename(files)
#'
#' map <- cr_column_map(
#'   exact = c("Event Label" = "cell_id",
#'             "Target - Signal Mean" = "target_signal"),
#'   prefix = c("^Nuclei - Area" = "area")
#' )
#' cells <- cr_read_exports(d, column_map = map, progress = FALSE)
#' head(cells[, c("source_file", "cell_id", "target_signal", "area")], 3)
cr_example_exports <- function(dir = tempdir(),
                               seed = 42,
                               n_cells = 20,
                               format = c("csv", "xlsx")) {
  format <- match.arg(format)
  .cr_screen_count(n_cells, 1, 5000)
  if (identical(format, "xlsx") &&
      !requireNamespace("writexl", quietly = TRUE)) {
    cli::cli_abort(c(
      "Writing {.val xlsx} exports needs the {.pkg writexl} package.",
      "i" = "Install it, or keep the default {.code format = \"csv\"}."
    ))
  }
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)

  .cr_with_seed(seed, {
    plan <- .cr_export_plan()
    out <- character(nrow(plan))
    for (i in seq_len(nrow(plan))) {
      leaf <- file.path(dir, "Run1", plan$compound[[i]],
                        plan$experiment[[i]], plan$container[[i]])
      if (!dir.exists(leaf)) dir.create(leaf, recursive = TRUE)
      path <- file.path(leaf, paste0(plan$stem[[i]], ".", format))
      tbl <- .cr_export_table(n_cells, level = plan$level[[i]])
      if (identical(format, "csv")) {
        readr::write_csv(tbl, path, na = "")
      } else {
        writexl::write_xlsx(tbl, path)
      }
      out[[i]] <- path
    }
    invisible(out)
  })
}

# ---- internal: export tree -------------------------------------------------

# ---- internal: export tree -------------------------------------------------

# The files written by cr_example_exports(): compound, experiment,
# container directory, file stem and the signal level to draw at.
.cr_export_plan <- function() {
  tibble::tibble(
    compound = c(rep("CompoundA", 7L), rep("CompoundB", 3L)),
    experiment = "Exp_1",
    container = c("Plate_1", "Plate_1", "Plate_1",
                  "Plate_2", "Plate_2", "Plate_2", "Plate_2",
                  "Plate_1 (partial)", "Plate_1 (partial)",
                  "Plate_1 (partial)"),
    stem = c(
      "CompoundA_15min_vehicle_1",
      "CompoundA_15min_250uM_treated_1",
      "CompoundA_15min_250uM_treated_1.1 (split)",
      "CompoundA_60min_vehicle_2",
      "CompoundA_60min_250uM_treated_2",
      "CompoundA_60min_250uM_treated_2 (repeat)",
      "CompoundA_60min_250uM_treated_2.2",
      "CompoundB_15min_vehicle_1",
      "CompoundB_15min_250uM_treated_1",
      "CompoundB_15min_250uM_treated_1 (no reagent)"
    ),
    level = c("control", "treated", "treated",
              "control", "treated", "treated", "treated",
              "control", "treated", "background")
  )
}

# One export table in raw instrument headers, terminated by the single
# all-blank row that many instruments write.
.cr_export_table <- function(n, level = c("control", "treated",
                                          "background")) {
  level <- match.arg(level)
  centre <- switch(level,
                   control = log(400),
                   treated = log(950),
                   background = log(48))
  out <- tibble::tibble(
    `Event Label` = c(sprintf("E%04d", seq_len(n)), NA_character_),
    `Position X [px]` = c(round(stats::runif(n, 0, 1500), 1), NA_real_),
    `Position Y [px]` = c(round(stats::runif(n, 0, 1500), 1), NA_real_)
  )
  out[[.cr_export_area_header]] <- c(round(stats::rlnorm(n, log(180), 0.3), 1),
                                     NA_real_)
  out[["Nuclei - Signal Mean"]] <- c(round(stats::rlnorm(n, log(600), 0.3), 1),
                                     NA_real_)
  out[["Target - Signal Mean"]] <- c(round(stats::rlnorm(n, centre, 0.45), 1),
                                     NA_real_)
  out
}

# Version 0.1.0
