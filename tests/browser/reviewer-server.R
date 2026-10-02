# Manual anonymous browser gate; starts only an explicit loopback test listener.
library(cellreportR)
d <- Sys.getenv("CELLREPORT_REVIEW_TEST_OUTPUT")
stopifnot(nzchar(d), dir.exists(d))
d <- normalizePath(d)
options(tinytex.install_packages = FALSE)
.review_fixture <- function(claim_count = 2L, figures = TRUE) {
  root <- withr::local_tempdir(.local_envir = parent.frame())
  writeLines(c("id,value", "a,1.25", "b,<unsafe>"), file.path(root, "results.csv"))
  writeBin(charToRaw("%PDF-1.4\nanonymous signature fixture"), file.path(root, "figure.pdf"))
  claims <- stats::setNames(lapply(seq_len(claim_count), function(i) {
    list(table = "results", key = c(id = if (i %% 2) "a" else "b"), column = "value")
  }), if (claim_count) paste0("claim_", seq_len(claim_count)) else character())
  evidence <- cr_report_evidence(root,
    tables = list(results = list(path = "results.csv", format = "csv", key = "id")),
    claims = claims,
    figures = if (figures) list(panel = list(path = "figure.pdf", tables = "results")) else list()
  )
  spec <- cr_report_spec(
    report = list(report_id = "example", title = "Example report"),
    result = list(display_value = "Quoted source values"),
    authorization = list(authorized_by = "Example authority"),
    limitations = "Source identity is not scientific validation."
  )
  list(root = root, report = cr_lab_report_from_evidence(evidence, root, spec))
}


f <- .review_fixture(3)
rejections <- list()
for (field in c("title", "limitations", "nested_tag")) {
  candidate <- f$report
  if (field == "title") candidate$spec$report$title <- shiny::HTML("<em>markup</em>")
  if (field == "limitations") candidate$spec$limitations <- shiny::HTML("<em>markup</em>")
  if (field == "nested_tag") candidate$extra <- list(shiny::tags$script("window.reviewInjection=1"))
  refused <- tryCatch({cr_report_review_app(candidate); FALSE}, error = function(e) TRUE)
  stopifnot(refused)
  rejections[[field]] <- refused
}
jsonlite::write_json(rejections, file.path(d, "markup-rejection.json"), auto_unbox = TRUE)
f$report$spec$report$title <- "Example report <em>literal</em>"
writeLines(f$root, file.path(d, "browser-root.txt"))
writeLines("SIBLING_SECRET_MARKER", file.path(d, "sibling-secret.txt"))
shiny::runApp(cr_report_review_app(f$report), host = "127.0.0.1", port = 18743, launch.browser = FALSE)
