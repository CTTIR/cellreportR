# File-name token grammars.
#
# One export file name decomposes into design facts: a replicate
# index, a leading label, and a handful of tokens whose absence is
# as meaningful as their presence.


#' Declare the token grammar of an export file name
#'
#' A `cr_filename_grammar` states how one export file name decomposes
#' into design facts: which trailing token is the replicate index, which
#' leading labels are stripped, which substrings are tokens, and which
#' whole-name shapes are legal at all.
#'
#' The `core_patterns` whitelist exists because the absence of a token is
#' itself meaningful — a name with no interval token is the untreated
#' reference arm, a name with no concentration token is a vehicle
#' control. A mistyped token therefore matches nothing, falls through to
#' the defaults, and silently reclassifies a treated unit as a vehicle
#' control, pulling it into the control denominator of its own batch.
#' With a whitelist in place such a name is a hard error instead.
#'
#' `prefix_strip` entries are removed longest-first, so a short label
#' cannot consume a longer one that starts with the same characters.
#'
#' @param tokens Named list (or named character vector) of regular
#'   expressions. Each is searched for in the name core; the matched text
#'   becomes the value of a column named after the list element.
#' @param defaults Named list of values to use when a token is absent.
#'   Elements with no entry default to `NA`.
#' @param core_patterns Character vector of regular expressions. The core
#'   (the name with extension, markers, replicate index and prefix
#'   removed) must match at least one of them. Empty means no whitelist.
#' @param typo_fixes Named character vector of `pattern = replacement`
#'   repairs applied before anything else is parsed.
#' @param prefix_strip Character vector of leading labels to strip from
#'   the core, longest first.
#' @param replicate Regular expression for the trailing replicate token.
#'   Default `"[0-9]+(?:\\.[0-9]+)?"`, which accepts both `1` and `1.1`.
#' @param sep Token separator. Default `"_"`.
#' @param normalise_space Logical. Convert runs of whitespace to `sep`
#'   and collapse repeated separators. Default `TRUE`.
#'
#' @return An object of class `cr_filename_grammar` (a list).
#'
#' @seealso [cr_parse_paths()], [cr_path_spec()].
#' @family import
#' @export
#' @examples
#' g <- cr_filename_grammar(
#'   tokens = list(interval = "[0-9]+min", dose = "[0-9]+uM",
#'                 mode = "treated|vehicle"),
#'   defaults = list(interval = "none", dose = "vehicle"),
#'   core_patterns = c("^vehicle$",
#'                     "^[0-9]+min_vehicle$",
#'                     "^[0-9]+uM_treated$",
#'                     "^[0-9]+min_[0-9]+uM_treated$"),
#'   prefix_strip = c("CompoundA", "CompoundB")
#' )
#' g
cr_filename_grammar <- function(tokens = list(),
                                defaults = list(),
                                core_patterns = character(),
                                typo_fixes = character(),
                                prefix_strip = character(),
                                replicate = "[0-9]+(?:\\.[0-9]+)?",
                                sep = "_",
                                normalise_space = TRUE) {
  if (is.character(tokens)) tokens <- as.list(tokens)
  if (!is.list(tokens) ||
      (length(tokens) && (is.null(names(tokens)) ||
                          any(!nzchar(names(tokens)))))) {
    cli::cli_abort("{.arg tokens} must be a fully named list of patterns.")
  }
  if (!is.list(defaults)) defaults <- as.list(defaults)
  if (length(defaults) && (is.null(names(defaults)) ||
                           any(!nzchar(names(defaults))))) {
    cli::cli_abort("{.arg defaults} must be a fully named list.")
  }
  unknown <- setdiff(names(defaults), names(tokens))
  if (length(unknown)) {
    cli::cli_abort(
      c("{.arg defaults} names must be token names.",
        "x" = "Not a token: {.field {unknown}}.")
    )
  }
  if (!is.character(core_patterns)) {
    cli::cli_abort("{.arg core_patterns} must be a character vector.")
  }
  .cr_arg_named_chr(if (length(typo_fixes)) typo_fixes else NULL,
                    arg = "typo_fixes")
  if (!is.character(prefix_strip)) {
    cli::cli_abort("{.arg prefix_strip} must be a character vector.")
  }
  .cr_arg_string(replicate)
  .cr_arg_string(sep)
  .cr_arg_flag(normalise_space)

  obj <- list(
    tokens = tokens,
    defaults = defaults,
    core_patterns = core_patterns,
    typo_fixes = typo_fixes,
    prefix_strip = prefix_strip,
    replicate = replicate,
    sep = sep,
    normalise_space = normalise_space
  )
  class(obj) <- c("cr_filename_grammar", "list")
  obj
}

#' @param x A `cr_filename_grammar`.
#' @param ... Ignored.
#' @return `x`, invisibly.
#' @rdname cr_filename_grammar
#' @export
print.cr_filename_grammar <- function(x, ...) {
  cli::cli_text("{.cls cr_filename_grammar}")
  cli::cli_bullets(c(
    "*" = "tokens: {.field {names(x$tokens)}}",
    "*" = "core patterns: {length(x$core_patterns)}",
    "*" = "prefixes stripped: {length(x$prefix_strip)}",
    "*" = "replicate: {.val {x$replicate}}"
  ))
  invisible(x)
}

# Parse one marker-stripped file stem against a grammar.
.cr_grammar_parse <- function(stem, grammar) {
  token_names <- names(grammar$tokens)
  empty <- stats::setNames(
    rep(NA_character_, length(token_names)), token_names
  )
  s <- stem
  for (pat in names(grammar$typo_fixes)) {
    s <- gsub(pat, grammar$typo_fixes[[pat]], s)
  }
  esc_sep <- .cr_regex_escape(grammar$sep)
  if (isTRUE(grammar$normalise_space)) {
    s <- trimws(s)
    s <- gsub("[[:space:]]+", grammar$sep, s)
    s <- gsub(paste0("(", esc_sep, ")+"), grammar$sep, s)
  }

  rep_pat <- paste0(esc_sep, "(", grammar$replicate, ")$")
  hit <- regmatches(s, regexpr(rep_pat, s))
  if (length(hit)) {
    replicate <- sub(paste0("^", esc_sep), "", hit)
    core <- sub(rep_pat, "", s)
  } else {
    replicate <- NA_character_
    core <- s
  }

  prefixes <- grammar$prefix_strip
  prefixes <- prefixes[order(-nchar(prefixes))]
  for (p in prefixes) {
    lead <- paste0(p, grammar$sep)
    if (startsWith(core, lead)) {
      core <- substring(core, nchar(lead) + 1L)
      break
    }
  }

  ok <- TRUE
  error <- NA_character_
  if (length(grammar$core_patterns)) {
    matched <- vapply(grammar$core_patterns,
                      function(p) grepl(p, core), logical(1L))
    if (!any(matched)) {
      ok <- FALSE
      error <- sprintf("core '%s' matches no pattern in the grammar", core)
    }
  }

  tokens <- empty
  for (nm in token_names) {
    hit <- regmatches(core, regexpr(grammar$tokens[[nm]], core))
    tokens[[nm]] <- if (length(hit)) {
      hit[[1L]]
    } else if (nm %in% names(grammar$defaults)) {
      as.character(grammar$defaults[[nm]])
    } else {
      NA_character_
    }
  }

  list(core = core, replicate = replicate, tokens = tokens,
       parse_ok = ok, parse_error = error)
}

# Version 0.1.0
