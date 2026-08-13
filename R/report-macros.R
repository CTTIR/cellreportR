#' Emit named values as a generated include file
#'
#' Writes every number a write-up quotes into one machine-generated
#' file, so the text can reference the value by name instead of
#' repeating the digits. A number that lives in exactly one place
#' cannot disagree with itself: re-run the analysis, re-emit the file,
#' and the document is current. Splicing an estimate from one run
#' beside an interval from another stops being possible.
#'
#' LaTeX control sequences may contain letters only, so names are
#' transliterated by [cr_macro_name()] — `"CompoundA_5min"` becomes
#' `\CompoundAfivemin`. Two source names that transliterate to the same
#' macro are an error rather than a silent overwrite.
#'
#' @param values A named list or named atomic vector of scalars. Nested
#'   named lists are flattened, joining the names.
#' @param file Output path. When `NULL` the formatted lines are
#'   returned instead of being written.
#' @param format `"tex"` (default) writes `\newcommand` definitions
#'   with presentation-formatted values; `"json"` and `"yaml"` write
#'   the underlying values, rounded but otherwise raw, for
#'   downstream tools.
#' @param prefix Optional prefix prepended to every name. A prefix is
#'   worth setting for `"tex"` output: it keeps generated names clear
#'   of the commands LaTeX already defines, such as `\label` or
#'   `\date`, which cannot be redefined with `\newcommand`.
#' @param header Optional character vector of header lines. `NULL`
#'   emits a default "generated file, do not edit" banner; `character()`
#'   emits none.
#' @param digits Decimal places used when formatting numbers. Counts —
#'   integers, and round values of 1000 or more — are written without
#'   decimals and with `big_mark` separators.
#' @param big_mark Thousands separator used in `"tex"` output.
#' @param na Placeholder for non-finite values in `"tex"` output.
#' @return The output path (invisibly), or a character vector of lines
#'   when `file` is `NULL`.
#' @seealso [cr_macros_from()] to derive the values from a report,
#'   [cr_macro_name()], [cr_format_number()], [cr_enumerate()].
#' @family macros
#' @export
#' @examples
#' vals <- list(cells_analyzed = 128400L, units_analyzed = 96L,
#'              top_estimate = 1.42, top_ci_low = 0.55)
#' cat(cr_macros(vals, file = NULL), sep = "\n")
#'
#' f <- tempfile(fileext = ".tex")
#' cr_macros(vals, f, prefix = "screen")
#' cat(readLines(f)[1:2], sep = "\n")
cr_macros <- function(values,
                      file,
                      format = c("tex", "json", "yaml"),
                      prefix = NULL,
                      header = NULL,
                      digits = 3,
                      big_mark = ",",
                      na = "--") {
  format <- match.arg(format)
  flat <- .cr_flatten_values(values)
  if (!length(flat)) {
    cli::cli_abort("{.arg values} is empty; nothing to emit.")
  }
  nms <- cr_macro_name(names(flat), prefix = prefix)
  dup <- duplicated(nms)
  if (any(dup)) {
    cli::cli_abort(c(
      "Macro name{?s} {.val {unique(nms[dup])}} would be defined more than once.",
      "i" = "Names are letters only, so {.val {names(flat)[dup]}} collided with an earlier entry."
    ))
  }

  if (is.null(header)) header <- .cr_macro_header(format)
  body <- switch(
    format,
    tex = vapply(seq_along(flat), function(i) {
      sprintf("\\newcommand{\\%s}{%s}", nms[i],
              .cr_macro_value(flat[[i]], digits = digits,
                              big_mark = big_mark, na = na))
    }, character(1)),
    json = .cr_macro_json(nms, flat, digits),
    yaml = vapply(seq_along(flat), function(i) {
      sprintf("%s: %s", nms[i], .cr_macro_scalar(flat[[i]], digits))
    }, character(1))
  )
  lines <- c(header, body)
  if (is.null(file)) return(lines)

  .cr_check_path(file)
  .cr_ensure_dir(dirname(file))
  writeLines(lines, file)
  invisible(file)
}

