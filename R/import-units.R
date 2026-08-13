# Resolving files to analysis units.
#
# The unit of replication is the spatial unit (the well), not the file
# and not the cell, and the file-to-unit map is not the identity: some
# files are two halves of one unit, some are repeated reads of a unit
# that already exists, and some look like both but are genuinely
# separate units. Everything that decides which is which lives here.

#' Declare how files are merged into analysis units
#'
#' States which replicate suffixes and marker flags mean "these files are
#' one unit" and which mean "these files are different units". Getting
#' this wrong is silent in both directions, so each rule is explicit.
#'
#' * `merge_suffix` matches the replicate index of a file that is the
#'   *second pass* over a unit that already exists. Left unmerged, such a
#'   unit draws a full cell allocation twice and is double-weighted in
#'   its own batch.
#' * `merge_marker` names a logical column (typically produced by
#'   [cr_extract_markers()]) that must also be `TRUE` before a suffix
#'   match is merged. Requiring the marker is the conservative default:
#'   a suffix on its own is not evidence.
#' * `keep_separate` matches replicate indices that look mergeable but
#'   are a different physical unit. It always wins over `merge_suffix`.
#'   [cr_centroid_overlap()] is the evidence test for deciding which of
#'   the two a given suffix is.
#' * `reacquisition` names the logical column marking a repeated read.
#'   With `merge_reacquisition = TRUE` such a file folds into its plain
#'   sibling; otherwise `separate_suffix` is appended so it stays a unit
#'   of its own.
#'
#' @param merge_suffix Regular expression matched against the replicate
#'   index, marking a second acquisition pass. `NULL` disables.
#' @param merge_marker Name of a logical column that must be `TRUE` for a
#'   `merge_suffix` match to merge, or `NULL` to merge on the suffix
#'   alone. When the column is absent no suffix merging happens.
#' @param keep_separate Regular expression matched against the replicate
#'   index, marking indices that must never merge. `NULL` disables.
#' @param reacquisition Name of a logical column marking repeated reads,
#'   or `NULL`.
#' @param merge_reacquisition Logical. Fold repeated reads into their
#'   plain sibling. Default `TRUE`.
#' @param separate_suffix Suffix appended to the replicate index of a
#'   repeated read when `merge_reacquisition = FALSE`. Default `"re"`.
#'
#' @return An object of class `cr_merge_rules` (a list).
#'
#' @seealso [cr_assign_units()], [cr_extract_markers()],
#'   [cr_centroid_overlap()].
#' @family import
#' @export
#' @examples
#' cr_merge_rules()
#' cr_merge_rules(merge_marker = NULL, keep_separate = NULL)
cr_merge_rules <- function(merge_suffix = "\\.1$",
                           merge_marker = "merge_unit",
                           keep_separate = "\\.2$",
                           reacquisition = "reacquisition",
                           merge_reacquisition = TRUE,
                           separate_suffix = "re") {
  for (nm in c("merge_suffix", "merge_marker", "keep_separate",
               "reacquisition")) {
    val <- get(nm, inherits = FALSE)
    if (!is.null(val)) .cr_arg_string(val, arg = nm)
  }
  .cr_arg_flag(merge_reacquisition)
  .cr_arg_string(separate_suffix)
  obj <- list(
    merge_suffix = merge_suffix,
    merge_marker = merge_marker,
    keep_separate = keep_separate,
    reacquisition = reacquisition,
    merge_reacquisition = merge_reacquisition,
    separate_suffix = separate_suffix
  )
  class(obj) <- c("cr_merge_rules", "list")
  obj
}

#' @param x A `cr_merge_rules`.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @rdname cr_merge_rules
#' @export
print.cr_merge_rules <- function(x, ...) {
  cli::cli_text("{.cls cr_merge_rules}")
  cli::cli_bullets(c(
    "*" = "merge suffix: {.val {x$merge_suffix %||% 'disabled'}}",
    "*" = "gated on marker: {.val {x$merge_marker %||% 'no'}}",
    "*" = "kept separate: {.val {x$keep_separate %||% 'disabled'}}",
    "*" = "merge repeated reads: {x$merge_reacquisition}"
  ))
  invisible(x)
}

