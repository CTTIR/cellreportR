# Path specifications.
#
# Where a file sits carries design facts that are nowhere inside it.
# A cr_path_spec bundles the meaning of each directory level with the
# file-name grammar and the marker rules, so that no naming
# convention is baked into the readers.

# Escape a literal string for use inside a regular expression.
.cr_regex_escape <- function(x) {
  gsub("([][{}()+*^$|\\\\?.])", "\\\\\\1", x)
}

# Directory components of `paths` below `root`, one character vector per
# path, excluding the file name itself.
.cr_rel_parts <- function(paths, root) {
  norm <- function(p) gsub("\\\\", "/", p)
  root_n <- sub("/+$", "", norm(normalizePath(root, winslash = "/",
                                              mustWork = FALSE)))
  paths_n <- norm(normalizePath(paths, winslash = "/", mustWork = FALSE))
  lapply(paths_n, function(p) {
    rel <- if (startsWith(p, paste0(root_n, "/"))) {
      substring(p, nchar(root_n) + 2L)
    } else {
      base_root <- basename(root_n)
      parts <- strsplit(p, "/", fixed = TRUE)[[1L]]
      hit <- which(parts == base_root)
      if (length(hit)) {
        paste(parts[seq(hit[[length(hit)]] + 1L, length(parts))],
              collapse = "/")
      } else {
        basename(p)
      }
    }
    parts <- strsplit(rel, "/", fixed = TRUE)[[1L]]
    if (length(parts) <= 1L) character() else parts[-length(parts)]
  })
}

# Resolve one file's directory components against a level specification.
.cr_level_values <- function(parts, levels) {
  if (is.character(levels)) {
    nms <- levels
    idx <- seq_along(levels)
  } else {
    nms <- names(levels)
    idx <- as.integer(levels)
  }
  keep <- !is.na(nms) & nzchar(nms)
  nms <- nms[keep]
  idx <- idx[keep]
  vals <- vapply(idx, function(k) {
    j <- if (k < 0L) length(parts) + 1L + k else k
    if (j >= 1L && j <= length(parts)) parts[[j]] else NA_character_
  }, character(1L))
  stats::setNames(as.list(vals), nms)
}



#' Bundle a directory and file-name specification
#'
#' A `cr_path_spec` holds everything needed to recover design facts from
#' where a file sits and what it is called: the meaning of each directory
#' level, the file-name grammar, the marker rules and whether an
#' unparseable name is an error.
#'
#' @param levels Either an unnamed character vector naming the directory
#'   levels below the root in order (use `NA` or `""` to skip a level),
#'   or a named integer vector mapping column names to level indices,
#'   where negative indices count back from the file (`-1` is the
#'   directory containing the file).
#' @param grammar A [cr_filename_grammar()], or `NULL`.
#' @param markers A [cr_marker_rules()] object, or `NULL`.
#' @param strict Logical. Treat a file name that does not match the
#'   grammar as an error. Default `TRUE`.
#'
#' @return An object of class `cr_path_spec` (a list).
#'
#' @seealso [cr_parse_paths()], [cr_read_exports()].
#' @family import
#' @export
#' @examples
#' spec <- cr_path_spec(
#'   levels = c(run = 1L, compound = 2L, plate = -1L),
#'   grammar = cr_filename_grammar(
#'     tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM")
#'   ),
#'   markers = cr_marker_rules(merge_unit = "\\(split\\)")
#' )
#' spec
cr_path_spec <- function(levels = NULL,
                         grammar = NULL,
                         markers = NULL,
                         strict = TRUE) {
  if (!is.null(levels)) {
    if (is.character(levels)) {
      if (!is.null(names(levels))) {
        cli::cli_abort(
          c("{.arg levels} given as names must be unnamed.",
            "i" = "Use a named {.cls integer} vector for index mapping.")
        )
      }
    } else if (is.numeric(levels)) {
      if (is.null(names(levels)) || any(!nzchar(names(levels)))) {
        cli::cli_abort("A numeric {.arg levels} must be fully named.")
      }
    } else {
      cli::cli_abort(
        "{.arg levels} must be a character or named integer vector."
      )
    }
  }
  if (!is.null(grammar) && !inherits(grammar, "cr_filename_grammar")) {
    cli::cli_abort(
      c("{.arg grammar} must be a {.cls cr_filename_grammar}.",
        "i" = "Build one with {.fn cr_filename_grammar}.")
    )
  }
  if (!is.null(markers) && !inherits(markers, "cr_marker_rules")) {
    cli::cli_abort(
      c("{.arg markers} must be a {.cls cr_marker_rules}.",
        "i" = "Build one with {.fn cr_marker_rules}.")
    )
  }
  .cr_arg_flag(strict)
  obj <- list(levels = levels, grammar = grammar, markers = markers,
              strict = strict)
  class(obj) <- c("cr_path_spec", "list")
  obj
}

