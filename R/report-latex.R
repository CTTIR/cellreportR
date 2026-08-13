# LaTeX preparation and layout helpers for laboratory-report template 2.0.

.cr_latex_escape <- function(x) {
  if (is.null(x) || !length(x)) return("")
  x <- as.character(x)
  token <- "CRBACKSLASHTOKEN"
  x <- gsub("\\\\", token, x)
  replacements <- c("&"="\\\\&", "%"="\\\\%", "$"="\\\\$",
                    "#"="\\\\#", "_"="\\\\_", "{"="\\\\{",
                    "}"="\\\\}", "~"="\\\\textasciitilde{}",
                    "^"="\\\\textasciicircum{}")
  for (key in names(replacements)) x <- gsub(key, replacements[[key]], x, fixed=TRUE)
  gsub(token, "\\\\textbackslash{}", x, fixed=TRUE)
}

.cr_tex_command <- function(name, value) {
  paste0("\\renewcommand{\\", name, "}{", .cr_latex_escape(value), "}")
}

.cr_tex_detokenized_path <- function(path) {
  paste0("\\detokenize{", normalizePath(path, winslash="/", mustWork=TRUE), "}")
}

.cr_latex_technical <- function(x) {
  x <- as.character(x)
  if (nchar(x) <= 32L) return(.cr_latex_escape(x))
  starts <- seq.int(1L,nchar(x),by=16L)
  pieces <- substring(x,starts,pmin(starts+15L,nchar(x)))
  paste(vapply(pieces,.cr_latex_escape,character(1)),collapse="\\allowbreak{}")
}

.cr_report_latex_header <- function(display) {
  style <- display$style
  primary <- if (identical(style$mode, "grayscale")) "3E3E3E" else sub("#", "", style$primary_colour)
  secondary <- if (identical(style$mode, "grayscale")) "666666" else sub("#", "", style$secondary_colour)
  lab_contact <- display$laboratory
  lab_contact <- lab_contact[lab_contact$key %in% c("address","telephone","email","website"),,drop=FALSE]
  contact <- paste(lab_contact$value, collapse="  |  ")
  labels <- display$labels
  commands <- c(
    .cr_tex_command("crPrimaryHex", primary),
    .cr_tex_command("crSecondaryHex", secondary),
    .cr_tex_command("crReportTitle", display$report$title),
    .cr_tex_command("crDocumentType", labels[["document_type"]]),
    .cr_tex_command("crReportID", display$report$id),
    .cr_tex_command("crReportVersion", display$report$version),
    .cr_tex_command("crReportStatus", display$report$status),
    .cr_tex_command("crReportCreated", display$report$created),
    .cr_tex_command("crLaboratoryName", display$report$laboratory_name),
    .cr_tex_command("crLaboratoryDepartment", display$report$department),
    .cr_tex_command("crLaboratoryContact", contact),
    .cr_tex_command("crLabelReportID", labels[["report_id"]]),
    .cr_tex_command("crLabelVersion", labels[["version"]]),
    .cr_tex_command("crLabelStatus", labels[["status"]]),
    .cr_tex_command("crLabelCreated", labels[["created_at"]]),
    .cr_tex_command("crLabelPage", labels[["page"]]),
    .cr_tex_command("crLabelOf", labels[["of"]]),
    .cr_tex_command("crLabelReviewedBy", labels[["reviewed_by"]]),
    .cr_tex_command("crLabelAuthorizedBy", labels[["authorized_by"]]),
    .cr_tex_command("crFooterText", style$footer_text %||% ""),
    .cr_tex_command("crPDFCreator", paste("cellreportR", .cr_pkg_version())),
    paste0("\\crcompact", if (identical(style$density,"compact")) "true" else "false"),
    paste0("\\crwatermark", if (isTRUE(display$include$watermark)) "true" else "false")
  )
  if (.cr_present(display$report$logo)) {
    .cr_validate_report_logo(display$report$logo)
    commands <- c(commands, "\\crhaslogotrue",
                  paste0("\\renewcommand{\\crLogoPath}{",
                         .cr_tex_detokenized_path(display$report$logo), "}"))
  }
  if (identical(display$report$status, "AMENDED") && nrow(display$amendment)) {
    commands <- c(commands, "\\cramendedtrue",
      .cr_tex_command("crAmendmentText", paste(
        paste0(display$amendment$label, ": ", display$amendment$value),
        collapse="; ")))
  }
  commands
}

