# Tests for the shared plot design contract: palette, shapes, theme, scales.

test_that("cr_palette returns the colour-vision-safe qualitative set", {
  full <- cr_palette()
  expect_length(full, 8L)
  expect_true(all(grepl("^#[0-9A-Fa-f]{6}$", full)))
  expect_named(full)
  expect_identical(unname(cr_palette(3L)), unname(full[1:3]))
})

test_that("cr_palette supports continuous types and explicit names", {
  expect_length(cr_palette(type = "sequential"), 256L)
  expect_length(cr_palette(type = "diverging"), 256L)
  expect_length(cr_palette(5L, type = "sequential"), 5L)
  expect_named(cr_palette(2L, names = c("a", "b")), c("a", "b"))
})

test_that("cr_palette warns rather than silently repeating hues", {
  expect_warning(out <- cr_palette(12L), "colour-vision-safe")
  expect_length(out, 12L)
  expect_false(anyDuplicated(out) > 0L)
})

test_that("cr_palette rejects bad input", {
  expect_error(cr_palette(0), "positive")
  expect_error(cr_palette(-1), "positive")
  expect_error(cr_palette("a"), "positive")
  expect_error(cr_palette(2L, names = "a"), "same length")
})

test_that("cr_shapes matches the palette and warns when it runs out", {
  expect_length(cr_shapes(), 10L)
  expect_identical(cr_shapes(3L), c(21L, 22L, 23L))
  expect_named(cr_shapes(2L, names = c("x", "y")), c("x", "y"))
  expect_warning(cr_shapes(12L), "distinct")
  expect_error(cr_shapes(0), "positive")
  expect_error(cr_shapes(2L, names = "x"), "same length")
})

test_that("cr_theme returns a usable ggplot2 theme", {
  th <- cr_theme()
  expect_s3_class(th, "theme")
  df <- data.frame(g = rep(c("a", "b"), each = 5), y = 1:10)
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$g, .data$y)) +
    ggplot2::geom_point() + th
  expect_s3_class(p, "ggplot")
  expect_no_error(ggplot2::ggplot_build(p))
  expect_s3_class(cr_theme(grid = FALSE)$panel.grid.major, "element_blank")
})

test_that("cr_scale_group builds one scale per aesthetic", {
  expect_length(cr_scale_group(c("colour", "fill", "shape")), 3L)
  expect_length(cr_scale_group("fill"), 1L)
  expect_error(cr_scale_group("size"), "Unsupported")
})

test_that("cr_scale_group controls which aesthetic keeps a guide", {
  all_on <- cr_scale_group(c("fill", "shape"), guide_for = "all")
  expect_true(all(vapply(all_on, function(s) identical(s$guide, "legend"),
                         logical(1))))
  none <- cr_scale_group(c("fill", "shape"), guide_for = "none")
  expect_true(all(vapply(none, function(s) identical(s$guide, "none"),
                         logical(1))))
  one <- cr_scale_group(c("fill", "shape"))
  expect_identical(vapply(one, function(s) s$guide, character(1)),
                   c("none", "legend"))
})

test_that("cr_scale_group scales render on a real plot", {
  df <- data.frame(g = rep(c("a", "b", "c"), each = 4), y = 1:12)
  p <- ggplot2::ggplot(df, ggplot2::aes(.data$g, .data$y,
                                        colour = .data$g,
                                        shape = .data$g)) +
    ggplot2::geom_point() +
    cr_scale_group(c("colour", "shape"), name = "group") +
    cr_theme()
  built <- ggplot2::ggplot_build(p)
  expect_setequal(unique(built$data[[1]]$colour), unname(cr_palette(3L)))
  expect_setequal(unique(built$data[[1]]$shape), cr_shapes(3L))
})
