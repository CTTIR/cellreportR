# Laboratory-report workflow. Sensitive free text is never copied to state$log.

.cr_clean_input <- function(x) { if(is.null(x)||!length(x)||all(is.na(x))||!nzchar(trimws(as.character(x)[1L]))) NULL else as.character(x)[1L] }
.cr_parse_datetime <- function(x) { x<-.cr_clean_input(x); if(is.null(x)) return(NULL); z<-as.POSIXct(x,tz="UTC"); if(is.na(z)) x else z }
.cr_lines <- function(x) { x<-.cr_clean_input(x); if(is.null(x)) return(character()); trimws(Filter(nzchar,strsplit(x,"[\r\n]+")[[1L]])) }
.cr_key_values <- function(x) { rows<-.cr_lines(x); if(!length(rows)) return(list()); bits<-strsplit(rows,"\\s*\\|\\s*"); keys<-trimws(vapply(bits,`[[`,character(1),1L)); if(any(!nzchar(keys))||anyDuplicated(keys)) cli::cli_abort("Additional-field labels must be non-empty and unique."); vals<-vapply(bits,function(z) paste(z[-1L],collapse=" | "),character(1)); stats::setNames(as.list(vals),keys) }
.cr_qc_text <- function(x) { rows<-.cr_lines(x); if(!length(rows)) return(cr_report_qc()); bits<-strsplit(rows,"\\s*\\|\\s*"); if(any(lengths(bits)!=4L)) cli::cli_abort("Each QC row must contain exactly four pipe-separated values."); m<-do.call(rbind,bits); cr_report_qc(m[,1],m[,2],m[,3],m[,4],source="manual") }

.cr_spec_from_inputs <- function(input, analysis_value=NULL) {
  if(!is.null(input$lab_logo)) {
    ext<-tolower(tools::file_ext(input$lab_logo$name[[1L]] %||% "")); if(!ext%in%c("png","jpg","jpeg","pdf")) cli::cli_abort("Logo must be a PNG, JPEG, or PDF file.")
    if(!is.null(input$lab_logo$size)&&is.finite(input$lab_logo$size[[1L]])&&input$lab_logo$size[[1L]]>5*1024^2) cli::cli_abort("Logo must not exceed 5 MB.")
  }
  value <- if(identical(input$lab_result_source,"analysis") && !is.null(analysis_value)) analysis_value else input$lab_value
  source <- if(identical(input$lab_result_source,"analysis") && !is.null(analysis_value)) "analysis" else "manual"
  cr_report_spec(
    report=list(title=.cr_clean_input(input$lab_title) %||% "Laboratory Report",report_id=.cr_clean_input(input$lab_id),version=.cr_clean_input(input$lab_version) %||% "1.0",status=.cr_clean_input(input$lab_status) %||% "DRAFT",created_at=if(inherits(input$lab_created,"Date")) input$lab_created else Sys.Date(),supersedes_report_id=.cr_clean_input(input$lab_supersedes),amendment_reason=.cr_clean_input(input$lab_amendment)),
    laboratory=list(name=.cr_clean_input(input$lab_name),department=.cr_clean_input(input$lab_department),address=.cr_clean_input(input$lab_address),telephone=.cr_clean_input(input$lab_phone),email=.cr_clean_input(input$lab_email),accreditation_text=.cr_clean_input(input$lab_accreditation),accreditation_identifier=.cr_clean_input(input$lab_accreditation_id),logo=if(!is.null(input$lab_logo)) input$lab_logo$datapath[[1L]] else NULL),
    subject=list(subject_id=.cr_clean_input(input$lab_subject_id),case_id=.cr_clean_input(input$lab_case_id),order_id=.cr_clean_input(input$lab_order_id),name=.cr_clean_input(input$lab_subject_name),date_of_birth=if(inherits(input$lab_dob,"Date")) input$lab_dob else NULL,sex=.cr_clean_input(input$lab_sex)),
    specimen=list(specimen_id=.cr_clean_input(input$lab_specimen_id),specimen_type=.cr_clean_input(input$lab_specimen_type),collection_datetime=.cr_parse_datetime(input$lab_collection),received_datetime=.cr_parse_datetime(input$lab_received),condition=.cr_clean_input(input$lab_condition),comment=.cr_clean_input(input$lab_specimen_comment)),
    examination=list(name=.cr_clean_input(input$lab_exam_name),short_name=.cr_clean_input(input$lab_short_name),method=.cr_clean_input(input$lab_method),intended_use=.cr_clean_input(input$lab_intended_use),assay_version=.cr_clean_input(input$lab_assay_version),analysis_pipeline_version=.cr_clean_input(input$lab_pipeline_version),qc_ruleset_version=.cr_clean_input(input$lab_qc_version),interpretation_ruleset_version=.cr_clean_input(input$lab_interpretation_version),instrument_id=.cr_clean_input(input$lab_instrument_id),instrument_name=.cr_clean_input(input$lab_instrument_name),instrument_software=.cr_clean_input(input$lab_instrument_software)),
    result=list(value=if(length(value)&&is.numeric(value)&&is.finite(value)) value else NULL,display_value=.cr_clean_input(input$lab_display_value),unit=.cr_clean_input(input$lab_unit),classification=.cr_clean_input(input$lab_classification),reference=.cr_clean_input(input$lab_reference),decision_limit=.cr_clean_input(input$lab_decision_limit),qc_status=.cr_clean_input(input$lab_qc_status),comment=.cr_clean_input(input$lab_result_comment),thresholds={z<-.cr_lines(gsub("\\|","\n",input$lab_thresholds %||% ""));if(length(z)){v<-suppressWarnings(as.numeric(z));if(all(is.finite(v)))v else NULL}else NULL},threshold_labels=.cr_lines(gsub("\\|","\n",input$lab_threshold_labels %||% "")),source=source,classification_source="manual"),
    interpretation=list(summary=.cr_clean_input(input$lab_interpretation_summary),text=.cr_clean_input(input$lab_interpretation_text),recommendation=.cr_clean_input(input$lab_recommendation)),
    limitations=.cr_lines(input$lab_limitations),
    authorization=list(reviewed_by=.cr_clean_input(input$lab_reviewed_by),reviewer_role=.cr_clean_input(input$lab_reviewer_role),authorized_by=.cr_clean_input(input$lab_authorized_by),authorizer_role=.cr_clean_input(input$lab_authorizer_role),released_at=.cr_parse_datetime(input$lab_released_at),electronic_release=.cr_clean_input(input$lab_electronic_release)),
    custom_fields=.cr_key_values(input$lab_custom_fields)
  )
}

