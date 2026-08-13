# Laboratory report assembly, serialization, provenance and rendering.

#' Assemble a laboratory report without recalculating analytical values
#' @param experiment Optional validated `cr_experiment`; it is retained by reference semantics of ordinary R lists and never modified.
#' @param spec A `cr_report_spec`.
#' @param qc Optional concise QC table from [cr_report_qc()].
#' @param result_graphic Optional precomputed plot, or `TRUE` to build one from result thresholds when possible.
#' @param include_audit_appendix Include a compact audit appendix in the rendered document.
#' @param strict Apply strict specification validation.
#' @param style A [cr_plot_style()] used by embedded report figures.
#' @export
cr_lab_report <- function(experiment=NULL, spec=cr_report_spec(), qc=NULL,
                          result_graphic=FALSE, include_audit_appendix=FALSE,
                          strict=TRUE, style=cr_plot_style(variant="report")) {
  cr_validate_report_spec(spec, strict=strict)
  if (!is.null(experiment)) cr_validate_experiment(experiment)
  if (is.null(qc)) qc <- if (!is.null(experiment)) cr_report_qc_from_log(experiment) else cr_report_qc()
  cr_validate_report_qc(qc)
  plot <- if (inherits(result_graphic,"ggplot")) result_graphic else NULL
  if (isTRUE(result_graphic)) plot <- .cr_plot_from_spec(spec, style)
  obj <- list(spec=spec, qc=tibble::as_tibble(qc), experiment=experiment,
    result_graphic=plot, include_audit_appendix=isTRUE(include_audit_appendix),
    style=style,
    template_name="laboratory-report", template_version="1.0",
    events=.cr_report_event("report_assembled","INFO","report"))
  class(obj) <- c("cr_lab_report","list"); obj
}

.cr_plot_from_spec <- function(spec, style=cr_plot_style(variant="report")) {
  r <- spec$result
  if (!is.numeric(r$value) || length(r$value)!=1L || !is.finite(r$value)) return(NULL)
  bounds <- r$thresholds %||% NULL
  if (is.null(bounds) || !is.numeric(bounds) || !length(bounds)) return(NULL)
  cr_plot_result_position(r$value, bounds, labels=r$threshold_labels %||% NULL,
                          unit=r$unit %||% NULL,
                          classification=r$classification %||% NULL,
                          mode=style$mode, style=style)
}

#' Inspect the exact structured values entering a laboratory report
#' @param report A `cr_lab_report`.
#' @export
cr_report_data <- function(report) {
  if(!inherits(report,"cr_lab_report")) cli::cli_abort("{.arg report} must be a {.cls cr_lab_report}.")
  list(schema_name=report$spec$schema_name, schema_version=report$spec$schema_version,
    template_name=report$template_name, template_version=report$template_version,
    spec=unclass(report$spec), qc=as.data.frame(report$qc), style=unclass(report$style))
}

#' Hash report-relevant structured data
#' @param x Any R object.
#' @param algorithm Algorithm supported by [digest::digest()], default SHA-256.
#' @export
cr_report_hash <- function(x, algorithm="sha256") digest::digest(.cr_canonical(x), algo=algorithm, serialize=TRUE)

.cr_canonical <- function(x) {
  if (inherits(x,"cr_report_spec")) { x <- unclass(x); x$events <- NULL }
  if (inherits(x,"cr_lab_report")) x <- cr_report_data(x)
  if (inherits(x,"POSIXt")) return(format(x, "%Y-%m-%dT%H:%M:%OS6%z"))
  if (inherits(x,"Date")) return(format(x, "%Y-%m-%d"))
  if (is.data.frame(x)) { rownames(x)<-NULL; return(lapply(x,.cr_canonical)) }
  if (is.list(x)) { if(!is.null(names(x))) x<-x[order(names(x))]; return(lapply(x,.cr_canonical)) }
  x
}

