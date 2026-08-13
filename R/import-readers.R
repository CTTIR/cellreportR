# Single-file readers.
#
# Convenience readers for the common one-file-one-table case and for
# the export formats of widely used segmentation tools.


#' Read segmented cell data from file
#'
#' Reads per-cell measurements from CSV, TSV, Excel, RDS or FCS formats.
#' The format is auto-detected from the file extension unless
#' `format` is given explicitly.
#'
#' @param path Path to file.
#' @param format Optional format string: one of `"csv"`, `"tsv"`,
#'   `"xlsx"`, `"rds"`, `"fcs"`. If `NULL`, inferred from file extension.
#' @return A tibble of cell measurements.
#' @seealso [cr_read_export()] and [cr_read_exports()] for exports that
#'   carry design information in their path and file name.
#' @family import
#' @export
#' @examples
#' f <- tempfile(fileext = ".csv")
#' utils::write.csv(
#'   data.frame(cell_id = "c1", well = "A01", target_signal = 12),
#'   f, row.names = FALSE
#' )
#' cr_read_cells(f)
cr_read_cells <- function(path, format = NULL) {
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.path {path}}")
  }
  if (is.null(format)) {
    ext <- .cr_path_ext(path)
    format <- switch(ext,
                     csv = "csv", tsv = "tsv", txt = "tsv",
                     xls = "xlsx", xlsx = "xlsx",
                     rds = "rds", fcs = "fcs", ext)
  }
  switch(format,
         csv = tibble::as_tibble(readr::read_csv(path,
                                                 show_col_types = FALSE)),
         tsv = tibble::as_tibble(readr::read_tsv(path,
                                                 show_col_types = FALSE)),
         xlsx = tibble::as_tibble(readxl::read_excel(path)),
         rds = .cr_read_rds(path),
         fcs = .cr_read_fcs(path),
         cli::cli_abort("Unsupported format {.val {format}}."))
}

.cr_read_rds <- function(path) {
  obj <- readRDS(path)
  if (inherits(obj, "cr_experiment")) return(tibble::as_tibble(obj$cells))
  if (inherits(obj, "cr_dataset")) return(tibble::as_tibble(obj$cells))
  if (inherits(obj, "segmantr_result") && !is.null(obj$cells)) {
    return(tibble::as_tibble(obj$cells))
  }
  if (is.data.frame(obj)) return(tibble::as_tibble(obj))
  cli::cli_abort("Unsupported RDS content for {.path {path}}.")
}

.cr_read_fcs <- function(path) {
  if (!requireNamespace("flowCore", quietly = TRUE)) {
    cli::cli_abort(
      "Reading FCS files requires the {.pkg flowCore} package (Bioconductor)."
    )
  }
  ff <- flowCore::read.FCS(path, transformation = FALSE)
  tibble::as_tibble(as.data.frame(flowCore::exprs(ff)))
}

#' Read experimental design from CSV or Excel
#'
#' @param path Path to file. `.csv`, `.tsv` and `.xlsx` are
#'   supported.
#' @return A tibble of design information.
#' @seealso [cr_design()] to turn the table into a validated design
#'   object.
#' @family import
#' @export
#' @examples
#' f <- tempfile(fileext = ".csv")
#' utils::write.csv(
#'   data.frame(well = c("A01", "A02"), treatment = c("Vehicle", "CompoundA")),
#'   f, row.names = FALSE
#' )
#' cr_read_design(f)
cr_read_design <- function(path) {
  if (!file.exists(path)) cli::cli_abort("File not found: {.path {path}}")
  ext <- .cr_path_ext(path)
  tbl <- switch(ext,
    csv = readr::read_csv(path, show_col_types = FALSE),
    tsv = readr::read_tsv(path, show_col_types = FALSE),
    txt = readr::read_tsv(path, show_col_types = FALSE),
    xls = readxl::read_excel(path),
    xlsx = readxl::read_excel(path),
    cli::cli_abort("Unsupported design format {.val {ext}}.")
  )
  tibble::as_tibble(tbl)
}