#' Derive generated numbers from a report or a results table
#'
#' Walks an assembled report (or any table of contrasts) and turns it
#' into the named values [cr_macros()] emits: the disposition counts,
#' one entry per contrast and numeric column, and the enumerations that
#' a sentence would otherwise state by hand — which intervals exclude
#' the null, and how many. Enumerations are the entries most worth
#' generating, because a hand-typed list is wrong as soon as one row of
#' the analysis changes.
#'
#' @param x A `cr_report`, or a data frame with one row per contrast.
#' @param file Output path, or `NULL` to return the lines.
#' @param label_cols Character vector naming the columns that identify
#'   a row. `NULL` (default) picks the first available of `group`,
#'   `compound`, `treatment`, `term`, `name`, together with `contrast`
#'   or `comparison` when present.
#' @param ci Names of the lower and upper confidence-bound columns,
#'   used for the "excludes zero" enumerations. `NULL` disables them.
#' @param ... Passed to [cr_macros()] (`format`, `prefix`, `digits`, ...).
#' @return The output path (invisibly), or a character vector of lines
#'   when `file` is `NULL`.
#' @seealso [cr_macros()].
#' @family macros
#' @export
#' @examples
#' eff <- data.frame(
#'   group = c("CompoundA", "CompoundB", "CompoundC"),
#'   estimate = c(1.42, 0.31, -0.88),
#'   ci_low = c(0.55, -0.10, -1.60),
#'   ci_high = c(2.29, 0.72, -0.16)
#' )
#' cat(cr_macros_from(eff, file = NULL), sep = "\n")
cr_macros_from <- function(x, file, label_cols = NULL,
                           ci = c("ci_low", "ci_high"), ...) {
  values <- list()
  tbl <- NULL

  if (inherits(x, "cr_report")) {
    disp <- x$tables$disposition
    if (is.data.frame(disp) && nrow(disp)) {
      total <- disp[nrow(disp), , drop = FALSE]
      values$n_units <- total$n_units[[1L]]
      values$n_cells <- total$n_cells[[1L]]
    }
    values$n_results <- length(x$results)
    tbl <- if (!is.null(x$effects)) x$effects else x$summary
  } else if (is.data.frame(x)) {
    tbl <- x
  } else {
    cli::cli_abort(c(
      "{.arg x} must be a {.cls cr_report} or a data frame.",
      "x" = "Got {.cls {class(x)[[1L]]}}."
    ))
  }

  if (is.data.frame(tbl) && nrow(tbl)) {
    tbl <- tibble::as_tibble(tbl)
    if (is.null(label_cols)) label_cols <- .cr_label_cols(tbl)
    labels <- .cr_row_labels(tbl, label_cols)
    num_cols <- names(tbl)[vapply(tbl, is.numeric, logical(1))]
    for (col in num_cols) {
      for (i in seq_len(nrow(tbl))) {
        values[[paste0(labels[i], "_", col)]] <- tbl[[col]][i]
      }
    }
    chr_cols <- setdiff(
      names(tbl)[vapply(tbl, function(v) is.character(v) || is.factor(v),
                        logical(1))],
      label_cols
    )
    for (col in chr_cols) {
      for (i in seq_len(nrow(tbl))) {
        values[[paste0(labels[i], "_", col)]] <- as.character(tbl[[col]][i])
      }
    }
    if (!is.null(ci) && length(ci) == 2L && all(ci %in% names(tbl))) {
      lo <- tbl[[ci[[1L]]]]
      hi <- tbl[[ci[[2L]]]]
      excl <- !is.na(lo) & !is.na(hi) & sign(lo) == sign(hi)
      values$excludes_zero <- cr_enumerate(labels[excl])
      values$n_excludes_zero <- sum(excl)
      values$n_contrasts <- nrow(tbl)
    }
  }

  cr_macros(values, file = file, ...)
}

