# File-name markers.
#
# Short annotations on a file or its directory change the analysis.
# The rules below turn each one into a typed flag.


#' Declare how parenthetical file-name markers are interpreted
#'
#' Acquisition software and operators annotate exports with short
#' markers, and those markers change the analysis. A `cr_marker_rules`
#' object states which regular expression means what, so that a marker
#' becomes a typed flag instead of a string somebody has to remember.
#'
#' The distinctions the rules encode are deliberate:
#'
#' * `merge_unit` sits on a **file** and means one spatial unit was
#'   acquired in two passes. The two files are one unit and must be
#'   merged before any per-unit balancing, or the unit contributes twice
#'   the cells of its neighbours.
#' * `partial_plate` sits on a **container** (the plate directory) and
#'   means a partly filled plate. It has no downstream consequence.
#'   Collapsing the two into one flag hides the one that matters, so they
#'   are matched against different strings.
#' * `omitted_reagent` marks the specificity arm, where the detection
#'   reagent was left out. These acquisitions are never samples.
#' * `reacquisition` marks a repeated read of a unit that already has a
#'   plain sibling file.
#' * `lot` marks a different reagent lot. A lot marker is *not* an
#'   omitted-reagent control; pooling the two inverts the meaning of the
#'   arm.
#'
#' Any trailing parenthetical that matches none of the rules is captured
#' verbatim into a `variant` column when `capture_unknown = TRUE`, rather
#' than being guessed at or silently dropped.
#'
#' @param merge_unit Regular expression marking a file as one half of a
#'   two-pass acquisition, or `NULL`.
#' @param partial_plate Regular expression matched against the container
#'   (directory) name, or `NULL`.
#' @param omitted_reagent Regular expression marking the specificity arm,
#'   or `NULL`.
#' @param reacquisition Regular expression marking a repeated read, or
#'   `NULL`.
#' @param lot Regular expression marking a reagent lot, or `NULL`.
#' @param capture_unknown Logical. Capture an unmatched trailing
#'   parenthetical into `variant`. Default `TRUE`.
#' @param ignore_case Logical. Match case-insensitively. Default `TRUE`.
#'
#' @return An object of class `cr_marker_rules` (a list).
#'
#' @seealso [cr_extract_markers()], [cr_parse_paths()],
#'   [cr_merge_rules()].
#' @family import
#' @export
#' @examples
#' rules <- cr_marker_rules(
#'   merge_unit = "\\(split\\)",
#'   partial_plate = "\\(partial\\)",
#'   omitted_reagent = "\\(no reagent\\)",
#'   reacquisition = "\\(repeat\\)",
#'   lot = "\\(lot[A-Z]\\)"
#' )
#' rules
cr_marker_rules <- function(merge_unit = NULL,
                            partial_plate = NULL,
                            omitted_reagent = NULL,
                            reacquisition = NULL,
                            lot = NULL,
                            capture_unknown = TRUE,
                            ignore_case = TRUE) {
  for (nm in c("merge_unit", "partial_plate", "omitted_reagent",
               "reacquisition", "lot")) {
    val <- get(nm, inherits = FALSE)
    if (!is.null(val)) .cr_arg_string(val, arg = nm)
  }
  .cr_arg_flag(capture_unknown)
  .cr_arg_flag(ignore_case)
  obj <- list(
    merge_unit = merge_unit,
    partial_plate = partial_plate,
    omitted_reagent = omitted_reagent,
    reacquisition = reacquisition,
    lot = lot,
    capture_unknown = capture_unknown,
    ignore_case = ignore_case
  )
  class(obj) <- c("cr_marker_rules", "list")
  obj
}

# Marker names that are matched against the file name, in strip order.
.cr_marker_name_rules <- c("merge_unit", "omitted_reagent", "reacquisition",
                           "lot")

# Flag columns always produced by the marker extractor.
.cr_marker_flags <- c("merge_unit", "partial_plate", "omitted_reagent",
                      "reacquisition", "lot")

