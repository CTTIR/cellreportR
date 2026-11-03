test_that("publication export refuses missing or empty device output", {
  p <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
  root <- withr::local_tempdir()
  output <- file.path(root, "figure.pdf")
  sidecar <- paste0(output, ".json")
  for (empty in c(FALSE, TRUE)) {
    writeLines("previous figure", output)
    writeLines("previous metadata", sidecar)
    local_mocked_bindings(ggsave = function(filename, ...) {
      if (empty) file.create(filename)
      invisible(NULL)
    }, .package = "ggplot2")
    expect_error(cr_save_figure(p, output, metadata = list(source = "new")),
                 "did not create a nonempty")
    expect_identical(readLines(output), "previous figure")
    expect_identical(readLines(sidecar), "previous metadata")
    expect_setequal(list.files(root, all.files = TRUE, no.. = TRUE),
                    c("figure.pdf", "figure.pdf.json"))
    unlink(output)
    expect_error(cr_save_figure(p, output), "did not create a nonempty")
    expect_false(file.exists(output))
  }
})

test_that("device and sidecar failures preserve the previous publication", {
  p <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y))
  root <- withr::local_tempdir()
  output <- file.path(root, "figure.pdf")
  sidecar <- paste0(output, ".json")
  writeLines("previous figure", output)
  writeLines("previous metadata", sidecar)
  device_failure <- TRUE
  local_mocked_bindings(ggsave = function(filename, ...) {
    writeLines("partial output", filename)
    if (device_failure) stop("device failed")
  }, .package = "ggplot2")
  expect_error(cr_save_figure(p, output), "device failed")
  expect_identical(readLines(output), "previous figure")
  device_failure <- FALSE
  local_mocked_bindings(write_json = function(...) stop("sidecar failed"),
                        .package = "jsonlite")
  expect_error(cr_save_figure(p, output, metadata = list(source = "new")),
               "sidecar failed")
  expect_identical(readLines(output), "previous figure")
  expect_identical(readLines(sidecar), "previous metadata")
  expect_setequal(list.files(root, all.files = TRUE, no.. = TRUE),
                  c("figure.pdf", "figure.pdf.json"))
})

test_that("a replacement figure and sidecar agree with the real output", {
  p <- ggplot2::ggplot(data.frame(x = 1:3, y = 1:3), ggplot2::aes(x, y)) +
    ggplot2::geom_point()
  root <- withr::local_tempdir()
  output <- file.path(root, "figure.pdf")
  writeLines("previous figure", output)
  writeLines("previous metadata", paste0(output, ".json"))
  expect_identical(cr_save_figure(p, output, metadata = list(source = "new")),
                    output)
  expect_gt(file.info(output)$size, 500)
  doc <- jsonlite::read_json(paste0(output, ".json"))
  expect_identical(doc$file_hash, digest::digest(file = output, algo = "sha256"))
  expect_identical(doc$source, "new")
  expect_setequal(list.files(root, all.files = TRUE, no.. = TRUE),
                  c("figure.pdf", "figure.pdf.json"))
})

test_that("a failed sidecar publication restores the whole previous bundle", {
  root <- withr::local_tempdir()
  paths <- file.path(root, c("figure.pdf", "figure.pdf.json"))
  stage <- file.path(root, c("staged.pdf", "staged.json"))
  for (i in seq_along(paths)) {
    writeLines(paste("previous", i), paths[[i]])
    writeLines(paste("new", i), stage[[i]])
  }
  rename <- function(from, to) {
    if (identical(from, stage[[2L]])) return(FALSE)
    file.rename(from, to)
  }
  expect_error(.cr_publish_figure(stage, paths, rename), "Cannot publish")
  expect_identical(readLines(paths[[1L]]), "previous 1")
  expect_identical(readLines(paths[[2L]]), "previous 2")
  expect_false(any(grepl("previous-", list.files(root, all.files = TRUE))))
})

test_that("warning-only TIFF initialization cannot draw on the caller device", {
  root <- withr::local_tempdir()
  output <- file.path(root, "figure.tiff")
  writeLines("previous figure", output)
  grDevices::pdf(file.path(root, "caller.pdf"))
  caller <- grDevices::dev.cur()
  withr::defer(if (caller %in% grDevices::dev.list()) grDevices::dev.off(caller))
  actual_capabilities <- base::capabilities
  local_mocked_bindings(capabilities = function(what = NULL) {
    result <- actual_capabilities()
    result[c("cairo", "tiff")] <- TRUE
    if (is.null(what)) result else result[what]
  }, .package = "base")
  local_mocked_bindings(tiff = function(...) warning("synthetic Cairo unavailable"),
                        .package = "grDevices")
  drew <- FALSE
  local_mocked_bindings(grid.newpage = function(...) { drew <<- TRUE },
                        .package = "grid")
  p <- ggplot2::ggplot(data.frame(x = 1, y = 1), ggplot2::aes(x, y)) +
    ggplot2::geom_point()
  expect_error(expect_warning(cr_save_figure(p, output), "synthetic Cairo unavailable"),
               "did not open")
  expect_false(drew)
  expect_identical(grDevices::dev.cur(), caller)
  expect_identical(readLines(output), "previous figure")
})

test_that("a failed restore retains the backup and reports its location", {
  root <- withr::local_tempdir()
  output <- file.path(root, "figure.pdf")
  stage <- file.path(root, "staged.pdf")
  writeLines("previous figure", output)
  writeLines("new figure", stage)
  backup <- NULL
  fail_after_backup <- function(from, to) {
    if (!identical(from, output)) return(FALSE)
    backup <<- to
    file.rename(from, to)
  }
  expect_error(expect_warning(.cr_publish_figure(stage, output, fail_after_backup),
                               "Could not restore.*retained at"), "Cannot publish")
  expect_identical(readLines(backup), "previous figure")
  expect_identical(readLines(stage), "new figure")
  expect_false(file.exists(output))
})

test_that("laboratory PDF graphics also stop before drawing on failed Cairo", {
  root <- withr::local_tempdir()
  grDevices::pdf(file.path(root, "caller.pdf"))
  caller <- grDevices::dev.cur()
  withr::defer(if (caller %in% grDevices::dev.list()) grDevices::dev.off(caller))
  local_mocked_bindings(cairo_pdf = function(...) warning("synthetic Cairo unavailable"),
                        .package = "grDevices")
  drew <- FALSE
  local_mocked_bindings(grid.newpage = function(...) { drew <<- TRUE },
                        .package = "grid")
  # Isolate the graphics failure from external TeX availability.
  local_mocked_bindings(.cr_lab_pdf_preflight = function(...) invisible(NULL))
  local_mocked_bindings(render = function(...) stop("renderer was called"),
                        .package = "rmarkdown")
  report <- cr_lab_report(spec = cr_test_lab_spec())
  report$result_graphic <- ggplot2::ggplot(data.frame(x = 1, y = 1),
                                          ggplot2::aes(x, y)) + ggplot2::geom_point()
  expect_error(expect_warning(.cr_render_lab_pdf(report, file.path(root, "report.pdf")),
                               "synthetic Cairo unavailable"), "did not open")
  expect_false(drew)
  expect_identical(grDevices::dev.cur(), caller)
  expect_false(file.exists(file.path(root, "report.pdf")))
})