#' @param x A `cr_path_spec`.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @rdname cr_path_spec
#' @export
print.cr_path_spec <- function(x, ...) {
  lv <- if (is.null(x$levels)) {
    "<none>"
  } else if (is.character(x$levels)) {
    paste(x$levels, collapse = " / ")
  } else {
    paste(sprintf("%s[%d]", names(x$levels), as.integer(x$levels)),
          collapse = " / ")
  }
  gr <- if (is.null(x$grammar)) {
    "none"
  } else {
    paste(names(x$grammar$tokens), collapse = ", ")
  }
  mk <- if (is.null(x$markers)) "none" else "set"
  cli::cli_text("{.cls cr_path_spec}")
  cli::cli_bullets(c(
    "*" = "levels: {lv}",
    "*" = "grammar tokens: {gr}",
    "*" = "markers: {mk}",
    "*" = "strict: {x$strict}"
  ))
  invisible(x)
}

#' Parse design facts out of export paths
#'
#' Turns a vector of export paths into one row of design information per
#' file: the directory levels below `root`, the file-name markers, the
#' replicate index and the grammar tokens.
#'
#' With `strict = TRUE` (the default) a file name that matches no
#' `core_patterns` entry of the grammar aborts the parse. That is the
#' intended behaviour: a name that parses to defaults instead of failing
#' loudly can move a treated unit into a control arm without anything in
#' the analysis noticing.
#'
#' @param paths Character vector of file paths.
#' @param root Directory the paths sit under. Required when `levels` is
#'   given.
#' @param levels Directory level specification; see [cr_path_spec()].
#' @param grammar A [cr_filename_grammar()], or `NULL`.
#' @param markers A [cr_marker_rules()] object, or `NULL`.
#' @param strict Logical. Abort on an unparseable file name. When `spec`
#'   is supplied and `strict` is not, the spec's setting is used.
#' @param spec Optional [cr_path_spec()] supplying any of `levels`,
#'   `grammar`, `markers` and `strict` that are not given directly.
#' @param call The execution environment of the calling function. Used
#'   for error reporting; experts only.
#'
#' @return A tibble with one row per path: `source_file`, `source_path`,
#'   one column per directory level, the marker flag columns, `variant`,
#'   `core`, `replicate`, one column per grammar token, and the
#'   `parse_ok` / `parse_error` outcome.
#'
#' @seealso [cr_path_spec()], [cr_filename_grammar()],
#'   [cr_marker_rules()], [cr_read_exports()].
#' @family import
#' @export
#' @examples
#' root <- file.path(tempdir(), "cr_paths_demo")
#' paths <- file.path(
#'   root, "Run1", "CompoundA", "Plate_1",
#'   c("CompoundA_vehicle_1.csv", "CompoundA_5min_10uM_treated_1.csv")
#' )
#' cr_parse_paths(
#'   paths,
#'   root = root,
#'   levels = c("run", "compound", "plate"),
#'   grammar = cr_filename_grammar(
#'     tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM"),
#'     defaults = list(interval = "none", dose = "vehicle"),
#'     prefix_strip = "CompoundA"
#'   )
#' )
cr_parse_paths <- function(paths,
                           root = NULL,
                           levels = NULL,
                           grammar = NULL,
                           markers = NULL,
                           strict = TRUE,
                           spec = NULL,
                           call = rlang::caller_env()) {
  rlang::check_required(paths)
  if (!is.character(paths) || !length(paths)) {
    cli::cli_abort("{.arg paths} must be a non-empty character vector.",
                   call = call)
  }
  if (!is.null(spec)) {
    if (!inherits(spec, "cr_path_spec")) {
      cli::cli_abort(
        c("{.arg spec} must be a {.cls cr_path_spec}.",
          "i" = "Build one with {.fn cr_path_spec}."),
        call = call
      )
    }
    if (is.null(levels)) levels <- spec$levels
    if (is.null(grammar)) grammar <- spec$grammar
    if (is.null(markers)) markers <- spec$markers
    if (missing(strict)) strict <- spec$strict
  }
  .cr_arg_flag(strict, call = call)
  if (!is.null(levels) && is.null(root)) {
    cli::cli_abort(
      c("{.arg root} is required when {.arg levels} is given.",
        "i" = "Levels are counted from {.arg root} downwards."),
      call = call
    )
  }

  out <- tibble::tibble(
    source_file = basename(paths),
    source_path = as.character(paths)
  )

  lvl_names <- character()
  if (!is.null(levels)) {
    lvl_names <- if (is.character(levels)) {
      levels[!is.na(levels) & nzchar(levels)]
    } else {
      names(levels)
    }
    parts <- .cr_rel_parts(paths, root)
    vals <- lapply(parts, .cr_level_values, levels = levels)
    for (nm in lvl_names) {
      out[[nm]] <- vapply(vals, function(v) v[[nm]], character(1L))
    }
  }

  stems <- sub("\\.[[:alnum:]]+$", "", basename(paths))
  container_col <- if (!length(lvl_names)) {
    NULL
  } else if ("plate" %in% lvl_names) {
    "plate"
  } else {
    lvl_names[[length(lvl_names)]]
  }
  containers <- if (!is.null(container_col) && container_col %in% names(out)) {
    out[[container_col]]
  } else {
    rep(NA_character_, length(paths))
  }

  rules <- markers %||% cr_marker_rules()
  marked <- lapply(seq_along(stems), function(i) {
    .cr_markers_one(stems[[i]], containers[[i]], rules)
  })
  for (flag in .cr_marker_flags) {
    out[[flag]] <- vapply(marked, function(m) m$flags[[flag]], logical(1L))
  }
  out$variant <- vapply(marked, function(m) m$variant, character(1L))
  stems <- vapply(marked, function(m) m$stem, character(1L))

  if (!is.null(grammar)) {
    parsed <- lapply(stems, .cr_grammar_parse, grammar = grammar)
    out$core <- vapply(parsed, function(p) p$core, character(1L))
    out$replicate <- vapply(parsed, function(p) p$replicate, character(1L))
    for (nm in names(grammar$tokens)) {
      out[[nm]] <- vapply(parsed, function(p) p$tokens[[nm]], character(1L))
    }
    out$parse_ok <- vapply(parsed, function(p) p$parse_ok, logical(1L))
    out$parse_error <- vapply(parsed, function(p) p$parse_error,
                              character(1L))
  } else {
    out$core <- stems
    out$replicate <- NA_character_
    out$parse_ok <- TRUE
    out$parse_error <- NA_character_
  }

  if (strict && any(!out$parse_ok)) {
    bad <- out$source_file[!out$parse_ok]
    cli::cli_abort(
      c("{sum(!out$parse_ok)} file name{?s} {?does/do} not match the grammar.",
        "x" = "{.file {utils::head(bad, 5)}}",
        "i" = paste("Extend {.arg core_patterns} only after confirming what",
                    "the file is; do not let it fall through to defaults."),
        "i" = "Use {.code strict = FALSE} to collect failures instead."),
      call = call
    )
  }
  out
}

# Version 0.1.0