.cr_srv_lab_report <- function(input,output,session,ctx) {
  state<-ctx$state
  shiny::observe({
    choices<-c("(none)"="")
    if(is.data.frame(state$effects)) { nums<-names(state$effects)[vapply(state$effects,is.numeric,logical(1))]; if(length(nums)) choices<-c(choices,stats::setNames(nums,nums)) }
    shiny::updateSelectInput(session,"lab_analysis_value",choices=choices)
  })
  shiny::observeEvent(TRUE,{
    s<-state$report_spec
    mapping<-list(lab_title=s$report$title,lab_id=s$report$report_id,lab_version=s$report$version,lab_status=s$report$status,lab_name=s$laboratory$name,lab_department=s$laboratory$department,lab_address=s$laboratory$address,lab_subject_id=s$subject$subject_id,lab_case_id=s$subject$case_id,lab_order_id=s$subject$order_id,lab_specimen_id=s$specimen$specimen_id,lab_specimen_type=s$specimen$specimen_type,lab_exam_name=s$examination$name,lab_short_name=s$examination$short_name,lab_method=s$examination$method,lab_value=s$result$value,lab_display_value=s$result$display_value,lab_unit=s$result$unit,lab_classification=s$result$classification,lab_reference=s$result$reference,lab_qc_status=s$result$qc_status,lab_interpretation_summary=s$interpretation$summary,lab_interpretation_text=s$interpretation$text,lab_recommendation=s$interpretation$recommendation,lab_reviewed_by=s$authorization$reviewed_by,lab_authorized_by=s$authorization$authorized_by,lab_limitations=paste(s$limitations,collapse="\n"),lab_custom_fields=paste(paste(names(s$custom_fields),unlist(s$custom_fields),sep=" | "),collapse="\n"))
    for(id in names(mapping)) if(!is.null(mapping[[id]])) shiny::updateTextInput(session,id,value=as.character(mapping[[id]])[1L])
    shiny::updateSelectInput(session,"lab_status",selected=s$report$status)
    if(inherits(state$report_profile,"cr_report_profile")) {
      sty<-state$report_profile$style
      shiny::updateRadioButtons(session,"lab_colour_mode",selected=sty$mode)
      shiny::updateSelectInput(session,"lab_density",selected=sty$density)
      shiny::updateTextInput(session,"lab_primary_colour",value=sty$primary_colour)
      shiny::updateCheckboxInput(session,"lab_include_audit",value=sty$include_audit_appendix)
      shiny::updateCheckboxInput(session,"lab_signature_lines",value=sty$show_signature_lines)
      shiny::updateCheckboxInput(session,"lab_draft_watermark",value=sty$draft_watermark)
    }
  },once=TRUE)
  analysis_value<-shiny::reactive({ if(!identical(input$lab_result_source,"analysis")||!nzchar(input$lab_analysis_value %||% "")||!is.data.frame(state$effects)) return(NULL); vals<-state$effects[[input$lab_analysis_value]]; vals<-vals[is.finite(vals)]; if(length(vals)) vals[[1L]] else NULL })
  current_spec<-shiny::reactive(.cr_spec_from_inputs(input,analysis_value()))
  current_qc<-shiny::reactive(.cr_qc_text(input$lab_qc_rows))
  shiny::observeEvent(input$btn_lab_use_qc,{
    q<-if(!is.null(state$experiment)) cr_report_qc_from_log(state$experiment) else cr_report_qc()
    txt<-if(nrow(q)) paste(apply(q[c("criterion","observed","acceptance","status")],1,paste,collapse=" | "),collapse="\n") else ""
    shiny::updateTextAreaInput(session,"lab_qc_rows",value=txt);ctx$log("Report QC summary updated from the current QC log.")
  })
  current_style<-shiny::reactive({
    base<-if(inherits(state$report_profile,"cr_report_profile")) state$report_profile$style else cr_report_style()
    cr_report_style(
      paper=input$lab_paper %||% base$paper,
      mode=input$lab_colour_mode %||% base$mode,
      density=input$lab_density %||% base$density,locale=base$locale,
      logo=if(!is.null(input$lab_logo)) input$lab_logo$datapath[[1L]] else base$logo,
      primary_colour=input$lab_primary_colour %||% base$primary_colour,
      secondary_colour=base$secondary_colour,date_format=base$date_format,
      date_time_format=base$date_time_format,labels=base$labels,
      footer_text=base$footer_text,
      include_audit_appendix=isTRUE(input$lab_include_audit),
      show_signature_lines=isTRUE(input$lab_signature_lines),
      draft_watermark=isTRUE(input$lab_draft_watermark))
  })
  current_report<-shiny::reactive({ s<-current_spec(); suppressWarnings(cr_lab_report(state$experiment,s,current_qc(),result_graphic=isTRUE(input$lab_show_result_graphic),include_audit_appendix=isTRUE(input$lab_include_audit),strict=TRUE,style=current_style())) })
  shiny::observeEvent(input$btn_lab_validate,{
    s<-tryCatch(current_spec(),error=function(e) ctx$fail(e,"Report validation")); if(is.null(s)) return(); state$report_spec<-s; state$lab_report<-tryCatch(suppressWarnings(cr_lab_report(state$experiment,s,current_qc(),result_graphic=isTRUE(input$lab_show_result_graphic),include_audit_appendix=isTRUE(input$lab_include_audit),strict=FALSE,style=current_style())),error=function(e) NULL); ctx$log("Report validated.")
  })
  output$lab_validation<-shiny::renderUI({ issues<-tryCatch(cr_validate_report_spec(current_spec(),strict=TRUE,return_issues=TRUE),error=function(e) data.frame(severity="ERROR",field="input",message=conditionMessage(e))); if(!nrow(issues)) return(shiny::div(class="alert alert-success",shiny::strong("PASS "),"Report is structurally ready.")); shiny::tags$ul(lapply(seq_len(nrow(issues)),function(i) shiny::tags$li(shiny::strong(paste(issues$severity[i],issues$field[i])),paste("-",issues$message[i])))) })
  output$lab_exports<-shiny::renderUI({ issues<-tryCatch(cr_validate_report_spec(current_spec(),strict=TRUE,return_issues=TRUE),error=function(e) data.frame(severity="ERROR")); if(any(issues$severity=="ERROR")) return(shiny::div(class="alert alert-secondary","Resolve ERROR items before export.")); shiny::tagList(shiny::downloadButton("dl_lab_pdf","PDF report",class="btn-primary w-100"),shiny::downloadButton("dl_lab_audit","Audit JSON",class="w-100 mt-1"),shiny::downloadButton("dl_lab_spec","Specification JSON",class="w-100 mt-1")) })
  output$lab_preview<-shiny::renderUI({ rep<-tryCatch(suppressWarnings(cr_lab_report(state$experiment,current_spec(),current_qc(),result_graphic=FALSE,strict=FALSE,style=current_style())),error=function(e) NULL); if(is.null(rep)) return(shiny::div(class="alert alert-danger","Preview unavailable: invalid input.")); .cr_report_preview_ui(cr_report_display_data(rep)) })
  output$lab_result_plot<-shiny::renderPlot({ s<-current_spec(); shiny::req(isTRUE(input$lab_show_result_graphic)); p<-.cr_plot_from_spec(s,current_style()); shiny::req(p); p })
  function(){ out<-current_report(); state$report_spec<-out$spec; out }
}

