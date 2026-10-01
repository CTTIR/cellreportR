.evidence_fixture <- function(root) {
  writeLines(c("group,site,estimate,note", "treated,A,1.2345,NA",
               "control,A,0,observed"), file.path(root, "results.csv"))
  writeBin(charToRaw("independent figure bytes"), file.path(root, "figure.svg"))
  list(tables = list(effects = list(path = "results.csv", format = "csv",
                                   key = c("group", "site"))),
       claims = list(effect = list(table = "effects",
         key = c(site = "A", group = "treated"), column = "estimate",
         format = "number", digits = 2),
         literal = list(table = "effects", key = c(group = "treated", site = "A"),
                        column = "note")),
       figures = list(plot = list(path = "figure.svg", tables = "effects")))
}

test_that("source-bound reporting retains frozen public function signatures", {
  expect_identical(formals(cr_export_report_audit),
                   formals(function(report, path, output_file = NULL) NULL))
  expect_identical(formals(cr_report_provenance), formals(function(
    experiment = NULL, report_spec, output_file = NULL,
    analysis_metadata = list()) {
      NULL
    }))
  expect_identical(formals(cr_render_lab_report), formals(function(
    report, output_file, template = NULL, quiet = TRUE, audit_file = NULL,
    overwrite = FALSE, keep_tex = FALSE) {
      NULL
    }))
})

test_that("a relocated source tree can assemble and export unchanged evidence", {
  root <- withr::local_tempdir(); relocated <- withr::local_tempdir()
  args <- .evidence_fixture(root)
  evidence <- do.call(cr_report_evidence, c(list(root = root), args))
  file.copy(list.files(root, full.names = TRUE), relocated)
  spec <- cr_report_spec(report = list(report_id = "portable"),
                         result = list(value = 1.2345),
                         authorization = list(authorized_by = "Reviewer"))
  original <- cr_lab_report_from_evidence(evidence, root, spec, strict = FALSE)
  moved <- cr_lab_report_from_evidence(evidence, relocated, spec, strict = FALSE)
  expect_identical(cr_report_data(moved), cr_report_data(original))
  output <- file.path(relocated, "audit.json")
  cr_export_report_audit(moved, output)
  audit <- jsonlite::read_json(output, simplifyVector = FALSE)
  expect_identical(audit$analysis_metadata$report_evidence$sha256, evidence$sha256)
  expect_false(grepl(normalizePath(root, winslash = "/"),
                     paste(readLines(output), collapse = ""), fixed = TRUE))
})

test_that("evidence identifier and figure-link ordering is locale independent", {
  root <- withr::local_tempdir()
  args <- .evidence_fixture(root)
  tables <- list(a = args$tables$effects, B = args$tables$effects)
  figures <- list(plot = list(path = "figure.svg", tables = c("a", "B")))
  withr::local_locale(c(LC_COLLATE = "C"))
  reference <- cr_report_evidence(root, tables, figures = figures)
  expect_identical(names(reference$tables), c("B", "a"))
  expect_identical(reference$figures$plot$tables, c("B", "a"))
  candidates <- c("en_US.utf8", "en_US.UTF-8", "English_United States.1252")
  available <- vapply(candidates, function(locale) {
    nzchar(suppressWarnings(Sys.setlocale("LC_COLLATE", locale)))
  }, logical(1))
  if (any(available)) {
    Sys.setlocale("LC_COLLATE", candidates[which(available)[1L]])
    actual <- cr_report_evidence(root, tables, figures = figures)
    expect_identical(actual, reference)
    expect_true(cr_validate_report_evidence(reference, root))
  }
})

test_that("evidence numeric displays ignore and restore the ambient decimal mark", {
  root <- withr::local_tempdir()
  args <- .evidence_fixture(root)
  withr::local_options(OutDec = ".")
  reference <- do.call(cr_report_evidence, c(list(root = root), args))
  options(OutDec = ",")
  expect_no_warning(actual <- do.call(cr_report_evidence, c(list(root = root), args)))
  expect_identical(actual, reference)
  expect_identical(getOption("OutDec"), ",")
  expect_true(cr_validate_report_evidence(reference, root))
  args$claims$effect$column <- "absent"
  expect_error(do.call(cr_report_evidence, c(list(root = root), args)), "Unknown claim")
  expect_identical(getOption("OutDec"), ",")
})