#' Build a macro-safe name
#'
#' Turns a label into an identifier that a LaTeX control sequence
#' accepts: letters only, with digits spelled out and every other
#' character dropped. `"CompoundA_5min"` becomes `"CompoundAfivemin"`.
#'
#' @param x Character vector of labels.
#' @param prefix Optional prefix, transliterated the same way.
#' @return A character vector of the same length as `x`.
#' @seealso [cr_macros()].
#' @family macros
#' @export
#' @examples
#' cr_macro_name(c("CompoundA_5min", "interval-2", "n cells"))
#' cr_macro_name("estimate", prefix = "screen")
cr_macro_name <- function(x, prefix = NULL) {
  spell <- function(s) {
    s <- as.character(s)
    digits <- c("zero", "one", "two", "three", "four", "five",
                "six", "seven", "eight", "nine")
    for (d in 0:9) {
      s <- gsub(as.character(d), digits[d + 1L], s, fixed = TRUE)
    }
    gsub("[^A-Za-z]", "", s)
  }
  out <- spell(x)
  if (!is.null(prefix) && nzchar(as.character(prefix)[[1L]])) {
    out <- paste0(spell(prefix)[[1L]], out)
  }
  empty <- !nzchar(out) | is.na(out)
  if (any(empty)) {
    cli::cli_abort(c(
      "Cannot build a macro name from {.val {x[empty]}}.",
      "i" = "A name must contain at least one letter or digit."
    ))
  }
  out
}

#' Format a number for a generated document
#'
#' Fixed-decimal formatting with the conventions a manuscript needs: a
#' placeholder rather than `NaN` for non-finite values, an optional
#' explicit sign — never printed on an exact zero, where a sign would
#' claim a direction the data does not support — and thousands
#' separators for counts.
#'
#' @param x Numeric vector.
#' @param digits Decimal places.
#' @param signed Whether to print a leading `+` on positive values.
#' @param big_mark Thousands separator.
#' @param na Placeholder for `NA`, `NaN` and infinite values.
#' @return A character vector of the same length as `x`.
#' @seealso [cr_macros()], [cr_enumerate()].
#' @family macros
#' @export
#' @examples
#' cr_format_number(c(1.2345, -0.5, 0, NA))
#' cr_format_number(c(1.2345, -0.5, 0), signed = TRUE)
#' cr_format_number(128400, digits = 0)
cr_format_number <- function(x, digits = 3, signed = FALSE,
                             big_mark = ",", na = "--") {
  x <- suppressWarnings(as.numeric(x))
  if (!is.numeric(digits) || length(digits) != 1L || is.na(digits) || digits < 0) {
    cli::cli_abort("{.arg digits} must be a single non-negative number.")
  }
  out <- character(length(x))
  ok <- is.finite(x)
  out[!ok] <- na
  if (any(ok)) {
    vals <- x[ok]
    fmt <- formatC(vals, format = "f", digits = as.integer(digits),
                   big.mark = big_mark,
                   flag = if (isTRUE(signed)) "+" else "")
    # An exact zero carries no direction, so it carries no sign either.
    zero <- round(vals, as.integer(digits)) == 0
    fmt[zero] <- sub("^[+-]", "", fmt[zero])
    out[ok] <- fmt
  }
  out
}

#' Write a vector out as an English list
#'
#' Renders a character vector as `"a"`, `"a and b"` or `"a, b and c"`,
#' with a fixed placeholder for the empty case. Sentences that
#' enumerate results — which contrasts cleared a threshold, which arms
#' were excluded — should be generated for the same reason the numbers
#' are: the hand-written version is right until the analysis changes.
#'
#' @param x Character vector. `NA` and empty strings are dropped.
#' @param conjunction Word joining the last two elements.
#' @param empty Text returned when nothing is left.
#' @param oxford Whether to place a comma before the conjunction.
#' @return A single string.
#' @seealso [cr_macros()], [cr_format_number()].
#' @family macros
#' @export
#' @examples
#' cr_enumerate(c("CompoundA", "CompoundB", "CompoundC"))
#' cr_enumerate(c("CompoundA", "CompoundB"), conjunction = "or")
#' cr_enumerate(character())
cr_enumerate <- function(x, conjunction = "and", empty = "none",
                         oxford = FALSE) {
  x <- as.character(x)
  x <- x[!is.na(x) & nzchar(x)]
  n <- length(x)
  if (!n) return(empty)
  if (n == 1L) return(x)
  sep <- if (isTRUE(oxford) && n > 2L) ", " else " "
  paste0(paste(x[-n], collapse = ", "), sep, conjunction, " ", x[n])
}