#' Assign cells to analysis units
#'
#' Derives the identifier of the analysis unit — the spatial unit that is
#' the unit of replication — for every row of a cell table, merging the
#' files that belong to the same unit according to a [cr_merge_rules()]
#' set.
#'
#' The unit identifier is the combination of `key_vars` and the merged
#' replicate index. Files that share it are one unit; files that do not
#' are separate replicates. Because a unit may be assembled from more
#' than one file, [cr_unit_map()] should be used afterwards to see which
#' units were merged and from how many files.
#'
#' @param x A data frame of cells (or of files) carrying the design
#'   columns and a replicate index.
#' @param key_vars Character vector of column names that, together with
#'   the replicate index, identify one unit.
#' @param replicate_var Name of the replicate index column. Default
#'   `"replicate"`.
#' @param rules A [cr_merge_rules()] object.
#' @param id_col Name of the unit identifier column to add. Default
#'   `"well_id"`.
#' @param sep Separator used to build the identifier. Default `"|"`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return `x` with two columns added: `replicate_merged` (the replicate
#'   index after merging) and the unit identifier named by `id_col`. The
#'   number of units is attached as the `"n_units"` attribute.
#'
#' @seealso [cr_unit_map()], [cr_merge_rules()],
#'   [cr_centroid_overlap()].
#' @family import
#' @export
#' @examples
#' files <- tibble::tibble(
#'   compound = "CompoundA",
#'   plate = "Plate_1",
#'   mode = "treated",
#'   replicate = c("1", "1.1", "2", "2.2"),
#'   merge_unit = c(FALSE, TRUE, FALSE, FALSE),
#'   reacquisition = FALSE
#' )
#' units <- cr_assign_units(files, key_vars = c("compound", "plate", "mode"))
#' units[, c("replicate", "replicate_merged", "well_id")]
cr_assign_units <- function(x,
                            key_vars,
                            replicate_var = "replicate",
                            rules = cr_merge_rules(),
                            id_col = "well_id",
                            sep = "|",
                            call = rlang::caller_env()) {
  rlang::check_required(x)
  rlang::check_required(key_vars)
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a data frame.", call = call)
  }
  if (!is.character(key_vars) || !length(key_vars)) {
    cli::cli_abort("{.arg key_vars} must be a non-empty character vector.",
                   call = call)
  }
  if (!inherits(rules, "cr_merge_rules")) {
    cli::cli_abort(
      c("{.arg rules} must be a {.cls cr_merge_rules}.",
        "i" = "Build one with {.fn cr_merge_rules}."),
      call = call
    )
  }
  .cr_arg_string(replicate_var, call = call)
  .cr_arg_string(id_col, call = call)
  .cr_arg_string(sep, call = call)
  .cr_arg_cols(x, c(key_vars, replicate_var), arg = "x", call = call)

  out <- tibble::as_tibble(x)
  rep_raw <- as.character(out[[replicate_var]])
  rep_merged <- rep_raw

  separate <- rep(FALSE, length(rep_raw))
  if (!is.null(rules$keep_separate)) {
    separate <- !is.na(rep_raw) & grepl(rules$keep_separate, rep_raw)
  }

  if (!is.null(rules$merge_suffix)) {
    hit <- !is.na(rep_raw) & grepl(rules$merge_suffix, rep_raw) & !separate
    if (!is.null(rules$merge_marker)) {
      if (rules$merge_marker %in% names(out)) {
        hit <- hit & !is.na(out[[rules$merge_marker]]) &
          as.logical(out[[rules$merge_marker]])
      } else {
        if (any(hit)) {
          cli::cli_inform(c(
            "!" = paste("No {.field {rules$merge_marker}} column: files",
                        "matching {.val {rules$merge_suffix}} were left",
                        "unmerged."),
            "i" = "Pass {.code merge_marker = NULL} to merge on the suffix alone."
          ))
        }
        hit <- rep(FALSE, length(rep_raw))
      }
    }
    rep_merged[hit] <- sub(rules$merge_suffix, "", rep_raw[hit])
  }

  if (!is.null(rules$reacquisition) && !rules$merge_reacquisition &&
      rules$reacquisition %in% names(out)) {
    flag <- !is.na(out[[rules$reacquisition]]) &
      as.logical(out[[rules$reacquisition]])
    rep_merged[flag] <- paste0(rep_merged[flag], "_", rules$separate_suffix)
  }

  key_values <- lapply(key_vars, function(v) as.character(out[[v]]))
  key_values[[length(key_values) + 1L]] <- rep_merged
  ids <- do.call(paste, c(key_values, list(sep = sep)))

  out$replicate_merged <- rep_merged
  out[[id_col]] <- ids
  attr(out, "n_units") <- length(unique(ids))
  out
}