.cr_tex_status <- function(x, mode="colour") {
  value <- toupper(as.character(x))
  colour <- switch(value, PASS="crPass", WARN="crWarn", WARNING="crWarn",
                   FAIL="crFail", ERROR="crFail", INFO="crMuted", "crText")
  if (identical(mode,"grayscale")) colour <- "crText"
  paste0("\\textbf{\\textcolor{", colour, "}{", .cr_latex_escape(x), "}}")
}

.cr_tex_kv <- function(rows, wide=FALSE, technical=character()) {
  if (!nrow(rows)) return("")
  width <- if (wide) "0.28" else "0.31"
  body <- vapply(seq_len(nrow(rows)), function(i) {
    value <- .cr_latex_escape(rows$value[[i]])
    if (rows$key[[i]] %in% technical) value <- paste0("\\crTechnical{", .cr_latex_technical(rows$value[[i]]), "}")
    paste0(.cr_latex_escape(rows$label[[i]]), " & ", value, " \\\\")
  }, character(1))
  spec <- paste0("@{}>{\\raggedright\\arraybackslash\\bfseries\\color{crMuted}}p{",width,"\\linewidth}>{\\raggedright\\arraybackslash}X@{}")
  paste(c("\\begingroup\\setlength{\\tabcolsep}{3pt}\\setlength{\\parskip}{0pt}",
          paste0("\\begin{tabularx}{\\linewidth}{",spec,"}"), body,
          "\\end{tabularx}\\endgroup"), collapse="\n")
}

.cr_tex_long_kv <- function(rows, technical=character()) {
  if (!nrow(rows)) return("")
  body <- vapply(seq_len(nrow(rows)), function(i) {
    value <- .cr_latex_escape(rows$value[[i]])
    if (rows$key[[i]] %in% technical) value <- paste0("\\crTechnical{",.cr_latex_technical(rows$value[[i]]),"}")
    paste0(.cr_latex_escape(rows$label[[i]]), " & ", value, " \\\\")
  }, character(1))
  paste(c("\\begingroup\\setlength{\\LTpre}{0pt}\\setlength{\\LTpost}{0pt}\\setlength{\\tabcolsep}{3pt}\\setlength{\\parskip}{0pt}",
    "\\begin{longtable}{@{}>{\\raggedright\\arraybackslash\\bfseries\\color{crMuted}}p{0.27\\linewidth}>{\\raggedright\\arraybackslash}p{0.69\\linewidth}@{}}",
    body, "\\end{longtable}\\endgroup"), collapse="\n")
}

.cr_tex_qc <- function(qc, labels, mode) {
  if (!nrow(qc)) return("")
  header <- paste(.cr_latex_escape(labels[c("criterion","observed","acceptance")]),
                  collapse=" & ")
  header <- paste0(header, " & ", .cr_latex_escape(labels[["status"]]), " \\\\")
  rows <- vapply(seq_len(nrow(qc)), function(i) paste0(
    .cr_latex_escape(qc$criterion[[i]]), " & ",
    .cr_latex_escape(qc$observed[[i]]), " & ",
    .cr_latex_escape(qc$acceptance[[i]]), " & ",
    .cr_tex_status(qc$status[[i]], mode), " \\\\"), character(1))
  paste(c("\\begingroup\\setlength{\\LTpre}{0pt}\\setlength{\\LTpost}{0pt}\\setlength{\\tabcolsep}{3pt}\\setlength{\\parskip}{0pt}\\small",
    "\\begin{longtable}{@{}>{\\raggedright\\arraybackslash}p{0.22\\linewidth}>{\\raggedright\\arraybackslash}p{0.22\\linewidth}>{\\raggedright\\arraybackslash}p{0.37\\linewidth}>{\\raggedright\\arraybackslash}p{0.11\\linewidth}@{}}",
    "\\toprule", header, "\\midrule", rows, "\\bottomrule",
    "\\end{longtable}\\endgroup"), collapse="\n")
}

.cr_tex_section <- function(title, bookmark=NULL) {
  bm <- if (!is.null(bookmark)) paste0("\\pdfbookmark[1]{",.cr_latex_escape(title),"}{",bookmark,"}\n") else ""
  paste0(bm, "\\crSection{", .cr_latex_escape(title), "}\n")
}

