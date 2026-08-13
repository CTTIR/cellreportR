# Multi-file ingest of segmented single-cell exports.
#
# One export is one acquisition of one spatial unit, so every row
# carries the provenance of the file it came from. A declarative
# column contract absorbs the differences between vendor exports.


# ---- internal argument checks ---------------------------------------------
# All take `arg` (the argument name as the user wrote it) and `call` (the
# user-facing call environment) so that cli::cli_abort() points at the
# user's code rather than at these helpers.

.cr_arg_string <- function(x,
                           arg = rlang::caller_arg(x),
                           call = rlang::caller_env()) {
  if (!is.character(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    cli::cli_abort(
      c("{.arg {arg}} must be a single non-empty string.",
        "x" = "Got {.cls {class(x)[[1L]]}} of length {length(x)}."),
      call = call
    )
  }
  invisible(x)
}

.cr_arg_flag <- function(x,
                         arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  if (!is.logical(x) || length(x) != 1L || is.na(x)) {
    cli::cli_abort("{.arg {arg}} must be {.code TRUE} or {.code FALSE}.",
                   call = call)
  }
  invisible(x)
}

.cr_arg_dir <- function(x,
                        arg = rlang::caller_arg(x),
                        call = rlang::caller_env()) {
  .cr_arg_string(x, arg = arg, call = call)
  if (!dir.exists(x)) {
    cli::cli_abort(
      c("{.arg {arg}} must be an existing directory.",
        "x" = "{.path {x}} does not exist."),
      call = call
    )
  }
  invisible(x)
}

.cr_arg_named_chr <- function(x,
                              arg = rlang::caller_arg(x),
                              call = rlang::caller_env(),
                              allow_null = TRUE) {
  if (is.null(x)) {
    if (allow_null) return(invisible(NULL))
    cli::cli_abort("{.arg {arg}} must not be {.code NULL}.", call = call)
  }
  if (!is.character(x) || is.null(names(x)) || any(!nzchar(names(x))) ||
      anyNA(x)) {
    cli::cli_abort(
      c("{.arg {arg}} must be a fully named character vector.",
        "i" = "Names are the pattern to look for, values the name to use."),
      call = call
    )
  }
  invisible(x)
}

.cr_arg_cols <- function(x, cols,
                         arg = rlang::caller_arg(x),
                         call = rlang::caller_env()) {
  missing <- setdiff(cols, names(x))
  if (length(missing)) {
    cli::cli_abort(
      c("{.arg {arg}} is missing required column{?s} {.field {missing}}.",
        "i" = "Available: {.field {utils::head(names(x), 10)}}."),
      call = call
    )
  }
  invisible(x)
}

# Lower-case file extension without the dot ("" when there is none).
.cr_path_ext <- function(path) {
  base <- basename(path)
  ext <- regmatches(base, regexpr("\\.([[:alnum:]]+)$", base))
  ext <- sub("^\\.", "", ext)
  if (!length(ext)) "" else tolower(ext)
}

# Drop rows that are NA in every column outside `exclude`.
.cr_drop_empty_rows <- function(x, exclude = character()) {
  cols <- setdiff(names(x), exclude)
  if (!length(cols) || !nrow(x)) return(x)
  keep <- Reduce(`|`, lapply(x[cols], function(col) !is.na(col)))
  x[keep, , drop = FALSE]
}

# ---- column contracts ------------------------------------------------------

#' Declare a column contract for vendor exports
#'
#' Segmented single-cell exports name their columns however the
#' acquisition software happens to. A `cr_column_map` records how those
#' raw headers translate to the analysis names used downstream, so that
#' the mapping lives in one declarative object instead of being spread
#' through reader code.
#'
#' Two matching modes are available because vendor headers are not
#' always stable: `exact` matches a header verbatim, while `prefix`
#' matches a regular expression. Prefix matching exists for headers that
#' embed a unit glyph (an area column ending in a squared-micrometre
#' symbol, for instance), where the exact spelling cannot be relied on.
#'
#' Renaming is deliberately *tolerant*: names that do not occur in a
#' given export are skipped silently rather than raising an error. Exports
#' from the same instrument routinely carry different subsets of the
#' available measurements, and a strict renamer forces a second reader to
#' exist for every subset.
#'
#' @param exact Named character vector. Names are raw header names,
#'   values the analysis name to rename them to.
#' @param prefix Named character vector. Names are regular expressions
#'   matched against the raw header names, values the analysis name. The
#'   first matching column is renamed.
#' @param keep Optional character vector of analysis names to retain
#'   after renaming, in this order. Names that are absent are ignored.
#'   `NULL` keeps every column.
#'
#' @return An object of class `cr_column_map`: a list with elements
#'   `exact`, `prefix` and `keep`.
#'
#' @seealso [cr_read_export()], [cr_read_exports()].
#' @family import
#' @export
#' @examples
#' map <- cr_column_map(
#'   exact = c(
#'     "Event Label" = "cell_id",
#'     "Signal - Mean Intensity" = "target_signal"
#'   ),
#'   prefix = c("^Nuclei - Area" = "area"),
#'   keep = c("cell_id", "target_signal", "area")
#' )
#' map
cr_column_map <- function(exact = NULL, prefix = NULL, keep = NULL) {
  .cr_arg_named_chr(exact)
  .cr_arg_named_chr(prefix)
  if (!is.null(keep) && (!is.character(keep) || anyNA(keep))) {
    cli::cli_abort("{.arg keep} must be a character vector or {.code NULL}.")
  }
  obj <- list(
    exact = exact %||% character(),
    prefix = prefix %||% character(),
    keep = keep
  )
  class(obj) <- c("cr_column_map", "list")
  obj
}

#' @param x A `cr_column_map`.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @rdname cr_column_map
#' @export
print.cr_column_map <- function(x, ...) {
  cli::cli_text("{.cls cr_column_map}")
  cli::cli_bullets(c(
    "*" = "exact rules: {length(x$exact)}",
    "*" = "prefix rules: {length(x$prefix)}",
    "*" = if (is.null(x$keep)) {
      "keep: all columns"
    } else {
      "keep: {length(x$keep)} column{?s}"
    }
  ))
  invisible(x)
}

# Apply a column contract to a freshly read table.
.cr_apply_column_map <- function(x, map, path = NULL,
                                 call = rlang::caller_env()) {
  if (is.null(map)) return(x)
  if (!inherits(map, "cr_column_map")) {
    cli::cli_abort(
      c("{.arg column_map} must be a {.cls cr_column_map}.",
        "i" = "Build one with {.fn cr_column_map}."),
      call = call
    )
  }
  nms <- names(x)
  for (raw in names(map$exact)) {
    j <- which(nms == raw)
    if (length(j)) nms[j[[1L]]] <- map$exact[[raw]]
  }
  for (pat in names(map$prefix)) {
    j <- grep(pat, nms)
    if (length(j)) nms[j[[1L]]] <- map$prefix[[pat]]
  }
  names(x) <- nms
  if (!is.null(map$keep)) {
    x <- x[, intersect(map$keep, names(x)), drop = FALSE]
  }
  dup <- unique(names(x)[duplicated(names(x))])
  if (length(dup)) {
    cli::cli_abort(
      c("Column contract produced duplicated names: {.field {dup}}.",
        "x" = if (!is.null(path)) "In {.path {path}}." else NULL,
        "i" = "Two raw headers map to the same analysis name."),
      call = call
    )
  }
  x
}

# ---- single-file readers ---------------------------------------------------

# Read one tabular file, dispatching on the extension.
.cr_read_table <- function(path, col_types = NULL, sheet = 1L,
                           call = rlang::caller_env()) {
  ext <- .cr_path_ext(path)
  switch(
    ext,
    csv = readr::read_csv(path, col_types = col_types,
                          show_col_types = FALSE, progress = FALSE),
    tsv = readr::read_tsv(path, col_types = col_types,
                          show_col_types = FALSE, progress = FALSE),
    txt = readr::read_tsv(path, col_types = col_types,
                          show_col_types = FALSE, progress = FALSE),
    xls = readxl::read_excel(path, sheet = sheet,
                             col_types = col_types %||% NULL),
    xlsx = readxl::read_excel(path, sheet = sheet,
                              col_types = col_types %||% NULL),
    cli::cli_abort(
      c("Unsupported export format {.val {ext}}.",
        "x" = "In {.path {path}}.",
        "i" = "Supported: {.val csv}, {.val tsv}, {.val txt}, {.val xls}, {.val xlsx}."),
      call = call
    )
  )
}

#' Read one segmented single-cell export
#'
#' Reads a single export file (`.csv`, `.tsv`, `.txt`, `.xls` or
#' `.xlsx`), applies an optional column contract and prepends the file's
#' provenance.
#'
#' Provenance is not optional in this reader. One export is one
#' acquisition of one spatial unit, and export base names repeat across
#' plates, so the *path* — not the file name — identifies the
#' acquisition. Both are carried on every row as `source_file` and
#' `source_path`, and both survive into the analysis unit assignment
#' performed by [cr_assign_units()].
#'
#' Many instruments terminate an export with a single all-blank row.
#' With `drop_empty_rows = TRUE` (the default) such rows are removed
#' rather than carried into the analysis as an all-`NA` cell.
#'
#' @param path Path to the export file.
#' @param column_map Optional [cr_column_map()] describing how raw
#'   headers translate to analysis names.
#' @param drop_empty_rows Logical. Drop rows that are `NA` in every
#'   measurement column. Default `TRUE`.
#' @param col_types Optional column-type specification passed to the
#'   underlying reader (a `readr` column specification for delimited
#'   files, a `readxl` type string such as `"numeric"` for Excel files).
#' @param sheet Sheet name or index for Excel exports. Default `1`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return A tibble of cells with `source_file` and `source_path` as the
#'   first two columns.
#'
#' @seealso [cr_read_exports()] for a whole directory tree,
#'   [cr_column_map()].
#' @family import
#' @export
#' @examples
#' d <- file.path(tempdir(), "cr_export_demo")
#' dir.create(d, showWarnings = FALSE)
#' raw <- data.frame(
#'   "Event Label" = 1:3,
#'   "Signal - Mean Intensity" = c(120, 140, 95),
#'   check.names = FALSE
#' )
#' raw[4, ] <- NA # trailing blank row, as many instruments write
#' f <- file.path(d, "CompoundA_5min_10uM_treated_1.csv")
#' utils::write.csv(raw, f, row.names = FALSE)
#'
#' map <- cr_column_map(
#'   exact = c("Event Label" = "cell_id",
#'             "Signal - Mean Intensity" = "target_signal")
#' )
#' cr_read_export(f, column_map = map)
cr_read_export <- function(path,
                           column_map = NULL,
                           drop_empty_rows = TRUE,
                           col_types = NULL,
                           sheet = 1L,
                           call = rlang::caller_env()) {
  rlang::check_required(path)
  .cr_arg_string(path, call = call)
  .cr_arg_flag(drop_empty_rows, call = call)
  if (!file.exists(path)) {
    cli::cli_abort(c("Export file not found.",
                     "x" = "{.path {path}} does not exist."), call = call)
  }

  raw <- suppressWarnings(
    .cr_read_table(path, col_types = col_types, sheet = sheet, call = call)
  )
  raw <- tibble::as_tibble(raw, .name_repair = "minimal")
  raw <- .cr_apply_column_map(raw, column_map, path = path, call = call)

  out <- tibble::tibble(
    source_file = basename(path),
    source_path = as.character(path)
  )
  out <- dplyr::bind_cols(out[rep(1L, max(nrow(raw), 0L)), , drop = FALSE], raw)
  if (drop_empty_rows) {
    out <- .cr_drop_empty_rows(out, exclude = c("source_file", "source_path"))
  }
  out
}

#' Read a directory tree of segmented single-cell exports
#'
#' Walks a directory recursively, reads every file matching `pattern`
#' with [cr_read_export()] and row-binds the result. Design facts that
#' live in the directory layout and in the file names — rather than
#' inside the files — are recovered by a parser and joined back onto the
#' cells.
#'
#' No naming convention is hardcoded. Either supply a [cr_path_spec()]
#' via `spec`, which is handed to [cr_parse_paths()], or supply an
#' arbitrary `parser` function. A parser receives the character vector of
#' file paths and must return one row per path; if it returns a
#' `source_path` column the join is made on that column, otherwise row
#' order is assumed to match.
#'
#' Row-binding is tolerant of exports that carry different subsets of the
#' available columns: absent columns are filled with `NA`.
#'
#' @param root Directory to walk.
#' @param pattern Regular expression selecting export files. Default
#'   matches `.csv`, `.tsv`, `.xls` and `.xlsx`.
#' @param column_map Optional [cr_column_map()] applied to every export.
#' @param spec Optional [cr_path_spec()] describing the directory and
#'   file-name grammar. Ignored when `parser` is supplied.
#' @param parser Optional function of the file paths returning a tibble
#'   with one row per path.
#' @param recursive Logical. Walk sub-directories. Default `TRUE`.
#' @param drop_empty_rows Logical. Passed to [cr_read_export()].
#' @param col_types Optional column-type specification passed to
#'   [cr_read_export()].
#' @param progress Logical. Show a progress bar while reading. Default
#'   `TRUE`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return A tibble of all cells, with `source_file` and `source_path`
#'   provenance columns and any columns produced by the parser. The paths
#'   that were read are attached as the `"files"` attribute.
#'
#' @seealso [cr_read_export()], [cr_path_spec()], [cr_parse_paths()],
#'   [cr_dataset()].
#' @family import
#' @export
#' @examples
#' # Build a small two-file export tree.
#' root <- file.path(tempdir(), "cr_exports_demo")
#' unlink(root, recursive = TRUE)
#' leaf <- file.path(root, "Run1", "CompoundA", "Plate_1")
#' dir.create(leaf, recursive = TRUE, showWarnings = FALSE)
#' one <- function(n) {
#'   data.frame("Event Label" = seq_len(n),
#'              "Signal - Mean Intensity" = seq_len(n) * 10,
#'              check.names = FALSE)
#' }
#' utils::write.csv(one(3), file.path(leaf, "CompoundA_vehicle_1.csv"),
#'                  row.names = FALSE)
#' utils::write.csv(one(4), file.path(leaf, "CompoundA_5min_10uM_treated_1.csv"),
#'                  row.names = FALSE)
#'
#' spec <- cr_path_spec(
#'   levels = c("run", "compound", "plate"),
#'   grammar = cr_filename_grammar(
#'     tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM"),
#'     defaults = list(interval = "none", dose = "vehicle"),
#'     prefix_strip = "CompoundA"
#'   )
#' )
#' cells <- cr_read_exports(root, spec = spec, progress = FALSE)
#' cells
cr_read_exports <- function(root,
                            pattern = "\\.(csv|tsv|xls|xlsx)$",
                            column_map = NULL,
                            spec = NULL,
                            parser = NULL,
                            recursive = TRUE,
                            drop_empty_rows = TRUE,
                            col_types = NULL,
                            progress = TRUE,
                            call = rlang::caller_env()) {
  rlang::check_required(root)
  .cr_arg_dir(root, call = call)
  .cr_arg_string(pattern, call = call)
  .cr_arg_flag(recursive, call = call)
  .cr_arg_flag(progress, call = call)

  files <- list.files(root, pattern = pattern, recursive = recursive,
                      full.names = TRUE)
  files <- files[!dir.exists(files)]
  if (!length(files)) {
    cli::cli_abort(
      c("No export files found.",
        "x" = "Nothing under {.path {root}} matches {.val {pattern}}.",
        "i" = "Check {.arg pattern} and {.arg recursive}."),
      call = call
    )
  }
  files <- sort(files)

  meta <- NULL
  if (!is.null(parser)) {
    if (!is.function(parser)) {
      cli::cli_abort("{.arg parser} must be a function.", call = call)
    }
    meta <- tibble::as_tibble(parser(files))
  } else if (!is.null(spec)) {
    meta <- cr_parse_paths(files, root = root, spec = spec, call = call)
  }
  if (!is.null(meta)) {
    if (nrow(meta) != length(files)) {
      cli::cli_abort(
        c("The path parser must return one row per file.",
          "x" = "Got {nrow(meta)} row{?s} for {length(files)} file{?s}."),
        call = call
      )
    }
    if (!"source_path" %in% names(meta)) meta$source_path <- files
  }

  if (progress) {
    cli::cli_progress_bar("Reading exports", total = length(files),
                          .envir = rlang::current_env())
  }
  parts <- vector("list", length(files))
  for (i in seq_along(files)) {
    parts[[i]] <- cr_read_export(files[[i]], column_map = column_map,
                                 drop_empty_rows = drop_empty_rows,
                                 col_types = col_types, call = call)
    if (progress) cli::cli_progress_update(.envir = rlang::current_env())
  }
  if (progress) cli::cli_progress_done(.envir = rlang::current_env())

  cells <- dplyr::bind_rows(parts)

  if (!is.null(meta)) {
    drop <- setdiff(intersect(names(meta), names(cells)), "source_path")
    meta <- meta[, setdiff(names(meta), drop), drop = FALSE]
    cells <- dplyr::left_join(cells, meta, by = "source_path")
  }
  attr(cells, "files") <- files
  cells
}

# Version 0.1.0