test_that("evidence decimals preserve grammar and independently specified doubles", {
  text <- c("+001.25", "+.5", "1.", "-000.00", "0001.e+02",
            "9.7951599999999999e+01", "9.2749999999999999e-01",
            "9.9399999999999999e-01", "4.9406564584124654e-324")
  expected <- c(1.25, 0.5, 1, -0.0, 100, 0x1.87ce703afb7e9p+6,
                0x1.dae147ae147aep-1, 0x1.fced916872b02p-1,
                0x0.0000000000001p-1022)
  actual <- vapply(text, cellreportR:::.cr_evidence_number, double(1), USE.NAMES = FALSE)
  expect_identical(writeBin(actual, raw()), writeBin(expected, raw()))
  for (bad in c("1,2", "[1]", "1e999", "NA", "--1", ".", "+", "1 e2")) {
    expect_error(cellreportR:::.cr_evidence_number(bad), "finite decimal")
  }
})

test_that("keyed claims resolve independently and preserve literal missingness", {
  root <- withr::local_tempdir()
  args <- .evidence_fixture(root)
  e <- do.call(cr_report_evidence, c(list(root = root), args))
  expect_identical(e$claims$effect$value, "1.2345")
  expect_identical(e$claims$effect$display, "1.23")
  expect_identical(e$claims$literal$display, "NA")
  expect_identical(e$tables$effects$rows, "2")
  expect_identical(e$tables$effects$sha256,
    digest::digest(file = file.path(root, "results.csv"), algo = "sha256"))
  expect_identical(e$figures$plot$table_sha256[["effects"]], e$tables$effects$sha256)
  expect_true(cr_validate_report_evidence(e, root))
  expect_identical(e, do.call(cr_report_evidence, c(list(root = root), args)))
  e2 <- e; e2$claims$effect$display <- "999"
  expect_error(cr_validate_report_evidence(e2, root), "manifest hash")
  e2 <- e; e2$schema_version <- "2.0"
  expect_error(cr_validate_report_evidence(e2, root), "schema")
})

test_that("portable relocation and RDS roundtrip retain evidence identity", {
  root <- withr::local_tempdir(); copy <- withr::local_tempdir()
  args <- .evidence_fixture(root)
  e <- do.call(cr_report_evidence, c(list(root = root), args))
  file.copy(list.files(root, full.names = TRUE), copy)
  rds <- tempfile(tmpdir = copy)
  saveRDS(e, rds)
  expect_identical(readRDS(rds), e)
  expect_true(cr_validate_report_evidence(readRDS(rds), copy))
  writeLines("changed", file.path(copy, "figure.svg"))
  expect_error(cr_validate_report_evidence(e, copy), "changed")
  writeLines(c("group,site,estimate,note", "control,A,0,observed",
               "treated,A,1.2345,NA"), file.path(root, "results.csv"))
  expect_error(cr_validate_report_evidence(e, root), "changed")
  new <- do.call(cr_report_evidence, c(list(root = root), args))
  expect_identical(new$claims$effect$display, e$claims$effect$display)
  expect_false(identical(new$sha256, e$sha256))
})

test_that("duplicate keys and unresolved claims fail closed", {
  root <- withr::local_tempdir(); args <- .evidence_fixture(root)
  run <- function(a = args) do.call(cr_report_evidence, c(list(root = root), a))
  a <- args; a$claims$effect$key <- c(group = "treated")
  expect_error(run(a), "every table key")
  a <- args; a$claims$effect$key[["group"]] <- "absent"
  expect_error(run(a), "exactly one row")
  a <- args; a$claims$effect$column <- "absent"
  expect_error(run(a), "Unknown claim column")
  a <- args; a$claims$effect$table <- "absent"
  expect_error(run(a), "Unknown claim table")
  a <- args; a$figures$plot$tables <- "absent"
  expect_error(run(a), "Unknown figure")
  a <- args; a$tables$effects$key <- "absent"
  expect_error(run(a), "Unknown key")
  writeLines(c("group,site,estimate,note", "treated,A,1,x", "treated,A,2,y"),
             file.path(root, "results.csv"))
  expect_error(run(), "unique")
  writeLines(c("group,site,estimate,note", ",A,1,x"), file.path(root, "results.csv"))
  expect_error(run(), "nonempty")
})

