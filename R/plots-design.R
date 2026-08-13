# Plot design contract -------------------------------------------------------
#
# Every figure the package draws inherits the same visual contract, so that
# constraints are owned once rather than re-stated per figure:
#
#   * a colour-vision-safe qualitative palette (Okabe-Ito);
#   * no red/green pair ever carries meaning;
#   * a redundant shape encoding wherever hue encodes a discrete grouping,
#     which is what makes a palette with a marginal worst-pair separation
#     legal at all;
#   * guides suppressed on duplicate aesthetics, so a figure emits one legend
#     rather than a clipped duplicate;
#   * one shared publication theme.

# Okabe-Ito, ordered so that the first pairs are the best separated.
.cr_okabe_ito <- c(
  blue           = "#0072B2",
  vermillion     = "#D55E00",
  bluish_green   = "#009E73",
  orange         = "#E69F00",
  reddish_purple = "#CC79A7",
  sky_blue       = "#56B4E9",
  yellow         = "#F0E442",
  grey           = "#999999"
)

# Filled shapes first (21-25 take both colour and fill), then open shapes.
.cr_shape_set <- c(21L, 22L, 23L, 24L, 25L, 1L, 0L, 5L, 2L, 6L)

#' Colour-vision-safe palette
#'
#' Returns hex colours from the palette every `cr_plot_*` function uses for
#' discrete groupings. The qualitative set is Okabe-Ito, the standard
#' colour-vision-safe qualitative palette; it deliberately contains no
#' red/green pair, so hue never encodes an opposition that a large minority of
#' readers cannot separate.
#'
#' Hue alone is not treated as a sufficient encoding: use [cr_shapes()] (or
#' [cr_scale_group()], which wires both at once) so that every grouping is
#' carried by shape as well as colour.
#'
#' @param n Number of colours to return. `NULL` (default) returns the whole
#'   palette: 8 colours for `"qualitative"`, 256 for the continuous types.
#'   Requesting more than 8 qualitative colours interpolates between the
#'   anchors and warns, because the result is no longer guaranteed to be
#'   colour-vision-safe; prefer facetting over more than 8 hues.
#' @param type One of `"qualitative"` (discrete groups), `"sequential"`
#'   (one-directional magnitude) or `"diverging"` (signed magnitude around a
#'   meaningful zero, ramped blue-to-vermillion rather than blue-to-red-green).
#' @param names Optional character vector of names to attach to the returned
#'   colours, for use as the `values` argument of a manual scale. Must have
#'   the same length as the result.
#' @return A character vector of hex colour strings, named when `names` is
#'   supplied or when the whole qualitative palette is returned.
#' @seealso [cr_shapes()], [cr_scale_group()], [cr_theme()]
#' @family plot design
#' @export
#' @examples
#' cr_palette()
#' cr_palette(3)
#' cr_palette(5, names = c("a", "b", "c", "d", "e"))
#' cr_palette(7, type = "diverging")
cr_palette <- function(n = NULL,
                       type = c("qualitative", "sequential", "diverging"),
                       names = NULL) {
  type <- match.arg(type)
  if (!is.null(n)) {
    if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
      cli::cli_abort("{.arg n} must be a single positive number.")
    }
    n <- as.integer(n)
  }

  out <- switch(
    type,
    qualitative = .cr_qualitative(n),
    sequential = scales::colour_ramp(
      c("#F7FBFF", "#9ECAE1", .cr_okabe_ito[["sky_blue"]],
        .cr_okabe_ito[["blue"]], "#04305A")
    )(seq(0, 1, length.out = if (is.null(n)) 256L else n)),
    diverging = scales::colour_ramp(
      c(.cr_okabe_ito[["blue"]], "#92C5DE", "#F7F7F7", "#F4A582",
        .cr_okabe_ito[["vermillion"]])
    )(seq(0, 1, length.out = if (is.null(n)) 256L else n))
  )

  if (!is.null(names)) {
    if (length(names) != length(out)) {
      cli::cli_abort(c(
        "{.arg names} must have the same length as the palette.",
        "x" = "Got {length(names)} name{?s} for {length(out)} colour{?s}."
      ))
    }
    out <- stats::setNames(out, names)
  }
  out
}

# Internal: the qualitative branch, including the interpolation warning.
.cr_qualitative <- function(n) {
  if (is.null(n)) return(.cr_okabe_ito)
  if (n <= length(.cr_okabe_ito)) {
    return(.cr_okabe_ito[seq_len(n)])
  }
  cli::cli_warn(c(
    "{n} qualitative colours requested but only \\
     {length(.cr_okabe_ito)} are colour-vision-safe.",
    "i" = "Interpolating; hue alone can no longer separate the levels.",
    "i" = "Prefer facetting, or let {.fn cr_shapes} carry the grouping."
  ))
  stats::setNames(
    scales::colour_ramp(unname(.cr_okabe_ito))(seq(0, 1, length.out = n)),
    NULL
  )
}

