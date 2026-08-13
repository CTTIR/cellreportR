# Publication and report visual-system extensions.

#' Construct a reusable plot style
#' @param mode `"colour"` or `"grayscale"`.
#' @param variant `"publication"` or compact `"report"`.
#' @param base_size Font size in points; values below 8 are rejected.
#' @param base_family System-safe font family.
#' @param palette Optional named qualitative palette.
#' @param shapes Optional named shape mapping.
#' @param linetypes Optional named line-type mapping.
#' @param legend_position Legend position.
#' @export
cr_plot_style <- function(mode=c("colour","grayscale"),variant=c("publication","report"),base_size=9,base_family="sans",palette=NULL,shapes=NULL,linetypes=NULL,legend_position="bottom") {
  mode<-match.arg(mode);variant<-match.arg(variant);if(!is.numeric(base_size)||length(base_size)!=1L||base_size<8) cli::cli_abort("{.arg base_size} must be at least 8 pt.")
  structure(list(mode=mode,variant=variant,base_size=base_size,base_family=base_family,palette=palette %||% cr_palette(mode=mode),shapes=shapes %||% cr_shapes(),linetypes=linetypes %||% cr_linetypes(),legend_position=legend_position),class="cr_plot_style")
}

#' Stable line types for categorical figures
#' @param n Number required, at most six.
#' @param names Optional category names.
#' @export
cr_linetypes <- function(n=NULL,names=NULL) { vals<-c("solid","dashed","dotdash","dotted","longdash","twodash"); if(!is.null(n)){if(n>length(vals)) cli::cli_warn("More than six line types requested; prefer facets or direct labels.");vals<-rep(vals,length.out=n)};if(!is.null(names)){if(length(names)!=length(vals)) cli::cli_abort("{.arg names} must match the line-type count.");names(vals)<-names};vals }

#' Manual colour scale from the cellreportR visual system
#' @param values Optional named values.
#' @param mode Colour mode.
#' @param ... Passed to `ggplot2::scale_colour_manual()`.
#' @export
cr_scale_colour <- function(values=NULL,mode=c("colour","grayscale"),...) { mode<-match.arg(mode);ggplot2::scale_colour_manual(values=values %||% cr_palette(mode=mode),...) }
#' @rdname cr_scale_colour
#' @export
cr_scale_fill <- function(values=NULL,mode=c("colour","grayscale"),...) { mode<-match.arg(mode);ggplot2::scale_fill_manual(values=values %||% cr_palette(mode=mode),...) }
#' @rdname cr_scale_colour
#' @export
cr_shape_scale <- function(values=NULL,...) ggplot2::scale_shape_manual(values=values %||% cr_shapes(),...)
#' @rdname cr_scale_colour
#' @export
cr_linetype_scale <- function(values=NULL,...) ggplot2::scale_linetype_manual(values=values %||% cr_linetypes(),...)

#' Continuous diverging scale
#' @param midpoint Explicit neutral midpoint.
#' @param aesthetics `"colour"` or `"fill"`.
#' @param mode Colour mode.
#' @param ... Passed to the gradient scale.
#' @export
cr_scale_diverging <- function(midpoint=0,aesthetics=c("colour","fill"),mode=c("colour","grayscale"),...) { aesthetics<-match.arg(aesthetics);mode<-match.arg(mode);cols<-cr_palette(3,"diverging",mode=mode);fun<-if(aesthetics=="colour") ggplot2::scale_colour_gradient2 else ggplot2::scale_fill_gradient2;fun(low=cols[1],mid=cols[2],high=cols[3],midpoint=midpoint,...) }

#' Standard deterministic figure dimensions
#' @param size One of `single`, `double`, `report`, or `square`.
#' @param units `"mm"` or `"in"`.
#' @export
cr_figure_size <- function(size=c("single","double","report","square"),units=c("mm","in")) { size<-match.arg(size);units<-match.arg(units);z<-switch(size,single=c(width=85,height=60),double=c(width=175,height=105),report=c(width=160,height=90),square=c(width=100,height=100));if(units=="in") z<-z/25.4;structure(as.list(z),units=units) }