test_that("numbers are explicit finite decimal values, not missing substitutes", {
  root <- withr::local_tempdir(); args <- .evidence_fixture(root)
  for (value in c("NA", "NaN", "Inf", "1e999", "0x10", "", "word")) {
    writeLines(c("group,site,estimate,note", paste0("treated,A,", value, ",NA")),
               file.path(root, "results.csv"))
    expect_error(do.call(cr_report_evidence, c(list(root = root), args)),
                 "finite decimal|missing or empty")
  }
  args <- .evidence_fixture(root)
  for (digits in list(NA_real_, Inf, 2.5, -1, 16, 1e100, "2")) {
    args$claims$effect$digits <- digits
    expect_error(do.call(cr_report_evidence, c(list(root = root), args)), "digits")
  }
})

test_that("paths, source schemas and descriptor names are guarded", {
  root <- withr::local_tempdir(); args <- .evidence_fixture(root)
  run <- function(a = args) do.call(cr_report_evidence, c(list(root = root), a))
  for (path in c("../outside.csv", "/tmp/results.csv", "C:/results.csv",
                 "sub\\results.csv", "./results.csv")) {
    a <- args; a$tables$effects$path <- path
    expect_error(run(a), "relative paths")
  }
  a <- args; a$tables$effects$extra <- TRUE
  expect_error(run(a), "descriptor")
  a <- args; a$tables$effects$format <- "guess"
  expect_error(run(a), "format")
  a <- args; names(a$claims) <- c("same", "same")
  expect_error(run(a), "unique")
  a <- args; a$claims$effect$format <- "percent"
  expect_error(run(a), "format")
  expect_error(cr_report_evidence(root, list()), "identifiers")
  outside <- withr::local_tempfile(); writeLines("outside", outside)
  if (file.symlink(outside, file.path(root, "link.csv"))) {
    a <- args; a$tables$effects$path <- "link.csv"
    expect_error(run(a), "within root")
  }
  writeLines(c("group,group", "A,B"), file.path(root, "results.csv"))
  expect_error(run(), "unique")
})

test_that("TSV empty tables are evidence but cannot supply invented claims", {
  root <- withr::local_tempdir()
  writeLines("id\tvalue", file.path(root, "empty.tsv"))
  tabs <- list(empty = list(path = "empty.tsv", format = "tsv", key = "id"))
  e <- cr_report_evidence(root, tabs)
  expect_identical(e$tables$empty$rows, "0")
  expect_true(cr_validate_report_evidence(e, root))
  expect_error(cr_report_evidence(root, tabs, list(value = list(table = "empty",
    key = c(id = "one"), column = "value"))), "exactly one row")
})

test_that("assembly binds custom fields and audit while legacy data stay unchanged", {
  root <- withr::local_tempdir(); args <- .evidence_fixture(root)
  e <- do.call(cr_report_evidence, c(list(root = root), args))
  spec <- cr_report_spec(report = list(report_id = "example"),
                         result = list(value = 1.2345),
                         authorization = list(authorized_by = "Reviewer"))
  legacy <- cr_lab_report(spec = spec, strict = FALSE)
  old <- cr_report_data(legacy)
  expect_false("evidence" %in% names(old))
  report <- cr_lab_report_from_evidence(e, root, spec, strict = FALSE)
  expect_s3_class(report, "cr_lab_report")
  expect_identical(report$spec$custom_fields$effect, "1.23")
  expect_identical(cr_report_data(legacy), old)
  expect_identical(cr_report_data(report)$evidence, unclass(e))
  audit <- cr_report_provenance(report_spec = report)
  expect_identical(audit$analysis_metadata$report_evidence, unclass(e))
  expect_error(cr_report_provenance(report_spec = report,
    analysis_metadata = list(report_evidence = "forged")), "Reserved")
  output <- file.path(root, "audit.json")
  cr_export_report_audit(report, output)
  expect_true(file.exists(output))
  expect_error(cr_lab_report_from_evidence(e, root, report$spec), "collide")
  report$spec$custom_fields$effect <- "999"
  expect_error(cr_report_provenance(report_spec = report), "fields have changed")
  expect_error(cr_render_lab_report(report, file.path(root, "report.html")),
               "fields have changed")
  expect_error(cr_export_report_audit(report, file.path(root, "bad.json")),
               "fields have changed")
  expect_false(file.exists(file.path(root, "bad.json")))
  expect_false(file.exists(file.path(root, "report.html")))
})
