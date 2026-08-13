# On-disk example files.
#
# Writers for the demonstration tables in the layouts the cr_read_*
# importers understand, and the resolver for the tiny fixtures that
# ship inside the package under inst/extdata.


#' Write example files in several on-disk formats
#'
#' Writes the tables behind [cr_example_experiment()] in the layouts the
#' `cr_read_*` importers understand, so that the import functions can be
#' demonstrated on real files without any being shipped.
#'
#' @param dir Directory to write into. Created when it does not exist.
#' @param seed Seed passed to [cr_example_experiment()].
#'
#' @return A character vector of the written file paths, invisibly.
#'
#' @seealso [cr_example_exports()] for a nested export tree with the
#'   design encoded in the paths, [cr_example_path()] for the files
#'   shipped inside the package.
#' @family example data
#' @export
#' @examples
#' d <- file.path(tempdir(), "cr_example_files")
#' files <- cr_example_files(d, seed = 1)
#' basename(files)
cr_example_files <- function(dir = tempdir(), seed = 42) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  exp <- cr_example_experiment(seed = seed, n_cells_per_well = 50)

  out <- character()

  cells_path <- file.path(dir, "cells.csv")
  readr::write_csv(exp$cells, cells_path)
  out <- c(out, cells_path)

  if (requireNamespace("writexl", quietly = TRUE)) {
    design_path <- file.path(dir, "design.xlsx")
    writexl::write_xlsx(exp$design, design_path)
    out <- c(out, design_path)
  } else {
    design_path <- file.path(dir, "design.csv")
    readr::write_csv(exp$design, design_path)
    out <- c(out, design_path)
  }

  cp_path <- file.path(dir, "cells_cellprofiler.csv")
  readr::write_csv(.cr_to_cellprofiler(exp$cells), cp_path)
  out <- c(out, cp_path)

  qp_path <- file.path(dir, "cells_qupath.tsv")
  readr::write_tsv(.cr_to_qupath(exp$cells), qp_path)
  out <- c(out, qp_path)

  invisible(out)
}

#' Locate the example files shipped with the package
#'
#' Three tiny synthetic files are installed under `extdata` so that
#' examples, tests and vignettes can read a real file without writing
#' one first and without depending on any gated data.
#'
#' \describe{
#'   \item{`example-export.csv`}{One acquisition of one unit as a vendor
#'     export: raw instrument headers, an all-blank trailing row of the
#'     kind many instruments write, and a header carrying a unit glyph,
#'     which is what the prefix matching of [cr_column_map()] exists
#'     for.}
#'   \item{`example-export.xlsx`}{The same acquisition as a workbook.}
#'   \item{`example-design.csv`}{The unit-level design table covering
#'     the units in the exports.}
#' }
#'
#' The two exports are the treated acquisition that
#' `cr_example_exports(seed = 42, n_cells = 20)` writes, so the shipped
#' files can be regenerated at any time rather than being opaque
#' binaries.
#'
#' @param file Name of one shipped file, or `NULL` (the default) to
#'   return them all.
#'
#' @return A character vector of absolute paths; length one when `file`
#'   is given.
#'
#' @seealso [cr_read_export()], [cr_read_design()], [cr_example_files()].
#' @family example data
#' @export
#' @examples
#' basename(cr_example_path())
#'
#' cells <- cr_read_export(cr_example_path("example-export.csv"))
#' head(cells, 3)
cr_example_path <- function(file = NULL) {
  dir <- system.file("extdata", package = "cellreportR")
  available <- sort(list.files(dir))
  if (is.null(file)) {
    return(file.path(dir, available))
  }
  if (!is.character(file) || length(file) != 1L || is.na(file)) {
    cli::cli_abort("{.arg file} must be a single file name or {.code NULL}.")
  }
  path <- file.path(dir, file)
  if (!file.exists(path)) {
    cli::cli_abort(c(
      "No example file called {.val {file}}.",
      "i" = "Available: {.val {available}}."
    ))
  }
  path
}

# ---- internal converters ---------------------------------------------------

# Recast the cells table in the column naming of a widely used
# segmentation tool, for the reader demonstrations.
.cr_to_cellprofiler <- function(cells) {
  tibble::tibble(
    ImageNumber = as.integer(factor(cells$well)),
    ObjectNumber = seq_len(nrow(cells)),
    Metadata_Well = cells$well,
    AreaShape_Area = cells$area,
    AreaShape_FormFactor = cells$circularity,
    Location_Center_X = cells$x,
    Location_Center_Y = cells$y,
    Intensity_MeanIntensity_DAPI = cells$DAPI,
    Intensity_MeanIntensity_marker_1 = cells$marker_1,
    Intensity_MeanIntensity_marker_2 = cells$marker_2,
    Intensity_MeanIntensity_marker_3 = cells$marker_3
  )
}

.cr_to_qupath <- function(cells) {
  tibble::tibble(
    Image = paste0(cells$well, ".ome.tif"),
    `Object ID` = cells$cell_id,
    Name = "Cell",
    Parent = cells$well,
    `Centroid X um` = cells$x,
    `Centroid Y um` = cells$y,
    `Cell: Area um^2` = cells$area,
    `Cell: Circularity` = cells$circularity,
    `Cell: DAPI mean` = cells$DAPI,
    `Cell: marker_1 mean` = cells$marker_1,
    `Cell: marker_2 mean` = cells$marker_2,
    `Cell: marker_3 mean` = cells$marker_3
  )
}

# Version 0.1.0