.cr_report_preview_ui <- function(d) {
  first_value <- function(rows,key) { x<-rows$value[rows$key==key]; if(length(x)) x[[1L]] else "" }
  row_text <- function(rows) {
    if (!nrow(rows)) return(shiny::span(class="text-muted","Not supplied"))
    shiny::tags$dl(class="row small mb-0",
      lapply(seq_len(nrow(rows)),function(i) shiny::tagList(
        shiny::tags$dt(class="col-5",rows$label[[i]]),
        shiny::tags$dd(class="col-7",rows$value[[i]]))))
  }
  accent <- if (identical(d$style$mode,"grayscale")) "#3E3E3E" else d$style$primary_colour
  shiny::div(class="bg-white text-dark p-3 border rounded",
    shiny::div(class="d-flex justify-content-between align-items-start",
      shiny::div(shiny::strong(d$report$laboratory_name),
                 shiny::div(class="small text-muted",d$report$department)),
      shiny::div(class="text-end",shiny::tags$small(style=paste0("color:",accent),d$labels[["document_type"]]),
                 shiny::h5(class="mb-0",d$report$title),shiny::strong(style=paste0("color:",accent),d$report$status))),
    shiny::hr(style=paste0("border-color:",accent,";opacity:1")),
    shiny::div(class="small d-flex justify-content-between",
      shiny::span("Report ",shiny::strong(d$report$id)," | v",d$report$version),
      shiny::span(d$report$created)),
    shiny::hr(),shiny::strong(d$labels[["subject_specimen"]]),
    bslib::layout_columns(col_widths=c(6,6),row_text(d$subject),row_text(d$specimen)),
    shiny::hr(),shiny::strong(d$labels[["examination"]]),row_text(d$examination),
    shiny::div(class="mt-3 p-3 border-top border-bottom",
      style=paste0("border-color:",accent,"!important"),
      shiny::tags$small(class="text-uppercase",d$labels[["result"]]),
      shiny::h3(style=paste0("color:",accent),first_value(d$result,"classification")),
      shiny::h5(first_value(d$result,"measured_value")),
      row_text(d$result[!d$result$key%in%c("classification","measured_value"),,drop=FALSE])),
    if(.cr_present(d$interpretation$summary)) shiny::p(class="mt-3 mb-1",shiny::strong(d$interpretation$summary)),
    if(.cr_present(d$interpretation$text)) shiny::p(class="small",d$interpretation$text),
    shiny::hr(),shiny::div(class="small text-muted d-flex justify-content-between",
      shiny::span("Report ",d$report$id," | v",d$report$version," | ",d$report$status),
      shiny::span("Page X of Y")))
}