#' Redundant shape encoding
#'
#' Returns plotting symbols matched to [cr_palette()], so that a grouping
#' encoded by hue is also encoded by shape. Filled shapes (`21:25`, which take
#' both a `colour` and a `fill`) come first, then open shapes.
#'
#' @param n Number of shapes to return. `NULL` (default) returns all 10.
#'   Requesting more recycles and warns, because shape has then stopped
#'   separating the levels.
#' @param names Optional character vector of names to attach, for use as the
#'   `values` argument of [ggplot2::scale_shape_manual()].
#' @return An integer vector of `ggplot2` shape codes.
#' @seealso [cr_palette()], [cr_scale_group()]
#' @family plot design
#' @export
#' @examples
#' cr_shapes(4)
#' cr_shapes(3, names = c("low", "mid", "high"))
cr_shapes <- function(n = NULL, names = NULL) {
  if (is.null(n)) {
    out <- .cr_shape_set
  } else {
    if (!is.numeric(n) || length(n) != 1L || is.na(n) || n < 1) {
      cli::cli_abort("{.arg n} must be a single positive number.")
    }
    n <- as.integer(n)
    if (n > length(.cr_shape_set)) {
      cli::cli_warn(c(
        "{n} shapes requested but only {length(.cr_shape_set)} are distinct.",
        "i" = "Recycling; shape no longer separates the levels."
      ))
    }
    out <- rep(.cr_shape_set, length.out = n)
  }
  if (!is.null(names)) {
    if (length(names) != length(out)) {
      cli::cli_abort(c(
        "{.arg names} must have the same length as the shape vector.",
        "x" = "Got {length(names)} name{?s} for {length(out)} shape{?s}."
      ))
    }
    out <- stats::setNames(out, names)
  }
  out
}

#' Publication theme
#'
#' The single `ggplot2` theme every `cr_plot_*` function applies, so that
#' figures assembled from different functions sit together without
#' re-styling: a classic axis-line frame, a faint major grid, a bold title, a
#' muted subtitle and a bottom legend.
#'
#' @param base_size Base font size in points (default `11`).
#' @param base_family Base font family. Default `""` (the device default),
#'   which keeps figures reproducible across machines.
#' @param grid Draw the faint major grid (default `TRUE`).
#' @param legend_position Passed to [ggplot2::theme()]. Default `"bottom"`.
#' @return A `ggplot2` theme object, usable with `+` like any other theme.
#' @seealso [cr_palette()], [cr_scale_group()]
#' @family plot design
#' @export
#' @examples
#' df <- data.frame(g = rep(c("a", "b"), each = 20), y = rnorm(40))
#' ggplot2::ggplot(df, ggplot2::aes(g, y)) +
#'   ggplot2::geom_boxplot() +
#'   cr_theme()
cr_theme <- function(base_size = 11, base_family = "", grid = TRUE,
                     legend_position = "bottom") {
  ggplot2::theme_classic(base_size = base_size, base_family = base_family) +
    ggplot2::theme(
      strip.background = ggplot2::element_rect(fill = "grey92", colour = NA),
      strip.text = ggplot2::element_text(face = "bold",
                                         size = base_size - 1),
      legend.position = legend_position,
      plot.title = ggplot2::element_text(face = "bold",
                                         size = base_size + 2),
      plot.subtitle = ggplot2::element_text(size = base_size - 1,
                                            colour = "grey40"),
      plot.caption = ggplot2::element_text(size = base_size - 3,
                                           colour = "grey30", hjust = 0),
      axis.line = ggplot2::element_line(colour = "grey30"),
      panel.grid.major = if (grid) {
        ggplot2::element_line(colour = "grey93")
      } else {
        ggplot2::element_blank()
      },
      panel.grid.minor = ggplot2::element_blank()
    )
}

#' Grouping scales with redundant encoding
#'
#' Builds the discrete scales that carry a grouping variable: a
#' colour-vision-safe hue from [cr_palette()] plus a matching symbol from
#' [cr_shapes()]. Add the result to a plot with `+`, exactly like a single
#' scale.
#'
#' Because the same variable is mapped to several aesthetics, the guide is
#' emitted for one aesthetic only. A duplicate guide is what makes a composed
#' figure print the same legend twice, so `guide_for` names the single
#' aesthetic that keeps its legend and every other aesthetic is suppressed.
#'
#' @param aesthetics Character vector of aesthetics to scale. Any of
#'   `"colour"`, `"color"`, `"fill"`, `"shape"`.
#' @param name Legend title. `NULL` (default) keeps the mapped variable name.
#' @param guide_for Aesthetics that keep a visible guide. Use `"all"` when the
#'   aesthetics are drawn by the same layer and should merge into one key,
#'   `"none"` to suppress every guide. Defaults to the last of `aesthetics`,
#'   which is the one drawn on top.
#' @param drop Passed to the underlying scales: drop unused factor levels
#'   (default `TRUE`).
#' @return A list of `ggplot2` scales.
#' @seealso [cr_palette()], [cr_shapes()], [cr_theme()]
#' @family plot design
#' @export
#' @examples
#' df <- data.frame(g = rep(c("a", "b", "c"), each = 10), y = rnorm(30))
#' ggplot2::ggplot(df, ggplot2::aes(g, y, colour = g, shape = g)) +
#'   ggplot2::geom_point() +
#'   cr_scale_group(c("colour", "shape"), name = "group") +
#'   cr_theme()
cr_scale_group <- function(aesthetics = c("colour", "fill", "shape"),
                           name = NULL,
                           guide_for = NULL,
                           drop = TRUE) {
  valid <- c("colour", "color", "fill", "shape")
  bad <- setdiff(aesthetics, valid)
  if (length(bad)) {
    cli::cli_abort(c(
      "{.arg aesthetics} must be one or more of {.val {valid}}.",
      "x" = "Unsupported: {.val {bad}}."
    ))
  }
  if (is.null(guide_for)) guide_for <- aesthetics[[length(aesthetics)]]
  if (identical(guide_for, "all")) guide_for <- aesthetics
  if (identical(guide_for, "none")) guide_for <- character()
  scale_name <- if (is.null(name)) ggplot2::waiver() else name

  lapply(aesthetics, function(a) {
    pal <- if (a == "shape") {
      function(n) cr_shapes(n)
    } else {
      function(n) unname(cr_palette(n))
    }
    ggplot2::discrete_scale(
      aesthetics = a,
      palette = pal,
      name = scale_name,
      drop = drop,
      guide = if (a %in% guide_for) "legend" else "none"
    )
  })
}

# Version 0.1.0