#' Build machine-readable report provenance
#' @param experiment Optional `cr_experiment`.
#' @param report_spec A `cr_report_spec` or `cr_lab_report`.
#' @param output_file Optional rendered file whose byte hash is recorded.
#' @param analysis_metadata Optional concise metadata about upstream result objects.
#' @export
cr_report_provenance <- function(experiment=NULL, report_spec, output_file=NULL, analysis_metadata=list()) {
  report <- if(inherits(report_spec,"cr_lab_report")) report_spec else cr_lab_report(experiment, report_spec, strict=FALSE)
  spec <- report$spec; exp_summary <- NULL
  if(!is.null(experiment)) {
    cr_validate_experiment(experiment)
    exp_summary <- list(n_source_files=if(is.data.frame(experiment$provenance)) nrow(experiment$provenance) else NA_integer_, n_cells=nrow(experiment$cells), n_units=length(unique(experiment$cells[[experiment$spatial_unit]])), unit_var=experiment$unit_var %||% experiment$spatial_unit, spatial_unit=experiment$spatial_unit, batch_vars=experiment$batch_vars %||% character(), qc_steps=if(nrow(experiment$qc_log)) as.character(experiment$qc_log$step) else character(), provenance_hash=if(!is.null(experiment$provenance)) cr_report_hash(experiment$provenance) else NA_character_, design_hash=cr_report_hash(experiment$design))
  }
  list(schema="cellreportR-report-audit", schema_version="1.0",
    report=list(report_id=spec$report$report_id %||% NA_character_, version=spec$report$version %||% NA_character_, status=spec$report$status %||% NA_character_, created_at=.cr_iso(spec$report$created_at), template_name=report$template_name, template_version=report$template_version, report_data_hash=cr_report_hash(report)),
    software=list(package="cellreportR", package_version=as.character(utils::packageVersion("cellreportR")), r_version=R.version.string, platform=R.version$platform),
    versions=list(analysis_pipeline=spec$examination$analysis_pipeline_version %||% NA_character_, qc_ruleset=spec$examination$qc_ruleset_version %||% NA_character_, interpretation_ruleset=spec$examination$interpretation_ruleset_version %||% NA_character_),
    result_source=spec$result$source %||% NA_character_, classification_source=spec$result$classification_source %||% NA_character_, experiment=exp_summary, qc=as.data.frame(report$qc), analysis_metadata=analysis_metadata, output_file_hash=if(!is.null(output_file)&&file.exists(output_file)) digest::digest(file=output_file,algo="sha256") else NA_character_, events=rbind(spec$events, report$events))
}

.cr_iso <- function(x) { if(is.null(x)||!length(x)) return(NA_character_); if(inherits(x,"POSIXt")) format(x,"%Y-%m-%dT%H:%M:%S%z") else if(inherits(x,"Date")) format(x,"%Y-%m-%d") else as.character(x) }

#' Export a report specification as versioned JSON
#' @param spec A `cr_report_spec`.
#' @param path Output JSON path.
#' @param pretty Pretty-print JSON.
#' @export
cr_export_report_spec <- function(spec,path,pretty=TRUE) { cr_validate_report_spec(spec,strict=FALSE); .cr_check_path(path); jsonlite::write_json(.cr_json_ready(unclass(spec)),path,pretty=pretty,auto_unbox=TRUE,null="null",na="null"); invisible(path) }

#' Import a versioned report specification from JSON
#' @param path Input JSON path.
#' @param validate Validate the reconstructed specification.
#' @export
cr_import_report_spec <- function(path,validate=TRUE) {
  .cr_check_path(path); x<-jsonlite::read_json(path,simplifyVector=TRUE)
  if(!identical(x$schema_name,"cellreportR-report-spec")) cli::cli_abort("Unsupported report specification schema.")
  for(nm in c("created_at","analysis_completed_at","released_at")) if(is.character(x$report[[nm]])&&length(x$report[[nm]])==1L) x$report[[nm]]<-as.POSIXct(x$report[[nm]],tz="UTC")
  if(is.character(x$subject$date_of_birth)&&length(x$subject$date_of_birth)==1L) x$subject$date_of_birth<-as.Date(x$subject$date_of_birth)
  for(nm in c("collection_datetime","received_datetime")) if(is.character(x$specimen[[nm]])&&length(x$specimen[[nm]])==1L) x$specimen[[nm]]<-as.POSIXct(x$specimen[[nm]],tz="UTC")
  if(is.character(x$authorization$released_at)&&length(x$authorization$released_at)==1L) x$authorization$released_at<-as.POSIXct(x$authorization$released_at,tz="UTC")
  obj<-cr_report_spec(report=as.list(x$report %||% list()),laboratory=as.list(x$laboratory %||% list()),subject=as.list(x$subject %||% list()),specimen=as.list(x$specimen %||% list()),examination=as.list(x$examination %||% list()),result=as.list(x$result %||% list()),interpretation=as.list(x$interpretation %||% list()),limitations=as.character(x$limitations %||% character()),authorization=as.list(x$authorization %||% list()),custom_fields=as.list(x$custom_fields %||% list()),custom_sections=x$custom_sections %||% list(),required_fields=as.character(x$required_fields %||% character()),field_labels=as.character(x$field_labels %||% character()),schema_version=x$schema_version)
  obj$events<-.cr_events_df(x$events); if(validate) cr_validate_report_spec(obj,strict=FALSE); obj
}