.cr_report_latex_body <- function(display, result_graphic_path=NULL) {
  l <- display$labels
  parts <- c("\\thispagestyle{crfirst}", "\\crFirstPageHeader")
  if (nrow(display$subject) || nrow(display$specimen)) {
    two_column <- paste0(
      "\\noindent\\begin{minipage}[t]{0.485\\textwidth}\n",
      "\\crSubsection{",.cr_latex_escape(l[["subject_case"]]),"}\n",
      .cr_tex_kv(display$subject),
      "\n\\end{minipage}\\hfill\\begin{minipage}[t]{0.485\\textwidth}\n",
      "\\crSubsection{",.cr_latex_escape(l[["specimen"]]),"}\n",
      .cr_tex_kv(display$specimen),"\n\\end{minipage}\\par")
    parts <- c(parts, .cr_tex_section(l[["subject_specimen"]]), two_column)
  }
  if (nrow(display$examination)) {
    parts <- c(parts, .cr_tex_section(l[["examination"]],"examination"),
               .cr_tex_kv(display$examination, wide=TRUE))
  }
  rr <- display$result
  first_result <- function(key) {
    value <- rr$value[rr$key==key]
    if (length(value)) value[[1L]] else ""
  }
  classification <- first_result("classification")
  measured <- first_result("measured_value")
  result_meta <- rr[!rr$key %in% c("classification","measured_value"),,drop=FALSE]
  if (nrow(result_meta) && any(result_meta$key=="qc_status")) {
    idx <- which(result_meta$key=="qc_status")
    result_meta$value[idx] <- paste0("CRSTATUS:", result_meta$value[idx])
  }
  result_rows <- if (nrow(result_meta)) vapply(seq_len(nrow(result_meta)), function(i) {
    val <- result_meta$value[[i]]
    val <- if (startsWith(val,"CRSTATUS:")) .cr_tex_status(sub("^CRSTATUS:","",val),display$style$mode) else .cr_latex_escape(val)
    paste0(.cr_latex_escape(result_meta$label[[i]])," & ",val," \\\\")
  }, character(1)) else character()
  result_summary <- c(
    "\\noindent\\begin{minipage}[t]{0.37\\linewidth}\\vspace{0pt}",
    paste0("\\crResultClassification{",.cr_latex_escape(classification),"}"),
    if(nzchar(measured)) paste0("\\crResultValue{",.cr_latex_escape(measured),"}") else NULL,
    "\\end{minipage}\\hfill\\begin{minipage}[t]{0.59\\linewidth}\\vspace{0pt}",
    if(length(result_rows)) c("\\begingroup\\setlength{\\tabcolsep}{3pt}\\setlength{\\parskip}{0pt}",
      "\\begin{tabularx}{\\linewidth}{@{}>{\\bfseries\\color{crMuted}}p{0.31\\linewidth}X@{}}",
      result_rows,"\\end{tabularx}\\endgroup") else NULL,
    "\\end{minipage}\\par")
  parts <- c(parts, .cr_tex_section(l[["result"]],"result"),
    "\\begin{crresult}",result_summary)
  if (!is.null(result_graphic_path) && file.exists(result_graphic_path)) {
    parts <- c(parts, "\\vspace{1.0mm}", paste0("\\includegraphics[width=\\linewidth,height=21mm,keepaspectratio]{",.cr_tex_detokenized_path(result_graphic_path),"}"))
  }
  parts <- c(parts,"\\end{crresult}")
  it <- display$interpretation
  if (any(vapply(it,.cr_present,logical(1)))) {
    parts <- c(parts,.cr_tex_section(l[["interpretation"]],"interpretation"))
    if (.cr_present(it$summary)) parts <- c(parts,paste0("\\crInterpretationSummary{",.cr_latex_escape(it$summary),"}"))
    if (.cr_present(it$text)) parts <- c(parts,paste0("\\crPlainText{",.cr_latex_escape(it$text),"}"))
    if (.cr_present(it$recommendation)) parts <- c(parts,
      paste0("\\crSubsection{",.cr_latex_escape(l[["recommendation"]]),"}"),
      paste0("\\crPlainText{",.cr_latex_escape(it$recommendation),"}"))
    if (.cr_present(it$comment)) parts <- c(parts,paste0("\\crPlainText{",.cr_latex_escape(it$comment),"}"))
  }
  # A controlled report has a deliberate human-readable page boundary.
  parts <- c(parts,"\\crBeginSecondPage")
  if (nrow(display$qc)) parts <- c(parts,.cr_tex_section(l[["quality_control"]],"quality-control"),.cr_tex_qc(display$qc,l,display$style$mode))
  if (nrow(display$traceability)) parts <- c(parts,.cr_tex_section(l[["traceability"]],"traceability"),.cr_tex_kv(display$traceability,wide=TRUE))
  if (length(display$limitations)) {
    items <- paste0("\\item ",.cr_latex_escape(display$limitations))
    parts <- c(parts,.cr_tex_section(l[["limitations"]],"limitations"),"\\begin{crlimitations}",items,"\\end{crlimitations}")
  }
  if (nrow(display$custom_fields)) parts <- c(parts,
    .cr_tex_section(l[["additional_information"]],"additional-information"),
    if(nrow(display$custom_fields)>6L) .cr_tex_long_kv(display$custom_fields) else .cr_tex_kv(display$custom_fields,wide=TRUE))
  for (i in seq_along(display$custom_sections)) {
    section <- display$custom_sections[[i]]
    if (nrow(section$rows)) parts <- c(parts,.cr_tex_section(section$title),
      if(nrow(section$rows)>6L) .cr_tex_long_kv(section$rows) else .cr_tex_kv(section$rows,wide=TRUE))
  }
  if (nrow(display$authorization)) {
    parts <- c(parts,"\\Needspace{11\\baselineskip}",
      .cr_tex_section(l[["authorization"]],"authorization"),"\\begin{crauthorization}",
      .cr_tex_kv(display$authorization,wide=TRUE))
    if (isTRUE(display$include$signature_lines)) parts <- c(parts,"\\crSignatureLines")
    release_values <- display$authorization$value[
      display$authorization$key == "electronic_release"]
    if (.cr_present(display$style$footer_text) &&
        !identical(display$style$footer_text, release_values %||% NULL)) parts <- c(parts,
      paste0("\\crReleaseStatement{",.cr_latex_escape(display$style$footer_text),"}"))
    parts <- c(parts,"\\end{crauthorization}")
  }
  if (isTRUE(display$include$audit_appendix)) {
    tech <- c("report_data_hash","design_hash","provenance_hash","schema","template")
    parts <- c(parts,"\\clearpage",paste0("\\crAppendixHeading{",.cr_latex_escape(l[["audit_appendix"]]),"}{",.cr_latex_escape(l[["audit_title"]]),"}"),.cr_tex_long_kv(display$audit,technical=tech))
  }
  paste(parts,collapse="\n\n")
}