#' Read a CellProfiler object export
#'
#' Imports a CellProfiler CSV export and renames the columns to the
#' cellreportR convention (`well`, `x`, `y`, `area`, `circularity`,
#' one column per marker channel).
#'
#' @param path Path to CellProfiler CSV.
#' @return A tibble with standardised column names.
#' @family import
#' @export
#' @examples
#' f <- tempfile(fileext = ".csv")
#' utils::write.csv(
#'   data.frame(
#'     Metadata_Well = c("A01", "A01"),
#'     Location_Center_X = c(10, 20),
#'     Location_Center_Y = c(15, 25),
#'     AreaShape_Area = c(120, 130),
#'     Intensity_MeanIntensity_marker_1 = c(0.4, 0.6)
#'   ),
#'   f, row.names = FALSE
#' )
#' cr_read_cellprofiler(f)
cr_read_cellprofiler <- function(path) {
  raw <- readr::read_csv(path, show_col_types = FALSE)
  nms <- names(raw)

  out <- tibble::tibble(
    cell_id = sprintf("c%06d", seq_len(nrow(raw)))
  )

  well_col <- grep("(Metadata_)?Well", nms, value = TRUE, ignore.case = TRUE)[1]
  if (!is.na(well_col)) {
    out$well <- as.character(raw[[well_col]])
  } else if (all(c("ImageNumber") %in% nms)) {
    out$well <- sprintf("img_%03d", raw$ImageNumber)
  } else {
    cli::cli_abort("No well column detected in CellProfiler export.")
  }

  x_col <- grep("Location_Center_X|Centroid_X", nms, value = TRUE)[1]
  y_col <- grep("Location_Center_Y|Centroid_Y", nms, value = TRUE)[1]
  if (!is.na(x_col)) out$x <- raw[[x_col]]
  if (!is.na(y_col)) out$y <- raw[[y_col]]

  area_col <- grep("AreaShape_Area", nms, value = TRUE)[1]
  if (!is.na(area_col)) out$area <- raw[[area_col]]

  circ_col <- grep("FormFactor|Circularity", nms, value = TRUE)[1]
  if (!is.na(circ_col)) out$circularity <- raw[[circ_col]]

  intensity_cols <- grep("^Intensity_MeanIntensity_", nms, value = TRUE)
  for (col in intensity_cols) {
    chan <- sub("^Intensity_MeanIntensity_", "", col)
    out[[chan]] <- raw[[col]]
  }

  out
}

#' Read a QuPath measurement export
#'
#' @param path Path to QuPath TSV.
#' @return A tibble with standardised column names.
#' @family import
#' @export
#' @examples
#' f <- tempfile(fileext = ".tsv")
#' writeLines(
#'   c("Image\tCentroid X um\tCentroid Y um\tArea um^2\tCell: marker_1 mean",
#'     "A01.ome.tif\t10\t12\t120\t0.44",
#'     "A01.ome.tif\t30\t42\t118\t0.51"),
#'   f
#' )
#' cr_read_qupath(f)
cr_read_qupath <- function(path) {
  raw <- readr::read_tsv(path, show_col_types = FALSE)
  nms <- names(raw)

  out <- tibble::tibble(
    cell_id = if ("Object ID" %in% nms) {
      as.character(raw[["Object ID"]])
    } else {
      sprintf("c%06d", seq_len(nrow(raw)))
    }
  )

  well_col <- if ("Parent" %in% nms) "Parent" else "Image"
  if (well_col %in% nms) {
    out$well <- sub("\\.ome\\.tif$", "", as.character(raw[[well_col]]))
  } else {
    cli::cli_abort("No spatial unit column detected in QuPath export.")
  }

  if ("Centroid X um" %in% nms) out$x <- raw[["Centroid X um"]]
  if ("Centroid Y um" %in% nms) out$y <- raw[["Centroid Y um"]]

  area_col <- grep("Area", nms, value = TRUE, ignore.case = TRUE)[1]
  if (!is.na(area_col)) out$area <- raw[[area_col]]

  circ_col <- grep("Circularity", nms, value = TRUE, ignore.case = TRUE)[1]
  if (!is.na(circ_col)) out$circularity <- raw[[circ_col]]

  mean_cols <- grep(": .* mean$", nms, value = TRUE)
  for (col in mean_cols) {
    chan <- sub(".*: (.*) mean$", "\\1", col)
    out[[chan]] <- raw[[col]]
  }
  out
}

#' Read a segmantR result
#'
#' Imports an RDS file produced by the `segmantR` segmentation
#' package. Accepts either a `segmantr_result` list (where cells are
#' in `$cells`) or a plain data frame.
#'
#' @param path Path to RDS file.
#' @return A tibble of cells.
#' @family import
#' @export
#' @examples
#' f <- tempfile(fileext = ".rds")
#' saveRDS(data.frame(cell_id = "c1", well = "A01", target_signal = 12), f)
#' cr_read_segmantr(f)
cr_read_segmantr <- function(path) {
  .cr_read_rds(path)
}

# Version 0.1.0
