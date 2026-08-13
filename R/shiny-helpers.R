# Non-reactive helpers backing the Shiny application. Everything here is
# an ordinary function of ordinary data, so the app's logic can be unit
# tested without a Shiny session. Anything that is analysis rather than
# plumbing is delegated to the package's exported functions.


# DT wrapper carrying the app's table defaults.
.cr_dt <- function(data, page = 10L, selection = "none", editable = FALSE) {
  DT::datatable(
    data,
    rownames = FALSE,
    selection = selection,
    editable = editable,
    options = list(scrollX = TRUE, pageLength = page)
  )
}


# Placeholder panel used wherever a figure cannot be drawn yet.
.cr_app_blank_plot <- function(message) {
  ggplot2::ggplot() +
    ggplot2::annotate("text", x = 0, y = 0, label = message,
                      size = 4.2, colour = "grey30") +
    ggplot2::theme_void()
}


# Example data for the "Load example data" button. Prefers a screen-shaped
# example when the package provides one and falls back to the single-plate
# example otherwise.
.cr_app_example <- function(seed = 42, n_cells_per_well = 60) {
  screen <- get0("cr_example_screen", envir = asNamespace("cellreportR"),
                 mode = "function")
  if (!is.null(screen)) {
    out <- tryCatch(screen(seed = seed), error = function(e) NULL)
    if (inherits(out, "cr_experiment")) {
      return(out)
    }
  }
  cr_example_experiment(seed = seed, n_cells_per_well = n_cells_per_well)
}


# Read one uploaded export, whatever the on-disk format. Uploads arrive
# under a temporary name, so the format is taken from the label the
# browser sent rather than from the temporary path.
.cr_app_read_one <- function(path, label = path) {
  ext <- tolower(tools::file_ext(label))
  if (ext %in% c("xlsx", "xls")) {
    return(tibble::as_tibble(readxl::read_excel(path)))
  }
  fmt <- switch(ext, csv = "csv", tsv = "tsv", txt = "tsv", rds = "rds",
                NULL)
  tibble::as_tibble(cr_read_cells(path, format = fmt))
}


# Read a set of uploads and stack them, keeping per-file provenance. One
# export is one acquisition and base names repeat across plates, so the
# file name is kept next to the path it came from.
.cr_app_read_files <- function(paths, labels = paths) {
  if (!length(paths)) {
    cli::cli_abort("No files to read.")
  }
  if (length(labels) != length(paths)) {
    cli::cli_abort("{.arg labels} must be as long as {.arg paths}.")
  }
  parts <- lapply(seq_along(paths), function(i) {
    tbl <- .cr_app_read_one(paths[[i]], labels[[i]])
    tbl$source_file <- basename(labels[[i]])
    tbl$source_path <- labels[[i]]
    tbl
  })
  .cr_app_prepare_cells(dplyr::bind_rows(parts))
}


# Directory ingest. Uses the package's multi-file reader, which carries
# provenance and tolerates exports with different column subsets, and
# falls back to reading each file in turn if that reader rejects the
# tree (for example an unsupported vendor layout).
.cr_app_read_dir <- function(root,
                             pattern = "\\.(csv|tsv|txt|xls|xlsx)$",
                             recursive = TRUE) {
  out <- tryCatch(
    cr_read_exports(root, pattern = pattern, recursive = recursive,
                    progress = FALSE),
    error = function(e) e
  )
  if (is.data.frame(out) && nrow(out)) {
    return(.cr_app_prepare_cells(out))
  }
  files <- list.files(root, pattern = pattern, recursive = recursive,
                      full.names = TRUE, ignore.case = TRUE)
  files <- files[!dir.exists(files)]
  if (!length(files)) {
    cli::cli_abort(c(
      "No files matching {.val {pattern}} under {.path {root}}.",
      i = "Adjust the file pattern or untick the sub-directory search."
    ))
  }
  .cr_app_read_files(sort(files))
}


