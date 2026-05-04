#' Build a `cr_experiment` object
#'
#' Assembles a validated `cr_experiment` from its components. A
#' `cr_experiment` is the central S3 object in cellreportR and holds
#' per-cell measurements, experimental design, channel metadata, plate
#' information, a QC log and arbitrary user metadata.
#'
#' @param cells A data frame / tibble of per-cell measurements. Must
#'   contain a `cell_id` column and a spatial unit column (either
#'   `well` or `slide`).
#' @param design A data frame / tibble that maps each spatial unit to
#'   treatment information. Must contain the spatial unit column and
#'   a `treatment` column. Recommended columns: `dose`, `dose_unit`,
#'   `replicate`, `group`, `timepoint`.
#' @param channels Optional tibble describing fluorescence channels.
#'   Columns: `channel` (required), `role`, `antibody`, `fluorophore`.
#'   If `NULL`, channels are auto-detected from numeric columns in
#'   `cells` that are not recognised as morphology fields.
#' @param plate_info Optional list with plate metadata (e.g. `format`
#'   = "96", `microscope`, `date`, `operator`).
#' @param metadata Optional list with arbitrary user metadata.
#'
#' @return A `cr_experiment` object (an S3 list).
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
#' print(exp)
cr_build_experiment <- function(cells,
                                design,
                                channels = NULL,
                                plate_info = list(),
                                metadata = list()) {
  cells <- tibble::as_tibble(cells)
  design <- tibble::as_tibble(design)

  spatial <- .cr_spatial_unit(cells)

  if (is.null(channels)) {
    channels <- .cr_autodetect_channels(cells)
  } else {
    channels <- tibble::as_tibble(channels)
    if (!"channel" %in% names(channels)) {
      cli::cli_abort("`channels` must contain a {.field channel} column.")
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
    spatial_unit = spatial
  )
  class(obj) <- c("cr_experiment", "list")
  cr_validate_experiment(obj)
  obj
}

#' Validate a `cr_experiment`
#'
#' Performs structural checks on a `cr_experiment`. Called
#' automatically by [cr_build_experiment()] but can also be used to
#' verify that manual modifications have not broken the object.
#'
#' @param x A `cr_experiment`.
#' @return `TRUE` invisibly on success. On failure an informative
#'   error is raised.
#' @export
#' @examples
#' exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
#' cr_validate_experiment(exp)
cr_validate_experiment <- function(x) {
  if (!inherits(x, "cr_experiment")) {
    cli::cli_abort("`x` must be a {.cls cr_experiment}.")
  }
  required <- c("cells", "design", "channels", "plate_info",
                "qc_log", "metadata", "spatial_unit")
  missing <- setdiff(required, names(x))
  if (length(missing)) {
    cli::cli_abort("`cr_experiment` is missing slots: {.field {missing}}")
  }
  spatial <- x$spatial_unit
  if (!spatial %in% names(x$cells)) {
    cli::cli_abort("Cells table is missing spatial unit column {.field {spatial}}.")
  }
  if (!spatial %in% names(x$design)) {
    cli::cli_abort("Design table is missing spatial unit column {.field {spatial}}.")
  }
  if (!"cell_id" %in% names(x$cells)) {
    cli::cli_abort("Cells table is missing {.field cell_id}.")
  }
  if (anyNA(x$cells[[spatial]])) {
    cli::cli_abort("Cells table has NA in {.field {spatial}}.")
  }
  if (anyNA(x$design[[spatial]])) {
    cli::cli_abort("Design table has NA in {.field {spatial}}.")
  }
  if (anyDuplicated(x$design[[spatial]])) {
    cli::cli_abort("Design table has duplicated {.field {spatial}} values.")
  }
  missing_wells <- setdiff(unique(x$cells[[spatial]]), x$design[[spatial]])
  if (length(missing_wells)) {
    cli::cli_abort(c(
      "Design table does not cover all {.field {spatial}} values in cells.",
      "x" = "Missing: {.val {utils::head(missing_wells, 5)}}"
    ))
  }
  if (!"treatment" %in% names(x$design)) {
    cli::cli_abort("Design table must contain a {.field treatment} column.")
  }
  invisible(TRUE)
}

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

# Internal: detect spatial unit column
.cr_spatial_unit <- function(cells) {
  if ("well" %in% names(cells)) {
    "well"
  } else if ("slide" %in% names(cells)) {
    "slide"
  } else {
    cli::cli_abort(
      "Cells table must contain a spatial unit column: {.field well} or {.field slide}."
    )
  }
}

# Internal: auto-detect channels from numeric columns
.cr_autodetect_channels <- function(cells) {
  reserved <- c("cell_id", "well", "slide", "row", "col", "x", "y",
                "area", "perimeter", "circularity", "eccentricity",
                "aspect_ratio", "solidity", "replicate", "field",
                "timepoint")
  num_cols <- names(cells)[vapply(cells, is.numeric, logical(1))]
  chans <- setdiff(num_cols, reserved)
  if (!length(chans)) {
    cli::cli_warn("No fluorescence channel columns detected in cells table.")
    return(tibble::tibble(channel = character(), role = character(),
                          antibody = character(), fluorophore = character()))
  }
  tibble::tibble(
    channel = chans,
    role = "marker",
    antibody = NA_character_,
    fluorophore = NA_character_
  )
}

# Null-coalescing operator (internal).
`%||%` <- function(a, b) if (is.null(a)) b else a
