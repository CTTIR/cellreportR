# The design and data-set constructors.
#
#   cr_design  -- one row per analysis unit, plus the roles its
#                 columns play (unit, treatment, reference, batch).
#   cr_dataset -- freshly ingested cells with their per-file
#                 provenance and, optionally, a design.


#' Build an experimental design object
#'
#' A `cr_design` records both the design table — one row per analysis
#' unit — and the roles its columns play: which column identifies the
#' unit, which holds the treatment, which level of that treatment is the
#' reference, and which columns together define a batch.
#'
#' Recording the roles alongside the table is what lets later stages
#' standardise each cell against the control of *its own* batch rather
#' than against one pooled reference. A batch is normally a combination
#' of columns (compound, run, plate, experiment, pre-treatment interval),
#' which a single batch variable cannot express.
#'
#' `data` may be a per-unit table or a per-cell / per-file table; in the
#' latter case it is collapsed to unique rows. If a unit maps to more
#' than one combination of design values the collapse is ambiguous and
#' the offending columns are named in the error, since silently keeping
#' the first row would invent a design that was never run.
#'
#' @param data A data frame carrying the design columns.
#' @param unit Name of the column identifying the analysis unit. If
#'   `NULL`, the first of `well`, `slide`, `well_id` or `unit` present in
#'   `data` is used.
#' @param treatment Name of the treatment (group) column. Default
#'   `"treatment"`.
#' @param control_level Optional value of `treatment` that is the
#'   reference level, for example the vehicle control.
#' @param batch_vars Optional character vector of columns that together
#'   define a batch.
#' @param levels Optional named list of factor level orders applied to
#'   the corresponding design columns.
#' @param keep Optional character vector of design columns to keep. The
#'   unit column is always kept. `NULL` keeps every column of `data`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return An object of class `cr_design`:
#' \describe{
#'   \item{`table`}{Tibble with one row per analysis unit.}
#'   \item{`unit`}{Name of the unit column.}
#'   \item{`treatment`}{Name of the treatment column.}
#'   \item{`control_level`}{Reference level, or `NULL`.}
#'   \item{`batch_vars`}{Character vector of batch columns.}
#'   \item{`levels`}{The factor level orders that were applied.}
#' }
#'
#' @seealso [cr_dataset()], [cr_build_experiment()], [cr_read_design()].
#' @family constructors
#' @export
#' @examples
#' units <- tibble::tibble(
#'   well = sprintf("A%02d", 1:6),
#'   treatment = rep(c("Vehicle", "CompoundA"), each = 3),
#'   plate = rep(c("Plate_1", "Plate_2"), 3),
#'   replicate = rep(1:3, 2)
#' )
#' design <- cr_design(units, control_level = "Vehicle",
#'                     batch_vars = c("plate"))
#' design
cr_design <- function(data,
                      unit = NULL,
                      treatment = "treatment",
                      control_level = NULL,
                      batch_vars = NULL,
                      levels = list(),
                      keep = NULL,
                      call = rlang::caller_env()) {
  rlang::check_required(data)
  if (!is.data.frame(data)) {
    cli::cli_abort("{.arg data} must be a data frame.", call = call)
  }
  data <- tibble::as_tibble(data)
  unit <- unit %||% .cr_spatial_unit(data, call = call)
  .cr_arg_string(unit, call = call)
  .cr_arg_string(treatment, call = call)
  .cr_arg_cols(data, c(unit, treatment), arg = "data", call = call)
  if (!is.null(batch_vars)) {
    if (!is.character(batch_vars)) {
      cli::cli_abort("{.arg batch_vars} must be a character vector.",
                     call = call)
    }
    .cr_arg_cols(data, batch_vars, arg = "data", call = call)
  }
  if (!is.list(levels)) {
    cli::cli_abort("{.arg levels} must be a named list.", call = call)
  }
  if (length(levels)) {
    .cr_arg_cols(data, names(levels), arg = "data", call = call)
  }

  cols <- if (is.null(keep)) {
    names(data)
  } else {
    union(c(unit, treatment), intersect(keep, names(data)))
  }
  tbl <- dplyr::distinct(data[, cols, drop = FALSE])

  if (anyNA(tbl[[unit]])) {
    cli::cli_abort(
      c("The unit column must not contain missing values.",
        "x" = "{.field {unit}} has {sum(is.na(tbl[[unit]]))} {.code NA} value{?s}."),
      call = call
    )
  }
  if (anyDuplicated(tbl[[unit]])) {
    varying <- vapply(
      setdiff(names(tbl), unit),
      function(nm) {
        any(tapply(tbl[[nm]], tbl[[unit]],
                   function(v) length(unique(v)) > 1L))
      },
      logical(1L)
    )
    cli::cli_abort(
      c("Each unit must map to exactly one design row.",
        "x" = "{.field {names(varying)[varying]}} var{?ies/y} within a unit.",
        "i" = "Restrict the design with {.arg keep}, or resolve the conflict."),
      call = call
    )
  }

  for (nm in names(levels)) {
    lv <- as.character(levels[[nm]])
    obs <- setdiff(unique(as.character(tbl[[nm]])), c(lv, NA))
    if (length(obs)) {
      cli::cli_abort(
        c("{.arg levels} for {.field {nm}} does not cover every value.",
          "x" = "Missing: {.val {obs}}."),
        call = call
      )
    }
    tbl[[nm]] <- factor(as.character(tbl[[nm]]), levels = lv)
  }

  if (!is.null(control_level)) {
    control_level <- as.character(control_level)
    .cr_arg_string(control_level, call = call)
    if (!control_level %in% as.character(tbl[[treatment]])) {
      cli::cli_abort(
        c("{.arg control_level} must be a value of {.field {treatment}}.",
          "x" = "{.val {control_level}} does not occur.",
          "i" = "Observed: {.val {unique(as.character(tbl[[treatment]]))}}."),
        call = call
      )
    }
  }

  obj <- list(
    table = tbl,
    unit = unit,
    treatment = treatment,
    control_level = control_level,
    batch_vars = batch_vars %||% character(),
    levels = levels
  )
  class(obj) <- c("cr_design", "list")
  obj
}