#' Map source files to analysis units
#'
#' Summarises which file contributed how many cells to which unit, and
#' flags the units that were assembled from more than one file. This is
#' the post-condition check for [cr_assign_units()]: a unit built from
#' several files should be one you can name and justify.
#'
#' @param x A cell table carrying a unit identifier and a file column,
#'   as returned by [cr_assign_units()].
#' @param id_col Name of the unit identifier column. Default
#'   `"well_id"`.
#' @param file_col Name of the file column. Default `"source_path"`;
#'   the path rather than the base name, because base names repeat
#'   across plates.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return A tibble with one row per file: the unit identifier, the file,
#'   `n_cells`, `n_files` (files contributing to that unit) and `merged`
#'   (`TRUE` when `n_files > 1`).
#'
#' @seealso [cr_assign_units()].
#' @family import
#' @export
#' @examples
#' cells <- tibble::tibble(
#'   source_path = rep(c("a.csv", "b.csv", "c.csv"), times = c(3, 2, 4)),
#'   compound = "CompoundA",
#'   replicate = rep(c("1", "1.1", "2"), times = c(3, 2, 4)),
#'   merge_unit = rep(c(FALSE, TRUE, FALSE), times = c(3, 2, 4))
#' )
#' units <- cr_assign_units(cells, key_vars = "compound")
#' cr_unit_map(units)
cr_unit_map <- function(x,
                        id_col = "well_id",
                        file_col = "source_path",
                        call = rlang::caller_env()) {
  rlang::check_required(x)
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a data frame.", call = call)
  }
  .cr_arg_string(id_col, call = call)
  .cr_arg_string(file_col, call = call)
  .cr_arg_cols(x, c(id_col, file_col), arg = "x", call = call)

  tbl <- dplyr::summarise(
    dplyr::group_by(tibble::as_tibble(x),
                    dplyr::across(dplyr::all_of(c(id_col, file_col)))),
    n_cells = dplyr::n(),
    .groups = "drop"
  )
  tbl <- dplyr::mutate(
    dplyr::group_by(tbl, dplyr::across(dplyr::all_of(id_col))),
    n_files = dplyr::n()
  )
  tbl <- dplyr::ungroup(tbl)
  tbl$merged <- tbl$n_files > 1L
  dplyr::arrange(tbl, dplyr::across(dplyr::all_of(c(id_col, file_col))))
}