# Extract markers from one name / container pair.
.cr_markers_one <- function(name, container = NA_character_,
                            rules = cr_marker_rules()) {
  flags <- stats::setNames(
    rep(FALSE, length(.cr_marker_flags)), .cr_marker_flags
  )
  stem <- name
  ic <- isTRUE(rules$ignore_case)
  for (nm in .cr_marker_name_rules) {
    pat <- rules[[nm]]
    if (is.null(pat)) next
    if (grepl(pat, stem, ignore.case = ic)) {
      flags[[nm]] <- TRUE
      stem <- sub(pat, "", stem, ignore.case = ic)
    }
  }
  if (!is.null(rules$partial_plate) && !is.na(container)) {
    flags[["partial_plate"]] <- grepl(rules$partial_plate, container,
                                      ignore.case = ic)
  }
  variant <- NA_character_
  if (isTRUE(rules$capture_unknown)) {
    hit <- regmatches(stem, regexpr("\\(([^)]+)\\)[[:space:]]*$", stem))
    if (length(hit)) {
      # The class must be [()[:space:]]: a class written with an escape
      # sequence silently deletes letters from the captured marker.
      variant <- gsub("[()[:space:]]", "", hit)
      stem <- sub("[[:space:]]*\\([^)]+\\)[[:space:]]*$", "", stem)
    }
  }
  stem <- trimws(gsub("[[:space:]]+", " ", stem))
  list(flags = flags, variant = variant, stem = stem)
}

#' Extract file-name markers into typed flags
#'
#' Applies a [cr_marker_rules()] set to a table that carries a file-name
#' column, adding one logical column per rule plus a character `variant`
#' column holding any unmatched trailing parenthetical.
#'
#' @param x A data frame with one row per file (or per cell).
#' @param name_col Name of the column holding the file name. Default
#'   `"source_file"`.
#' @param container_col Optional name of the column holding the container
#'   (plate or directory) name that `partial_plate` is matched against.
#' @param rules A [cr_marker_rules()] object.
#' @param stem_col Optional name of a column to write the marker-stripped
#'   name into.
#' @param strip_ext Logical. Remove a trailing file extension before
#'   matching. Default `TRUE`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return `x` with the columns `merge_unit`, `partial_plate`,
#'   `omitted_reagent`, `reacquisition`, `lot` (all logical) and
#'   `variant` (character) added. Columns for rules that were not
#'   supplied are `FALSE` throughout.
#'
#' @seealso [cr_marker_rules()], [cr_parse_paths()].
#' @family import
#' @export
#' @examples
#' files <- tibble::tibble(
#'   source_file = c("CompoundA_10uM_treated_1.csv",
#'                   "CompoundA_10uM_treated_1.1 (split).csv",
#'                   "CompoundA_vehicle_1 (no reagent).csv",
#'                   "CompoundA_vehicle_2 (weekend).csv"),
#'   plate = c("Plate_1", "Plate_1", "Plate_1", "Plate_2 (partial)")
#' )
#' cr_extract_markers(
#'   files,
#'   container_col = "plate",
#'   rules = cr_marker_rules(merge_unit = "\\(split\\)",
#'                           partial_plate = "\\(partial\\)",
#'                           omitted_reagent = "\\(no reagent\\)")
#' )
cr_extract_markers <- function(x,
                               name_col = "source_file",
                               container_col = NULL,
                               rules = cr_marker_rules(),
                               stem_col = NULL,
                               strip_ext = TRUE,
                               call = rlang::caller_env()) {
  rlang::check_required(x)
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a data frame.", call = call)
  }
  .cr_arg_string(name_col, call = call)
  .cr_arg_flag(strip_ext, call = call)
  if (!inherits(rules, "cr_marker_rules")) {
    cli::cli_abort(
      c("{.arg rules} must be a {.cls cr_marker_rules}.",
        "i" = "Build one with {.fn cr_marker_rules}."),
      call = call
    )
  }
  .cr_arg_cols(x, name_col, arg = "x", call = call)
  if (!is.null(container_col)) {
    .cr_arg_cols(x, container_col, arg = "x", call = call)
  }

  nms <- as.character(x[[name_col]])
  if (strip_ext) nms <- sub("\\.[[:alnum:]]+$", "", nms)
  containers <- if (is.null(container_col)) {
    rep(NA_character_, length(nms))
  } else {
    as.character(x[[container_col]])
  }

  parsed <- lapply(seq_along(nms), function(i) {
    .cr_markers_one(nms[[i]], containers[[i]], rules)
  })
  out <- tibble::as_tibble(x)
  for (flag in .cr_marker_flags) {
    out[[flag]] <- vapply(parsed, function(p) p$flags[[flag]], logical(1L))
  }
  out$variant <- vapply(parsed, function(p) p$variant, character(1L))
  if (!is.null(stem_col)) {
    out[[stem_col]] <- vapply(parsed, function(p) p$stem, character(1L))
  }
  out
}

# Version 0.1.0
