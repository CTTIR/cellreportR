test_that("timestamp import preserves instants and supported UTC syntax", {
  expected <- as.numeric(as.POSIXct("2026-10-02 15:37:15", tz = "UTC"))
  for (x in c("2026-10-02T17:37:15+0200", "2026-10-02T17:37:15+02:00",
              "2026-10-02T10:07:15-0530", "2026-10-02T15:37:15Z",
              "2026-10-02 15:37:15", "2026-10-02 15:37:15 UTC")) {
    expect_identical(as.numeric(.cr_import_datetime(x)), expected)
  }
  expect_identical(as.numeric(.cr_import_datetime("2026-10-02 15:37")), expected - 15)
  expect_identical(as.numeric(.cr_import_datetime("2026-10-02 15:37 UTC")), expected - 15)
  for (x in c("2026-10-02T15:37:15.125Z", "2026-10-02 15:37:15.125 UTC")) {
    expect_identical(as.numeric(.cr_import_datetime(x)), expected + 0.125)
  }
  expect_identical(.cr_import_datetime("2024-02-29"), as.Date("2024-02-29"))
  expect_null(.cr_import_datetime(NULL))
  for (x in list("", NA_character_, character(), c("x", "y"), 1,
                "2026-02-30", "2026-10-02junk", "2026-10-02T25:00:00Z",
                "2026-10-02T12:60:00Z", "2026-10-02T12:00:60Z",
                "2026-10-02T12:00:00+2400", "2026-10-02T12:00:00+0060",
                "2026-10-02T12:00:00", "2026-10-02T12:00:00Zjunk")) {
    expect_error(.cr_import_datetime(x))
  }
})

test_that("all timestamp fields round trip without changing date of birth", {
  when <- as.POSIXct("2026-10-02 15:37:15", tz = "UTC")
  spec <- cr_report_spec(
    report = list(created_at = when, analysis_completed_at = when, released_at = when),
    subject = list(date_of_birth = as.Date("2000-02-29")),
    specimen = list(collection_datetime = when, received_datetime = when),
    authorization = list(released_at = when, authorized_by = "Example")
  )
  path <- withr::local_tempfile(fileext = ".json")
  cr_export_report_spec(spec, path)
  back <- cr_import_report_spec(path)
  for (nm in c("created_at", "analysis_completed_at", "released_at")) {
    expect_identical(back$report[[nm]], when)
  }
  for (nm in c("collection_datetime", "received_datetime")) {
    expect_identical(back$specimen[[nm]], when)
  }
  expect_identical(back$authorization$released_at, when)
  expect_identical(back$subject$date_of_birth, spec$subject$date_of_birth)
  expect_identical(back$events, spec$events)
  # Date-only values are supported by the constructor and retain their class.
  spec$report$created_at <- as.Date("2024-02-29")
  cr_export_report_spec(spec, path)
  expect_identical(cr_import_report_spec(path)$report$created_at, spec$report$created_at)
})

test_that("custom sections and future label names survive JSON round trips", {
  sections <- list(list(title = "One", fields = list(a = "literal", b = 2L)),
                   list(title = "Two", fields = list(c = "other", d = TRUE)))
  path <- withr::local_tempfile(fileext = ".json")
  for (n in 0:2) {
    spec <- cr_report_spec(
      report = list(created_at = as.Date("2026-10-02")),
      authorization = list(authorized_by = "Example"),
      custom_sections = sections[seq_len(n)],
      field_labels = c("report.title" = "Display title", "result.value" = "Result")
    )
    cr_export_report_spec(spec, path)
    back <- cr_import_report_spec(path)
    expect_identical(back$custom_sections, spec$custom_sections)
    expect_identical(back$field_labels, spec$field_labels)
    expect_identical(back$events, spec$events)
    payload <- jsonlite::read_json(path, simplifyVector = FALSE)
    expect_named(payload$field_labels, names(spec$field_labels))
  }
  # Historical unnamed arrays have no recoverable original labels.
  payload$field_labels <- unname(as.list(spec$field_labels))
  jsonlite::write_json(payload, path, auto_unbox = TRUE, null = "null")
  expect_identical(cr_import_report_spec(path)$field_labels, unname(spec$field_labels))
  spec$field_labels <- character()
  cr_export_report_spec(spec, path)
  expect_identical(cr_import_report_spec(path)$field_labels, character())
})
