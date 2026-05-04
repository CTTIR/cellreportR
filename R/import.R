#' Read segmented cell data from file
#'
#' Reads per-cell measurements from CSV, TSV, RDS or FCS formats.
#' The format is auto-detected from the file extension unless
#' `format` is given explicitly.
#'
#' @param path Path to file.
#' @param format Optional format string: one of `"csv"`, `"tsv"`,
#'   `"rds"`, `"fcs"`. If `NULL`, inferred from file extension.
#' @return A tibble of cell measurements.
#' @export
#' @examples
#' d <- tempfile("cr_cells_"); dir.create(d)
#' files <- cr_example_files(d)
#' cells <- cr_read_cells(file.path(d, "cells.csv"))
#' head(cells)
cr_read_cells <- function(path, format = NULL) {
  if (!file.exists(path)) {
    cli::cli_abort("File not found: {.path {path}}")
  }
  if (is.null(format)) {
    ext <- tolower(tools::file_ext(path))
    format <- switch(ext,
                     csv = "csv", tsv = "tsv", txt = "tsv",
                     rds = "rds", fcs = "fcs", ext)
  }
  switch(format,
         csv = tibble::as_tibble(readr::read_csv(path,
                                                 show_col_types = FALSE)),
         tsv = tibble::as_tibble(readr::read_tsv(path,
                                                 show_col_types = FALSE)),
         rds = .cr_read_rds(path),
         fcs = .cr_read_fcs(path),
         cli::cli_abort("Unsupported format {.val {format}}."))
}

.cr_read_rds <- function(path) {
  obj <- readRDS(path)
  if (inherits(obj, "cr_experiment")) return(tibble::as_tibble(obj$cells))
  if (inherits(obj, "segmantr_result") && !is.null(obj$cells)) {
    return(tibble::as_tibble(obj$cells))
  }
  if (is.data.frame(obj)) return(tibble::as_tibble(obj))
  cli::cli_abort("Unsupported RDS content for {.path {path}}.")
}

.cr_read_fcs <- function(path) {
  if (!requireNamespace("flowCore", quietly = TRUE)) {
    cli::cli_abort("Reading FCS files requires the {.pkg flowCore} package (Bioconductor).")
  }
  ff <- flowCore::read.FCS(path, transformation = FALSE)
  tibble::as_tibble(as.data.frame(flowCore::exprs(ff)))
}

#' Read experimental design from CSV or Excel
#'
#' @param path Path to file. `.csv`, `.tsv` and `.xlsx` are
#'   supported.
#' @return A tibble of design information.
#' @export
#' @examples
#' d <- tempfile("cr_design_"); dir.create(d)
#' files <- cr_example_files(d)
#' design_file <- grep("design", files, value = TRUE)[1]
#' design <- cr_read_design(design_file)
#' head(design)
cr_read_design <- function(path) {
  if (!file.exists(path)) cli::cli_abort("File not found: {.path {path}}")
  ext <- tolower(tools::file_ext(path))
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

#' Read CellProfiler output
#'
#' Imports a CellProfiler CSV export and renames the columns to the
#' cellreportR convention (`well`, `x`, `y`, `area`, `circularity`,
#' one column per channel).
#'
#' @param path Path to CellProfiler CSV.
#' @return A tibble with standardised column names.
#' @export
#' @examples
#' d <- tempfile("cr_cp_"); dir.create(d)
#' files <- cr_example_files(d)
#' cp <- cr_read_cellprofiler(file.path(d, "cells_cellprofiler.csv"))
#' head(cp)
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

#' Read QuPath measurement export
#'
#' @param path Path to QuPath TSV.
#' @return A tibble with standardised column names.
#' @export
#' @examples
#' d <- tempfile("cr_qp_"); dir.create(d)
#' files <- cr_example_files(d)
#' qp <- cr_read_qupath(file.path(d, "cells_qupath.tsv"))
#' head(qp)
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

#' Read segmantR output
#'
#' Imports an RDS file produced by the `segmantR` segmentation
#' package. Accepts either a `segmantr_result` list (where cells are
#' in `$cells`) or a plain data frame.
#'
#' @param path Path to RDS file.
#' @return A tibble of cells.
#' @export
#' @examples
#' tmp <- tempfile(fileext = ".rds")
#' df <- cr_example_experiment(seed = 1, n_cells_per_well = 5)$cells
#' saveRDS(df, tmp)
#' cells <- cr_read_segmantr(tmp)
#' head(cells)
cr_read_segmantr <- function(path) {
  .cr_read_rds(path)
}
