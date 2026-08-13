# The cr_experiment constructor and validator.
#
# cr_experiment is the analysis object the rest of the package works
# on: cells, design, channels, QC log, provenance and metadata.


#' Build a `cr_experiment` object
#'
#' Assembles a validated `cr_experiment` from its components. A
#' `cr_experiment` is the central S3 object in cellreportR and holds
#' per-cell measurements, experimental design, channel metadata, plate
#' information, a QC log and arbitrary user metadata.
#'
#' Three optional slots describe structure that a single design table
#' cannot: `unit_var` names the analysis unit when it is neither `well`
#' nor `slide` (a unit assembled from several files, for instance),
#' `batch_vars` names the *combination* of columns that defines a batch,
#' and `provenance` keeps the per-file record that lets any cell be
#' traced back to its acquisition. `set_aside` holds arms that were split
#' out of the analysis pool, such as a specificity control, so that they
#' travel with the experiment instead of being lost.
#'
#' @param cells A data frame / tibble of per-cell measurements, or a
#'   [cr_dataset()]. Must contain a `cell_id` column and a spatial unit
#'   column (`well`, `slide`, `well_id` or `unit`, or the column named by
#'   `unit_var`).
#' @param design A data frame / tibble that maps each spatial unit to
#'   treatment information, or a [cr_design()] object. Must contain the
#'   spatial unit column and a `treatment` column. Recommended columns:
#'   `dose`, `dose_unit`, `replicate`, `group`, `timepoint`. May be
#'   `NULL` when `cells` is a `cr_dataset` carrying a design.
#' @param channels Optional tibble describing marker channels.
#'   Columns: `channel` (required), `role`, `target`, `fluorophore`.
#'   If `NULL`, channels are auto-detected from numeric columns in
#'   `cells` that are not recognised as morphology fields.
#' @param plate_info Optional list with plate metadata (e.g. `format`
#'   = "96", `microscope`, `date`, `operator`).
#' @param metadata Optional list with arbitrary user metadata.
#' @param unit_var Optional name of the analysis unit column.
#' @param batch_vars Optional character vector of columns that together
#'   define a batch.
#' @param provenance Optional per-file provenance table.
#' @param set_aside Optional data frame or list of arms split out of the
#'   analysis pool.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return A `cr_experiment` object (an S3 list).
#' @seealso [cr_validate_experiment()], [cr_dataset()], [cr_design()].
#' @family constructors
#' @export
#' @examples
#' cells <- tibble::tibble(
#'   cell_id = sprintf("c%03d", 1:6),
#'   well = rep(c("A01", "A02"), each = 3),
#'   area = c(120, 130, 125, 118, 122, 131),
#'   target_signal = c(10, 12, 11, 30, 33, 29)
#' )
#' design <- tibble::tibble(
#'   well = c("A01", "A02"),
#'   treatment = c("Vehicle", "CompoundA"),
#'   plate = "Plate_1"
#' )
#' exp <- cr_build_experiment(cells, design, batch_vars = "plate")
#' exp
cr_build_experiment <- function(cells,
                                design = NULL,
                                channels = NULL,
                                plate_info = list(),
                                metadata = list(),
                                unit_var = NULL,
                                batch_vars = NULL,
                                provenance = NULL,
                                set_aside = NULL,
                                call = rlang::caller_env()) {
  rlang::check_required(cells)

  if (inherits(cells, "cr_dataset")) {
    ds <- cells
    cells <- ds$cells
    design <- design %||% ds$design
    unit_var <- unit_var %||% ds$unit_var
    provenance <- provenance %||% ds$provenance
    if (!length(metadata)) metadata <- ds$metadata
  }

  cells <- tibble::as_tibble(cells)

  if (inherits(design, "cr_design")) {
    dsg <- design
    design <- dsg$table
    unit_var <- unit_var %||% dsg$unit
    batch_vars <- batch_vars %||% dsg$batch_vars
    if (!identical(dsg$treatment, "treatment") &&
        !"treatment" %in% names(design)) {
      # The rest of the package looks for a column called `treatment`.
      design$treatment <- design[[dsg$treatment]]
    }
  }
  if (is.null(design)) {
    cli::cli_abort(
      c("{.arg design} is required.",
        "i" = "Supply a design table, a {.fn cr_design}, or a
               {.fn cr_dataset} that carries one."),
      call = call
    )
  }
  design <- tibble::as_tibble(design)

  spatial <- unit_var %||% .cr_spatial_unit(cells, call = call)

  if (is.null(channels)) {
    channels <- .cr_autodetect_channels(cells)
  } else {
    channels <- tibble::as_tibble(channels)
    if (!"channel" %in% names(channels)) {
      cli::cli_abort("`channels` must contain a {.field channel} column.",
                     call = call)
    }
    if (!"role" %in% names(channels)) {
      channels$role <- "marker"
    }
  }

  obj <- list(
    cells = cells,
    design = design,
    channels = channels,
    plate_info = as.list(plate_info),
    qc_log = tibble::tibble(
      step = character(),
      parameters = character(),
      cells_before = integer(),
      cells_after = integer(),
      cells_removed = integer(),
      percent_removed = numeric(),
      timestamp = as.POSIXct(character())
    ),
    metadata = as.list(metadata),
    spatial_unit = spatial,
    unit_var = spatial,
    batch_vars = batch_vars %||% character(),
    provenance = provenance,
    set_aside = set_aside
  )
  class(obj) <- c("cr_experiment", "list")
  cr_validate_experiment(obj, call = call)
  obj
}

#' Validate a `cr_experiment`
#'
#' Performs structural checks on a `cr_experiment`. Called
#' automatically by [cr_build_experiment()] but can also be used to
#' verify that manual modifications have not broken the object.
#'
#' The optional `unit_var`, `batch_vars`, `provenance` and `set_aside`
#' slots are checked only when they are present, so that objects built by
#' earlier versions still validate.
#'
#' @param x A `cr_experiment`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#' @return `TRUE` invisibly on success. On failure an informative
#'   error is raised.
#' @seealso [cr_build_experiment()].
#' @family constructors
#' @export
#' @examples
#' cells <- tibble::tibble(
#'   cell_id = c("c1", "c2"), well = c("A01", "A02"),
#'   target_signal = c(10, 20)
#' )
#' design <- tibble::tibble(well = c("A01", "A02"),
#'                          treatment = c("Vehicle", "CompoundA"))
#' cr_validate_experiment(cr_build_experiment(cells, design))
cr_validate_experiment <- function(x, call = rlang::caller_env()) {
  if (!inherits(x, "cr_experiment")) {
    cli::cli_abort("`x` must be a {.cls cr_experiment}.", call = call)
  }
  required <- c("cells", "design", "channels", "plate_info",
                "qc_log", "metadata", "spatial_unit")
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    cli::cli_abort("`cr_experiment` is missing slots: {.field {missing}}",
                   call = call)
  }
  spatial <- x$spatial_unit
  if (!spatial %in% names(x$cells)) {
    cli::cli_abort(
      "Cells table is missing spatial unit column {.field {spatial}}.",
      call = call
    )
  }
  if (!spatial %in% names(x$design)) {
    cli::cli_abort(
      "Design table is missing spatial unit column {.field {spatial}}.",
      call = call
    )
  }
  if (!"cell_id" %in% names(x$cells)) {
    cli::cli_abort("Cells table is missing {.field cell_id}.", call = call)
  }
  if (anyNA(x$cells[[spatial]])) {
    cli::cli_abort("Cells table has NA in {.field {spatial}}.", call = call)
  }
  if (anyNA(x$design[[spatial]])) {
    cli::cli_abort("Design table has NA in {.field {spatial}}.", call = call)
  }
  if (anyDuplicated(x$design[[spatial]])) {
    cli::cli_abort("Design table has duplicated {.field {spatial}} values.",
                   call = call)
  }
  missing_units <- setdiff(unique(x$cells[[spatial]]), x$design[[spatial]])
  if (length(missing_units)) {
    cli::cli_abort(c(
      "Design table does not cover all {.field {spatial}} values in cells.",
      "x" = "Missing: {.val {utils::head(missing_units, 5)}}"
    ), call = call)
  }
  if (!"treatment" %in% names(x$design)) {
    cli::cli_abort("Design table must contain a {.field treatment} column.",
                   call = call)
  }
  if (!is.null(x$unit_var) && !identical(x$unit_var, spatial)) {
    cli::cli_abort(c(
      "{.field unit_var} and {.field spatial_unit} disagree.",
      "x" = "{.val {x$unit_var}} vs {.val {spatial}}."
    ), call = call)
  }
  if (length(x$batch_vars %||% character())) {
    known <- unique(c(names(x$design), names(x$cells)))
    unknown <- setdiff(x$batch_vars, known)
    if (length(unknown)) {
      cli::cli_abort(c(
        "{.field batch_vars} must name design or cell columns.",
        "x" = "Not found: {.field {unknown}}."
      ), call = call)
    }
  }
  if (!is.null(x$provenance) && !is.data.frame(x$provenance)) {
    cli::cli_abort("{.field provenance} must be a data frame or NULL.",
                   call = call)
  }
  invisible(TRUE)
}