.cr_events_df <- function(x) { if(is.null(x)) return(.cr_report_event("report_spec_imported","INFO","specification")); if(is.data.frame(x)) return(x); as.data.frame(x,stringsAsFactors=FALSE) }
.cr_json_ready <- function(x) { if(inherits(x,"POSIXt")) return(.cr_iso(x)); if(inherits(x,"Date")) return(.cr_iso(x)); if(is.data.frame(x)) return(lapply(seq_len(nrow(x)),function(i) .cr_json_ready(as.list(x[i,,drop=FALSE])))); if(is.list(x)) return(lapply(x,.cr_json_ready)); if(length(x)==0L) NULL else x }

#' Export report audit provenance as JSON
#' @param report A `cr_lab_report`.
#' @param path Output JSON path.
#' @param output_file Optional rendered file to hash.
#' @export
cr_export_report_audit <- function(report,path,output_file=NULL) { if(!inherits(report,"cr_lab_report")) cli::cli_abort("{.arg report} must be a {.cls cr_lab_report}."); audit<-cr_report_provenance(report$experiment,report,output_file); jsonlite::write_json(.cr_json_ready(audit),path,pretty=TRUE,auto_unbox=TRUE,null="null",na="null"); invisible(path) }

#' Plot a value relative to caller-supplied boundaries
#' @param value Single finite numeric value.
#' @param thresholds One or more sorted finite boundaries.
#' @param labels Optional labels for the resulting intervals; must have one more item than thresholds.
#' @param xlim Optional two-value display range.
#' @param unit,classification Optional user-supplied marker labels.
#' @param show_value Include the numeric value below the marker.
#' @param mode Colour or grayscale rendering.
#' @param style Optional [cr_plot_style()].
#' @export
cr_plot_result_position <- function(value,thresholds,labels=NULL,xlim=NULL,
                                    unit=NULL,classification=NULL,
                                    show_value=TRUE,
                                    mode=c("colour","grayscale"),
                                    style=NULL) {
  mode<-match.arg(mode); style<-style %||% cr_plot_style(mode=mode,variant="report")
  if(!is.numeric(value)||length(value)!=1L||!is.finite(value)) cli::cli_abort("{.arg value} must be one finite number.")
  if(!is.numeric(thresholds)||!length(thresholds)||any(!is.finite(thresholds))||is.unsorted(thresholds,strictly=TRUE)) cli::cli_abort("{.arg thresholds} must be finite and strictly increasing.")
  if(is.null(labels)) labels<-paste("Category",seq_len(length(thresholds)+1L)); if(length(labels)!=length(thresholds)+1L) cli::cli_abort("{.arg labels} must contain one label per interval.")
  if(is.null(xlim)) { span<-diff(range(c(value,thresholds))); if(!is.finite(span)||span==0) span<-max(abs(value),1); xlim<-range(c(value,thresholds))+c(-.15,.15)*span }
  mids <- c((xlim[1]+thresholds[1])/2, if(length(thresholds)>1) (thresholds[-length(thresholds)]+thresholds[-1])/2, (utils::tail(thresholds,1)+xlim[2])/2)
  marker<-paste(c(if(show_value) format(value,trim=TRUE),unit,classification),collapse=" ")
  ggplot2::ggplot(data.frame(x=value,y=0),ggplot2::aes(x=.data$x,y=.data$y))+ggplot2::geom_segment(ggplot2::aes(x=xlim[1],xend=xlim[2],y=0,yend=0),linewidth=.7,colour="grey25")+ggplot2::geom_vline(xintercept=thresholds,linetype="dashed",colour="grey45",linewidth=.45)+ggplot2::geom_point(size=4,shape=21,fill=if(mode=="colour") unname(cr_palette(1)) else "grey35",colour="black",stroke=1.1)+ggplot2::annotate("text",x=mids,y=.12,label=labels,size=style$base_size/2.845)+ggplot2::annotate("text",x=value,y=-.12,label=marker,size=style$base_size/2.845,fontface="bold")+ggplot2::coord_cartesian(xlim=xlim,ylim=c(-.2,.2),clip="off")+ggplot2::labs(x=NULL,y=NULL)+ggplot2::theme_void(base_family=style$base_family,base_size=style$base_size)+ggplot2::theme(plot.margin=ggplot2::margin(5,8,5,8))
}