#' Save a publication-ready figure deterministically
#' @param plot A ggplot object.
#' @param filename Explicit PDF, SVG, PNG, TIFF or TIF filename.
#' @param size Standard size name or numeric width/height.
#' @param dpi Raster resolution.
#' @param background Explicit background.
#' @param metadata Optional list written to a JSON sidecar.
#' @export
cr_save_figure <- function(plot,filename,size=c("single","double","report","square"),dpi=600,background="white",metadata=NULL) {
  if(!inherits(plot,"ggplot")) cli::cli_abort("{.arg plot} must be a ggplot object.");.cr_check_path(filename);ext<-tolower(tools::file_ext(filename));if(!ext%in%c("pdf","svg","png","tiff","tif")) cli::cli_abort("Supported figure formats are PDF, SVG, PNG and TIFF.")
  dims<-if(is.character(size)) cr_figure_size(match.arg(size),"mm") else {if(!is.numeric(size)||length(size)!=2L) cli::cli_abort("Numeric {.arg size} must be width and height in millimetres.");as.list(stats::setNames(size,c("width","height")))}
  if(dims$width<40||dims$height<30) cli::cli_warn("Very small output dimensions may make text illegible.")
  args<-list(filename=filename,plot=plot,width=dims$width,height=dims$height,units="mm",dpi=dpi,bg=background)
  if(ext%in%c("tiff","tif")) args$compression<-"lzw"
  do.call(ggplot2::ggsave,args)
  if(!is.null(metadata)){sidecar<-paste0(filename,".json");payload<-c(list(schema="cellreportR-figure",schema_version="1.0",created_at=.cr_iso(Sys.time()),package_version=as.character(utils::packageVersion("cellreportR")),file_hash=digest::digest(file=filename,algo="sha256")),metadata);jsonlite::write_json(.cr_json_ready(payload),sidecar,pretty=TRUE,auto_unbox=TRUE,na="null",null="null")}
  invisible(filename)
}

#' Plot estimates and confidence intervals
#' @param data Data frame of finalized estimates.
#' @param estimate,lower,upper,label Column names.
#' @param group Optional grouping column, redundantly encoded by colour and shape.
#' @param reference Optional explicit reference value.
#' @param order_by `design`, `estimate`, or `name`.
#' @param colour_mode Colour mode.
#' @param style Optional `cr_plot_style`.
#' @export
cr_plot_estimates <- function(data,estimate="estimate",lower="conf_low",upper="conf_high",label="group",group=NULL,reference=0,order_by=c("design","estimate","name"),colour_mode=c("colour","grayscale"),style=NULL) {
  order_by<-match.arg(order_by);colour_mode<-match.arg(colour_mode);df<-tibble::as_tibble(data);.cr_need_cols(df,c(estimate,lower,upper,label,group));labs<-as.character(df[[label]]);levels<-if(is.factor(df[[label]])) levels(df[[label]]) else unique(labs);if(order_by=="estimate") levels<-labs[order(df[[estimate]])] else if(order_by=="name") levels<-sort(unique(labs));df$.cr_label<-factor(labs,levels=unique(levels));df$.cr_group<-if(is.null(group)) "Estimate" else as.character(df[[group]])
  p<-ggplot2::ggplot(df,ggplot2::aes(x=.data[[estimate]],y=.data$.cr_label,colour=.data$.cr_group,shape=.data$.cr_group))+ggplot2::geom_errorbar(ggplot2::aes(xmin=.data[[lower]],xmax=.data[[upper]]),width=.16,linewidth=.6,orientation="y")+ggplot2::geom_point(size=2.4,stroke=.8)
  if(!is.null(reference)) p<-p+ggplot2::geom_vline(xintercept=reference,colour="grey35",linetype="dashed",linewidth=.45)
  sty<-style %||% cr_plot_style(mode=colour_mode);p+cr_scale_group(c("colour","shape"),name=if(is.null(group)) NULL else group,guide_for=if(is.null(group)) "none" else "all",mode=sty$mode)+ggplot2::labs(x="Estimate (95% CI)",y=NULL,colour=group,shape=group)+cr_theme(sty$base_size,sty$base_family,legend_position=sty$legend_position,variant=sty$variant,mode=sty$mode)
}