#' @param x A `cr_design`.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @rdname cr_design
#' @export
print.cr_design <- function(x, ...) {
  cli::cli_h3("cr_design")
  cli::cli_bullets(c(
    "*" = "units: {nrow(x$table)} (column {.field {x$unit}})",
    "*" = "treatment: {.field {x$treatment}} with
           {length(unique(as.character(x$table[[x$treatment]])))} level{?s}",
    "*" = "reference: {.val {x$control_level %||% 'not set'}}",
    "*" = "batch: {if (length(x$batch_vars))
           paste(x$batch_vars, collapse = ' x ') else 'not set'}"
  ))
  invisible(x)
}

# ---- dataset ---------------------------------------------------------------

# One row per source file: cell count plus every column that is constant
# within each file (i.e. the design facts recovered at ingest).
.cr_provenance <- function(cells, file_col = "source_path") {
  if (!file_col %in% names(cells)) return(NULL)
  files <- as.character(cells[[file_col]])
  candidates <- setdiff(names(cells), file_col)
  constant <- vapply(candidates, function(nm) {
    all(tapply(cells[[nm]], files, function(v) length(unique(v)) == 1L))
  }, logical(1L))
  keep <- names(constant)[constant]
  first <- !duplicated(files)
  out <- tibble::as_tibble(cells[first, c(file_col, keep), drop = FALSE])
  out$n_cells <- as.integer(table(files)[out[[file_col]]])
  out[order(out[[file_col]]), , drop = FALSE]
}

