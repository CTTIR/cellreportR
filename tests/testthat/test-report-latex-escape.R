test_that("LaTeX metacharacters use exact single-pass escapes", {
  escape <- cellreportR:::.cr_latex_escape
  inputs <- c("&", "%", "$", "#", "_", "{", "}", "~", "^", "\\")
  expected <- c("\\&", "\\%", "\\$", "\\#", "\\_", "\\{", "\\}",
                "\\textasciitilde{}", "\\textasciicircum{}", "\\textbackslash{}")
  expect_identical(escape(inputs), expected)
  expect_identical(escape(paste0(inputs, collapse = "")),
                   paste0(expected, collapse = ""))
  expect_identical(escape("CRBACKSLASHTOKEN"), "CRBACKSLASHTOKEN")
  expect_identical(escape("\\input{file_name}%"),
                   "\\textbackslash{}input\\{file\\_name\\}\\%")
  expect_identical(escape("A & B: 100% _ # $ { }"),
                   "A \\& B: 100\\% \\_ \\# \\$ \\{ \\}")
})

test_that("LaTeX escaping preserves text and established vector semantics", {
  escape <- cellreportR:::.cr_latex_escape
  expect_identical(escape("äöü µ α — < >"), "äöü µ α — < >")
  expect_identical(escape(c("", NA_character_, "plain")),
                   c("", NA_character_, "plain"))
  expect_identical(escape(NULL), "")
  expect_identical(escape(character()), "")
  expect_identical(escape(c(first = "a_b", second = NA_character_)),
                   c("a\\_b", NA_character_))
  expect_identical(escape(c(1, NA_real_)), c("1", NA_character_))
})