# Internal helpers ----------------------------------------------------------

# Flatten a nested named list to a flat named list of scalars.
.cr_flatten_values <- function(values, parent = NULL) {
  if (is.null(values) || !length(values)) return(list())
  if (!is.list(values)) {
    if (is.null(names(values)) && length(values) == 1L && !is.null(parent)) {
      out <- list(values[[1L]])
      names(out) <- parent
      return(out)
    }
    values <- as.list(values)
  }
  nms <- names(values)
  if (is.null(nms)) {
    cli::cli_abort("{.arg values} must be named.")
  }
  out <- list()
  for (i in seq_along(values)) {
    nm <- if (is.null(parent)) nms[i] else paste0(parent, "_", nms[i])
    v <- values[[i]]
    if (is.list(v) || (length(v) > 1L && !is.null(names(v)))) {
      out <- c(out, .cr_flatten_values(v, parent = nm))
    } else if (length(v) == 1L) {
      out[[nm]] <- unname(v)
    } else if (length(v) == 0L) {
      next
    } else {
      cli::cli_abort(c(
        "Value {.val {nm}} has length {length(v)}.",
        "i" = "Emit scalars; collapse vectors with {.fn cr_enumerate} first."
      ))
    }
  }
  out
}

# Presentation form of one value for a LaTeX macro body. Counts are
# written without decimals: an integer, or a round value large enough
# that decimals could only be noise.
.cr_macro_value <- function(v, digits, big_mark, na) {
  if (is.numeric(v)) {
    count <- is.integer(v) || (is.finite(v) && v == round(v) && abs(v) >= 1000)
    d <- if (count) 0 else digits
    return(cr_format_number(v, digits = d, big_mark = big_mark, na = na))
  }
  if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
  as.character(v)
}

# Data form of one value for JSON / YAML output.
.cr_macro_scalar <- function(v, digits) {
  if (is.numeric(v)) {
    if (!is.finite(v)) return("null")
    return(format(round(v, digits), trim = TRUE, scientific = FALSE))
  }
  if (is.logical(v)) return(if (isTRUE(v)) "true" else "false")
  paste0("\"", gsub("\"", "\\\\\"", as.character(v)), "\"")
}

.cr_macro_json <- function(nms, flat, digits) {
  body <- vapply(seq_along(flat), function(i) {
    sprintf("  \"%s\": %s%s", nms[i], .cr_macro_scalar(flat[[i]], digits),
            if (i < length(flat)) "," else "")
  }, character(1))
  c("{", body, "}")
}

.cr_macro_header <- function(format) {
  msg <- c(
    "Generated by cellreportR -- do not edit by hand.",
    "Every value is derived from the analysis object. If one looks",
    "wrong, fix the analysis and emit this file again."
  )
  switch(
    format,
    tex = c(paste("%", msg), ""),
    yaml = c(paste("#", msg), ""),
    json = character()
  )
}

# Columns that identify a row of a contrast table.
.cr_label_cols <- function(tbl) {
  primary <- intersect(c("group", "compound", "treatment", "term", "name"),
                       names(tbl))
  secondary <- intersect(c("contrast", "comparison", "level"), names(tbl))
  cols <- c(primary[seq_len(min(1L, length(primary)))], secondary)
  if (!length(cols)) {
    chr <- names(tbl)[vapply(tbl, function(v) is.character(v) || is.factor(v),
                             logical(1))]
    cols <- chr[seq_len(min(1L, length(chr)))]
  }
  cols
}

# Row labels built from the label columns, or positional when absent.
.cr_row_labels <- function(tbl, cols) {
  if (!length(cols)) return(paste0("row", seq_len(nrow(tbl))))
  parts <- lapply(cols, function(cl) as.character(tbl[[cl]]))
  labels <- do.call(paste, c(parts, list(sep = "_")))
  labels[is.na(labels) | !nzchar(labels)] <- "row"
  make.unique(labels, sep = "_")
}

# Version 0.1.0