# ---- internal constructors -------------------------------------------------

# Internal constructor for cr_result
.cr_new_result <- function(comparison,
                           cell_level = NULL,
                           rep_level = NULL,
                           effect_sizes = NULL,
                           fold_change = NULL,
                           roc = NULL,
                           model = NULL) {
  empty_tbl <- tibble::tibble()
  obj <- list(
    comparison = comparison,
    cell_level = cell_level %||% empty_tbl,
    rep_level = rep_level %||% empty_tbl,
    effect_sizes = effect_sizes %||% empty_tbl,
    fold_change = fold_change %||% empty_tbl,
    roc = roc,
    model = model
  )
  class(obj) <- c("cr_result", "list")
  obj
}

# Internal constructor for cr_report
.cr_new_report <- function(experiment,
                           results = list(),
                           summary = tibble::tibble(),
                           plots = list(),
                           metadata = list(),
                           params = list()) {
  obj <- list(
    experiment = experiment,
    results = results,
    summary = summary,
    plots = plots,
    metadata = metadata,
    params = params
  )
  class(obj) <- c("cr_report", "list")
  obj
}

# Internal: detect the spatial unit column
.cr_spatial_unit <- function(cells, call = rlang::caller_env()) {
  candidates <- c("well", "slide", "well_id", "unit")
  hit <- candidates[candidates %in% names(cells)]
  if (length(hit)) return(hit[[1L]])
  cli::cli_abort(
    c("No spatial unit column found.",
      "x" = "Expected one of {.field {candidates}}.",
      "i" = "Name it explicitly with {.arg unit_var}, or derive one with
             {.fn cr_assign_units}."),
    call = call
  )
}

# Internal: auto-detect channels from numeric columns
.cr_autodetect_channels <- function(cells) {
  reserved <- c("cell_id", "well", "slide", "well_id", "unit", "row", "col",
                "x", "y", "area", "perimeter", "circularity", "eccentricity",
                "aspect_ratio", "solidity", "replicate", "replicate_merged",
                "field", "timepoint", "n_cells", "n_files")
  num_cols <- names(cells)[vapply(cells, is.numeric, logical(1))]
  chans <- setdiff(num_cols, reserved)
  if (!length(chans)) {
    cli::cli_warn("No marker channel columns detected in cells table.")
    return(tibble::tibble(channel = character(), role = character(),
                          target = character(), fluorophore = character()))
  }
  tibble::tibble(
    channel = chans,
    role = "marker",
    target = NA_character_,
    fluorophore = NA_character_
  )
}

# Null-coalescing operator (internal).
`%||%` <- function(a, b) if (is.null(a)) b else a

# Version 0.1.0
