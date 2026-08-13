# Generated-number emission: names, formatting, enumerations and the
# files they are written to.

# ---- names ----

test_that("cr_macro_name keeps letters and spells digits out", {
  expect_equal(cr_macro_name(c("CompoundA_5min", "interval-2", "n cells")),
               c("CompoundAfivemin", "intervaltwo", "ncells"))
  expect_equal(cr_macro_name("estimate", prefix = "screen"), "screenestimate")
  expect_equal(cr_macro_name("2F"), "twoF")
  expect_error(cr_macro_name("_-_"), "Cannot build a macro name")
})

# ---- number formatting ----

test_that("cr_format_number formats, signs and guards non-finite values", {
  expect_equal(cr_format_number(c(1.2345, -0.5)), c("1.234", "-0.500"))
  expect_equal(cr_format_number(c(NA, Inf, NaN)), rep("--", 3))
  expect_equal(cr_format_number(NA, na = "n/a"), "n/a")
  expect_equal(cr_format_number(1.2, signed = TRUE), "+1.200")
  expect_equal(cr_format_number(128400, digits = 0), "128,400")
  expect_equal(cr_format_number(128400, digits = 0, big_mark = ""), "128400")
  expect_error(cr_format_number(1, digits = -1), "digits")
})

test_that("cr_format_number prints no sign on an exact zero", {
  expect_equal(cr_format_number(0, signed = TRUE), "0.000")
  expect_equal(cr_format_number(-1e-9, signed = TRUE), "0.000")
})

# ---- enumerations ----

test_that("cr_enumerate renders an English list", {
  expect_equal(cr_enumerate("A"), "A")
  expect_equal(cr_enumerate(c("A", "B")), "A and B")
  expect_equal(cr_enumerate(c("A", "B", "C")), "A, B and C")
  expect_equal(cr_enumerate(c("A", "B", "C"), oxford = TRUE), "A, B, and C")
  expect_equal(cr_enumerate(c("A", "B"), conjunction = "or"), "A or B")
  expect_equal(cr_enumerate(character()), "none")
  expect_equal(cr_enumerate(c(NA, "")), "none")
  expect_equal(cr_enumerate(NULL, empty = "no compound"), "no compound")
})

# ---- emission ----

test_that("cr_macros emits LaTeX definitions and writes a file", {
  vals <- list(cells_analysed = 128400, units_analysed = 96L,
               top_estimate = 1.42, flag = TRUE, label = "CompoundA")
  lines <- cr_macros(vals, file = NULL, prefix = "screen")
  expect_true(any(grepl("\\newcommand{\\screencellsanalysed}{128,400}",
                        lines, fixed = TRUE)))
  expect_true(any(grepl("{\\screenunitsanalysed}{96}", lines, fixed = TRUE)))
  expect_true(any(grepl("{\\screentopestimate}{1.420}", lines, fixed = TRUE)))
  expect_true(any(grepl("{\\screenflag}{true}", lines, fixed = TRUE)))

  f <- withr::local_tempfile(fileext = ".tex")
  out <- cr_macros(vals, f)
  expect_equal(out, f)
  expect_true(file.exists(f))
  expect_true(any(grepl("do not edit by hand", readLines(f))))
})

test_that("cr_macros supports json and yaml and flattens nested values", {
  vals <- list(a = 1.5, nested = list(inner = 2L), label = "CompoundA")
  js <- cr_macros(vals, file = NULL, format = "json")
  expect_equal(js[[1]], "{")
  expect_equal(js[[length(js)]], "}")
  expect_true(any(grepl("\"nestedinner\": 2", js, fixed = TRUE)))

  ya <- cr_macros(vals, file = NULL, format = "yaml", header = character())
  expect_true(any(grepl("^a: 1.5$", ya)))
  expect_false(any(grepl("^#", ya)))
})

test_that("cr_macros refuses colliding names, empty input and vectors", {
  expect_error(cr_macros(list(`a-1` = 1, a1 = 2), file = NULL),
               "more than once")
  expect_error(cr_macros(list(), file = NULL), "nothing to emit")
  expect_error(cr_macros(list(x = 1:3), file = NULL), "length 3")
  expect_error(cr_macros(list(1, 2), file = NULL), "must be named")
})

# ---- derivation from results ----

test_that("cr_macros_from turns a contrast table into named values", {
  eff <- data.frame(
    group = c("CompoundA", "CompoundB", "CompoundC"),
    estimate = c(1.42, 0.31, -0.88),
    ci_low = c(0.55, -0.10, -1.60),
    ci_high = c(2.29, 0.72, -0.16),
    magnitude = c("large", "small", "large")
  )
  lines <- cr_macros_from(eff, file = NULL)
  expect_true(any(grepl("{\\CompoundAestimate}{1.420}", lines, fixed = TRUE)))
  expect_true(any(grepl("{\\CompoundBmagnitude}{small}", lines, fixed = TRUE)))
  # the enumeration is computed, not transcribed
  expect_true(any(grepl("{\\excludeszero}{CompoundA and CompoundC}",
                        lines, fixed = TRUE)))
  expect_true(any(grepl("{\\nexcludeszero}{2}", lines, fixed = TRUE)))
  expect_true(any(grepl("{\\ncontrasts}{3}", lines, fixed = TRUE)))
})

test_that("cr_macros_from reads the counts of an assembled report", {
  exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
  rep <- cr_report(exp)
  f <- withr::local_tempfile(fileext = ".tex")
  cr_macros_from(rep, f)
  lines <- readLines(f)
  expect_true(any(grepl("\\newcommand{\\nunits}", lines, fixed = TRUE)))
  expect_true(any(grepl("\\newcommand{\\ncells}", lines, fixed = TRUE)))
  expect_error(cr_macros_from(42, file = NULL), "cr_report")
})