#' Centroid overlap between two candidate units
#'
#' Answers the question a mergeable-looking replicate suffix raises: are
#' these two files two passes over the same physical unit, or two
#' different units? Two passes over one unit share their segmentation
#' centroids; two different units share essentially none.
#'
#' @param x A cell table carrying a unit identifier and centroid columns.
#' @param unit_a,unit_b The two unit identifiers to compare.
#' @param coords Length-2 character vector naming the centroid columns.
#'   Default `c("x", "y")`.
#' @param tol Numeric matching tolerance in centroid units. Default `1`.
#' @param id_col Name of the unit identifier column. Default
#'   `"well_id"`.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return A single number: the fraction of cells in the smaller unit
#'   that have a centroid within `tol` of a centroid in the other unit.
#'   The cell counts and the number of matches are attached as the
#'   `"n_a"`, `"n_b"` and `"n_matched"` attributes.
#'
#' @seealso [cr_assign_units()], [cr_merge_rules()].
#' @family import
#' @export
#' @examples
#' cells <- tibble::tibble(
#'   well_id = rep(c("u1", "u2"), each = 4),
#'   x = c(1, 2, 3, 4, 1, 2, 3, 90),
#'   y = c(1, 2, 3, 4, 1, 2, 3, 90)
#' )
#' # u1 and u2 share three of four centroids:
#' cr_centroid_overlap(cells, "u1", "u2")
cr_centroid_overlap <- function(x,
                                unit_a,
                                unit_b,
                                coords = c("x", "y"),
                                tol = 1,
                                id_col = "well_id",
                                call = rlang::caller_env()) {
  rlang::check_required(x)
  rlang::check_required(unit_a)
  rlang::check_required(unit_b)
  if (!is.data.frame(x)) {
    cli::cli_abort("{.arg x} must be a data frame.", call = call)
  }
  if (!is.character(coords) || length(coords) != 2L) {
    cli::cli_abort("{.arg coords} must name exactly two columns.",
                   call = call)
  }
  if (!is.numeric(tol) || length(tol) != 1L || is.na(tol) || tol <= 0) {
    cli::cli_abort("{.arg tol} must be a single positive number.",
                   call = call)
  }
  .cr_arg_string(id_col, call = call)
  .cr_arg_cols(x, c(id_col, coords), arg = "x", call = call)

  ids <- as.character(x[[id_col]])
  a <- x[ids == unit_a, coords, drop = FALSE]
  b <- x[ids == unit_b, coords, drop = FALSE]
  if (!nrow(a) || !nrow(b)) {
    cli::cli_abort(
      c("Both units must have cells.",
        "x" = "{.val {unit_a}}: {nrow(a)} cell{?s}; {.val {unit_b}}: {nrow(b)} cell{?s}."),
      call = call
    )
  }

  ax <- as.numeric(a[[1L]])
  ay <- as.numeric(a[[2L]])
  bx <- as.numeric(b[[1L]])
  by <- as.numeric(b[[2L]])

  # Bin both units onto a grid of side `tol`, so that a match can only
  # sit in the point's own cell or one of the eight around it. This
  # keeps the search linear in the number of cells; the candidates are
  # then distance-tested exactly.
  cell_a <- cbind(floor(ax / tol), floor(ay / tol))
  cell_b <- cbind(floor(bx / tol), floor(by / tol))
  keys_b <- paste(cell_b[, 1L], cell_b[, 2L], sep = ",")
  lookup <- list2env(split(seq_along(keys_b), keys_b),
                     envir = new.env(parent = emptyenv(), hash = TRUE))

  offsets <- expand.grid(dx = -1:1, dy = -1:1)
  matched <- vapply(seq_along(ax), function(i) {
    cand <- integer()
    for (j in seq_len(nrow(offsets))) {
      key <- paste(cell_a[i, 1L] + offsets$dx[[j]],
                   cell_a[i, 2L] + offsets$dy[[j]], sep = ",")
      if (exists(key, envir = lookup, inherits = FALSE)) {
        cand <- c(cand, get(key, envir = lookup, inherits = FALSE))
      }
    }
    if (!length(cand)) return(FALSE)
    any(sqrt((bx[cand] - ax[[i]])^2 + (by[cand] - ay[[i]])^2) <= tol)
  }, logical(1L))

  frac <- sum(matched) / min(nrow(a), nrow(b))
  frac <- min(frac, 1)
  attr(frac, "n_a") <- nrow(a)
  attr(frac, "n_b") <- nrow(b)
  attr(frac, "n_matched") <- sum(matched)
  frac
}

# Version 0.1.0