.cr_lab_pdf_preflight <- function(report, output_file, template, logo=NULL) {
  if (!rmarkdown::pandoc_available()) cli::cli_abort("Pandoc is required to render laboratory reports.")
  if (!nzchar(Sys.which("xelatex"))) cli::cli_abort("XeLaTeX is required for Unicode laboratory-report PDFs.")
  if (!file.exists(template)) cli::cli_abort("Laboratory LaTeX template not found: {.path {template}}")
  needed <- c("scrartcl.cls","scrlayer-scrpage.sty","booktabs.sty","tabularx.sty",
              "longtable.sty","microtype.sty","needspace.sty","lastpage.sty",
              "fontspec.sty","draftwatermark.sty")
  found <- vapply(needed,function(x) {
    ans <- suppressWarnings(system2("kpsewhich",x,stdout=TRUE,stderr=FALSE))
    if (length(ans)) ans[[1L]] else ""
  },character(1))
  missing <- needed[!nzchar(found)]
  if (length(missing)) cli::cli_abort("Required LaTeX components are missing: {.val {missing}}.")
  if (!is.null(logo)) .cr_validate_report_logo(logo)
  parent <- dirname(output_file)
  if (!dir.exists(parent)) dir.create(parent,recursive=TRUE,showWarnings=FALSE)
  if (file.access(parent,2L)!=0L) cli::cli_abort("Output directory is not writable: {.path {parent}}")
  invisible(TRUE)
}