#' Build an ingested data set
#'
#' A `cr_dataset` is what comes out of ingest: the cells of every export,
#' the per-file provenance that lets any row be traced back to the
#' acquisition it came from, and optionally the design those files
#' encode. It is the object to inspect before committing to an analysis,
#' and it converts to a `cr_experiment` with [cr_build_experiment()].
#'
#' @param cells A data frame of cells, typically from
#'   [cr_read_exports()].
#' @param design Optional [cr_design()] object, or a data frame that is
#'   passed to [cr_design()].
#' @param unit_var Name of the analysis unit column. Defaults to the
#'   design's unit column, or the first of `well`, `slide`, `well_id` or
#'   `unit` present in `cells`.
#' @param provenance Optional per-file table. When `NULL` it is derived
#'   from `cells`: one row per file with its cell count and every column
#'   that is constant within the file.
#' @param file_col Name of the file column used for provenance. Default
#'   `"source_path"`.
#' @param metadata Optional list of arbitrary user metadata.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return An object of class `cr_dataset`:
#' \describe{
#'   \item{`cells`}{Tibble of per-cell measurements.}
#'   \item{`provenance`}{Tibble with one row per source file, or `NULL`.}
#'   \item{`design`}{A `cr_design`, or `NULL`.}
#'   \item{`unit_var`}{Name of the analysis unit column, or `NULL`.}
#'   \item{`metadata`}{List of user metadata.}
#' }
#'
#' @seealso [cr_read_exports()], [cr_design()], [cr_build_experiment()].
#' @family constructors
#' @export
#' @examples
#' cells <- tibble::tibble(
#'   source_path = rep(c("a.csv", "b.csv"), each = 3),
#'   source_file = rep(c("a.csv", "b.csv"), each = 3),
#'   well = rep(c("A01", "A02"), each = 3),
#'   treatment = rep(c("Vehicle", "CompoundA"), each = 3),
#'   target_signal = c(10, 12, 11, 30, 33, 29)
#' )
#' ds <- cr_dataset(cells)
#' ds
#' ds$provenance
cr_dataset <- function(cells,
                       design = NULL,
                       unit_var = NULL,
                       provenance = NULL,
                       file_col = "source_path",
                       metadata = list(),
                       call = rlang::caller_env()) {
  rlang::check_required(cells)
  if (!is.data.frame(cells)) {
    cli::cli_abort("{.arg cells} must be a data frame.", call = call)
  }
  cells <- tibble::as_tibble(cells)
  .cr_arg_string(file_col, call = call)

  if (!is.null(design) && !inherits(design, "cr_design")) {
    if (!is.data.frame(design)) {
      cli::cli_abort(
        c("{.arg design} must be a {.cls cr_design} or a data frame.",
          "i" = "Build one with {.fn cr_design}."),
        call = call
      )
    }
    design <- cr_design(design, unit = unit_var, call = call)
  }

  if (is.null(unit_var)) {
    unit_var <- if (!is.null(design)) {
      design$unit
    } else {
      tryCatch(.cr_spatial_unit(cells, call = call), error = function(e) NULL)
    }
  } else {
    .cr_arg_cols(cells, unit_var, arg = "cells", call = call)
  }

  if (is.null(provenance)) {
    provenance <- .cr_provenance(cells, file_col = file_col)
  } else if (!is.data.frame(provenance)) {
    cli::cli_abort("{.arg provenance} must be a data frame or {.code NULL}.",
                   call = call)
  } else {
    provenance <- tibble::as_tibble(provenance)
  }

  obj <- list(
    cells = cells,
    provenance = provenance,
    design = design,
    unit_var = unit_var,
    metadata = as.list(metadata)
  )
  class(obj) <- c("cr_dataset", "list")
  obj
}

#' @param x A `cr_dataset`.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @rdname cr_dataset
#' @export
print.cr_dataset <- function(x, ...) {
  cli::cli_h3("cr_dataset")
  cli::cli_bullets(c(
    "*" = "cells: {format(nrow(x$cells), big.mark = ',')} x {ncol(x$cells)}",
    "*" = "source files: {if (is.null(x$provenance)) 'unknown' else nrow(x$provenance)}",
    "*" = "unit column: {.field {x$unit_var %||% 'not set'}}",
    "*" = "units: {if (is.null(x$unit_var)) NA else length(unique(x$cells[[x$unit_var]]))}",
    "*" = "design: {if (is.null(x$design)) 'not set' else 'set'}"
  ))
  invisible(x)
}

#' @param object A `cr_dataset`.
#' @return A tibble with one row per source file, or `NULL` when the data
#'   set carries no provenance.
#' @rdname cr_dataset
#' @export
summary.cr_dataset <- function(object, ...) {
  object$provenance
}

# Version 0.1.0
