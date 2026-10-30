test_that("report and audit paths cannot overwrite each other", {
  root <- withr::local_tempdir()
  report <- cr_lab_report(spec = cr_test_lab_spec())
  output <- file.path(root, "report.html")
  for (audit in c(output, file.path(root, ".", "report.html"),
                  file.path(root, "new", "..", "report.html"))) {
    expect_error(cr_render_lab_report(report, output, audit_file = audit), "distinct")
    expect_false(file.exists(output))
  }
})

test_that("overwrite protection covers an existing audit before rendering", {
  root <- withr::local_tempdir()
  report <- cr_lab_report(spec = cr_test_lab_spec())
  output <- file.path(root, "report.html")
  audit <- file.path(root, "audit.json")
  writeLines("preserved audit", audit)
  expect_error(cr_render_lab_report(report, output, audit_file = audit), "Audit output already exists")
  expect_identical(readLines(audit), "preserved audit")
  expect_false(file.exists(output))
})

test_that("TIFF export respects compression support with Quartz configured", {
  native_tiff <- isTRUE(capabilities("cairo")) && isTRUE(capabilities("tiff"))
  skip_if_not(native_tiff || isTRUE(capabilities("aqua")))
  withr::local_options(list(bitmapType = "quartz"))
  p <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(.data$x, .data$y)) +
    ggplot2::geom_point()
  f <- withr::local_tempfile(fileext = ".tiff")
  expect_silent(cr_save_figure(p, f, size = "single", dpi = 100))
  con <- file(f, "rb")
  on.exit(close(con), add = TRUE)
  order <- rawToChar(readBin(con, "raw", 2))
  endian <- if (order == "II") "little" else "big"
  expect_true(order %in% c("II", "MM"))
  expect_equal(readBin(con, "integer", 1, size = 2, endian = endian), 42)
  offset <- readBin(con, "integer", 1, size = 4, endian = endian)
  seek(con, offset)
  n <- readBin(con, "integer", 1, size = 2, endian = endian)
  compression <- NA_integer_
  for (i in seq_len(n)) {
    seek(con, offset + 2 + (i - 1) * 12)
    tag <- readBin(con, "integer", 1, size = 2, endian = endian)
    if (tag == 259) {
      seek(con, offset + 2 + (i - 1) * 12 + 8)
      compression <- readBin(con, "integer", 1, size = 2, endian = endian)
    }
  }
  expect_equal(compression, if (native_tiff) 5 else 1) # TIFF tag 259: LZW or none.
})