#' Render a concise laboratory report
#' @param report A `cr_lab_report`.
#' @param output_file Explicit output file ending in `.pdf` or `.html`.
#' @param template Optional R Markdown template.
#' @param quiet Passed to [rmarkdown::render()].
#' @param audit_file Optional JSON audit path written after rendering.
#' @param overwrite Replace an existing output file. Defaults to `FALSE`, so
#'   released or draft reports are never silently replaced.
#' @export
cr_render_lab_report <- function(report,output_file,template=NULL,quiet=TRUE,audit_file=NULL,overwrite=FALSE) {
  if(!inherits(report,"cr_lab_report")) cli::cli_abort("{.arg report} must be a {.cls cr_lab_report}.")
  cr_validate_report_spec(report$spec,strict=TRUE); cr_validate_report_qc(report$qc)
  .cr_check_path(output_file); ext<-tolower(tools::file_ext(output_file)); if(!ext%in%c("pdf","html")) cli::cli_abort("Laboratory reports support explicit {.val pdf} or {.val html} output files.")
  if(file.exists(output_file)&&!isTRUE(overwrite)) cli::cli_abort("Output already exists: {.path {output_file}}. Set {.arg overwrite = TRUE} explicitly to replace it.")
  if(!requireNamespace("rmarkdown",quietly=TRUE)||!requireNamespace("knitr",quietly=TRUE)) cli::cli_abort("Rendering requires {.pkg rmarkdown} and {.pkg knitr}.")
  if(!rmarkdown::pandoc_available()) cli::cli_abort("Pandoc is required to render laboratory reports.")
  if(is.null(template)) template<-system.file("rmd","laboratory-report.Rmd",package="cellreportR"); if(!nzchar(template)||!file.exists(template)) cli::cli_abort("Laboratory report template not found: {.path {template}}")
  dir.create(dirname(output_file),recursive=TRUE,showWarnings=FALSE); work<-tempfile("cr_lab_report_",fileext=".Rmd",tmpdir=dirname(output_file)); on.exit(unlink(work),add=TRUE); file.copy(template,work,overwrite=TRUE)
  rendered <- rmarkdown::render(work,output_format=if(ext=="pdf") "pdf_document" else "html_document",output_file=basename(output_file),output_dir=dirname(output_file),params=list(report=report),envir=new.env(parent=globalenv()),quiet=quiet)
  if(!identical(normalizePath(rendered,mustWork=FALSE),normalizePath(output_file,mustWork=FALSE))) file.copy(rendered,output_file,overwrite=TRUE)
  if(!is.null(audit_file)) cr_export_report_audit(report,audit_file,output_file)
  invisible(output_file)
}

#' @export
print.cr_lab_report <- function(x,...) { cat("<cr_lab_report>\n  Report:",x$spec$report$report_id %||% "(unset)","version",x$spec$report$version,"[",x$spec$report$status,"]\n  QC rows:",nrow(x$qc),"\n"); invisible(x) }

.cr_display <- function(x) { if(!.cr_present(x)) return(NULL); paste(as.character(x),collapse=", ") }
.cr_markdown_escape <- function(x) gsub("([\\\\`*_{}\\[\\]()#+.!|<>$%&])", "\\\\\\1", as.character(x), perl=TRUE)
.cr_pairs <- function(x, labels=NULL) {
  keep<-vapply(x,.cr_present,logical(1)); x<-x[keep]; if(!length(x)) return(data.frame())
  nms<-names(x); if(!is.null(labels)) nms<-ifelse(nms%in%names(labels),labels[nms],nms)
  data.frame(Field=gsub("_"," ",tools::toTitleCase(nms)),Value=vapply(x,.cr_display,character(1)),check.names=FALSE,row.names=NULL)
}