# Guarantee the one column cr_build_experiment() insists on.
.cr_app_prepare_cells <- function(cells) {
  cells <- tibble::as_tibble(cells)
  if (!"cell_id" %in% names(cells) || anyNA(cells$cell_id) ||
      anyDuplicated(cells$cell_id)) {
    cells$cell_id <- sprintf("c%07d", seq_len(nrow(cells)))
  }
  cells
}


# Columns that can plausibly identify an acquisition unit: anything
# discrete with more than one and fewer than n values.
.cr_app_unit_choices <- function(cells) {
  if (is.null(cells) || !ncol(cells)) {
    return(character(0))
  }
  ok <- vapply(cells, function(v) {
    (is.character(v) || is.factor(v) || is.integer(v)) &&
      dplyr::n_distinct(v) > 1L &&
      dplyr::n_distinct(v) < nrow(cells)
  }, logical(1))
  nms <- names(cells)[ok]
  nms <- setdiff(nms, "cell_id")
  preferred <- intersect(c("well", "slide", "well_id", "unit", "source_file"),
                         nms)
  unique(c(preferred, nms))
}


# Promote a chosen column to the spatial unit cr_build_experiment()
# recognises, leaving the original column in place.
.cr_app_set_unit <- function(cells, column) {
  if (is.null(column) || !nzchar(column) || !column %in% names(cells)) {
    return(cells)
  }
  if (column %in% c("well", "slide")) {
    cells[[column]] <- as.character(cells[[column]])
    return(cells)
  }
  cells$well <- as.character(cells[[column]])
  cells
}


# One design row per spatial unit, with placeholder levels the user then
# edits or assigns in the Design tab.
.cr_app_design_skeleton <- function(cells) {
  unit <- intersect(c("well", "slide"), names(cells))
  if (!length(unit)) {
    cli::cli_abort(c(
      "Cells table has no spatial unit column.",
      "x" = "Expected a {.field well} or {.field slide} column.",
      i = "Pick the column identifying one acquisition and derive again."
    ))
  }
  unit <- unit[[1L]]
  units <- sort(unique(as.character(cells[[unit]])))
  out <- tibble::tibble(
    unit = units,
    treatment = "untreated",
    dose = 0,
    dose_unit = "",
    group = "control",
    replicate = seq_along(units)
  )
  names(out)[1] <- unit
  out
}


# Column names holding the estimate and its interval for one method of a
# cr_effect_grid() result. The grid is wide (`cohens_d`,
# `cohens_d_ci_low`, ...); a long table with a `method` column is
# accepted as well.
.cr_app_effect_columns <- function(effects, method = "cohens_d") {
  nms <- names(effects)
  if (method %in% nms) {
    return(list(
      estimate = method,
      ci_low = if (paste0(method, "_ci_low") %in% nms) {
        paste0(method, "_ci_low")
      } else {
        NA_character_
      },
      ci_high = if (paste0(method, "_ci_high") %in% nms) {
        paste0(method, "_ci_high")
      } else {
        NA_character_
      }
    ))
  }
  list(
    estimate = if ("estimate" %in% nms) "estimate" else NA_character_,
    ci_low = if ("ci_low" %in% nms) "ci_low" else NA_character_,
    ci_high = if ("ci_high" %in% nms) "ci_high" else NA_character_
  )
}


# Effect-size methods a grid actually carries, for the method picker.
.cr_app_effect_methods <- function(effects) {
  if (is.null(effects)) {
    return(character(0))
  }
  if ("method" %in% names(effects)) {
    return(unique(as.character(effects$method)))
  }
  known <- c("cohens_d", "hedges_g", "cliffs_delta", "rank_biserial",
             "glass_delta")
  intersect(known, names(effects))
}


# Label column of a grid: the contrast, or whatever identifies a row.
.cr_app_effect_label <- function(effects) {
  hit <- intersect(c("contrast", "group", "treatment", "compound", "term"),
                   names(effects))
  if (length(hit)) hit[[1L]] else NA_character_
}

# Version 0.1.0