#' Compact text-first QC status plot
#' @param qc A report QC table.
#' @param mode Colour mode.
#' @export
cr_plot_qc_summary <- function(qc,mode=c("colour","grayscale")) { mode<-match.arg(mode);cr_validate_report_qc(qc);d<-tibble::as_tibble(qc);d$.row<-rev(seq_len(nrow(d)));status_cols<-if(mode=="colour") c(PASS="#2F6B68",WARN="#B06A00",FAIL="#A33B32",INFO="#536878") else c(PASS="#303030",WARN="#666666",FAIL="#111111",INFO="#888888");ggplot2::ggplot(d,ggplot2::aes(x=0,y=.data$.row))+ggplot2::geom_point(ggplot2::aes(shape=.data$status,colour=.data$status),size=3,stroke=1)+ggplot2::geom_text(ggplot2::aes(x=.08,label=.data$criterion),hjust=0,size=3)+ggplot2::geom_text(ggplot2::aes(x=.92,label=.data$status),hjust=1,fontface="bold",size=3)+ggplot2::scale_colour_manual(values=status_cols)+cr_shape_scale()+ggplot2::coord_cartesian(xlim=c(0,1),clip="off")+cr_theme(base_size=9,grid=FALSE,legend_position="none",variant="report",mode=mode)+ggplot2::theme(axis.text=ggplot2::element_blank(),axis.ticks=ggplot2::element_blank(),axis.line=ggplot2::element_blank())+ggplot2::labs(x=NULL,y=NULL) }

#' Build a descriptive figure caption
#' @param title,description,qc_note User-supplied descriptive text.
#' @param n Optional observation count.
#' @param unit Optional unit-of-replication label.
#' @export
cr_figure_caption <- function(title=NULL,description=NULL,n=NULL,unit=NULL,qc_note=NULL) paste(Filter(nzchar,c(title,description,if(!is.null(n)) paste0("n = ",n,if(!is.null(unit)) paste0(" ",unit) else ""),qc_note)),collapse=" ")

#' Format p-values without displaying calculated zero
#' @param x Numeric p-values.
#' @param digits Decimal places determining the reporting threshold.
#' @export
cr_format_pvalue <- function(x,digits=3) { cut<-10^-digits;out<-rep(NA_character_,length(x));ok<-is.finite(x)&x>=0&x<=1;out[ok&x<cut]<-paste0("p < ",formatC(cut,format="f",digits=digits));out[ok&x>=cut]<-paste0("p = ",formatC(x[ok&x>=cut],format="f",digits=digits));out }

#' Format an estimate and confidence interval
#' @param estimate,lower,upper Numeric vectors.
#' @param digits Decimal places.
#' @export
cr_format_interval <- function(estimate,lower,upper,digits=2) sprintf(paste0("%.",digits,"f [%.",digits,"f, %.",digits,"f]"),estimate,lower,upper)

#' Format proportions as percentages
#' @param x Numeric proportions.
#' @param digits Decimal places.
#' @export
cr_format_percent <- function(x,digits=1) ifelse(is.na(x),NA_character_,paste0(formatC(100*x,format="f",digits=digits),"%"))

# Internal development/preview helper. Position and data are unchanged; only
# existing colour/fill scales and the theme are replaced.
cr_plot_to_grayscale <- function(plot, variant=c("publication","report")) {
  if(!inherits(plot,"ggplot")) cli::cli_abort("{.arg plot} must be a ggplot object.")
  variant<-match.arg(variant); mapped<-unique(c(names(plot$mapping),unlist(lapply(plot$layers,function(x) names(x$mapping)))))
  out<-plot
  if(any(mapped%in%c("colour","color"))) out<-out+ggplot2::scale_colour_manual(values=cr_palette(mode="grayscale"))
  if("fill"%in%mapped) out<-out+ggplot2::scale_fill_manual(values=cr_palette(mode="grayscale"))
  out+cr_theme(variant=variant,mode="grayscale")
}
