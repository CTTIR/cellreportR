test_that("visual mappings and grayscale mode are deterministic", {
  expect_identical(cr_palette(4),cr_palette(4))
  expect_identical(cr_shapes(4,names=c("A","B","C","D")),cr_shapes(4,names=c("A","B","C","D")))
  expect_length(unique(cr_linetypes(6)),6)
  combos<-paste(cr_shapes(6),cr_linetypes(6));expect_length(unique(combos),6)
  expect_equal(length(unique(cr_palette(8,mode="grayscale"))),8)
  expect_s3_class(cr_theme(mode="grayscale"),"theme")
})

test_that("standard figure dimensions are exact", {
  expect_equal(unlist(cr_figure_size("single")),c(width=85,height=60))
  expect_equal(unlist(cr_figure_size("double")),c(width=175,height=105))
  expect_equal(round(unlist(cr_figure_size("single","in"))*25.4),c(width=85,height=60))
})

test_that("estimate styling leaves analytical values unchanged", {
  d<-data.frame(group=factor(c("B","A"),levels=c("B","A")),estimate=c(2,1),conf_low=c(1.5,.5),conf_high=c(2.5,1.5));before<-d
  p<-cr_plot_estimates(d,colour_mode="grayscale");expect_s3_class(p,"ggplot");expect_identical(d,before)
  expect_equal(levels(p$data$.cr_label),c("B","A"))
})

test_that("formatters avoid floating noise and p equals zero", {
  expect_equal(cr_format_pvalue(c(0,.0005,.05),3),c("p < 0.001","p < 0.001","p = 0.050"))
  expect_equal(cr_format_interval(1.42,.91,1.93),"1.42 [0.91, 1.93]")
  expect_equal(cr_format_percent(c(.125,NA)),c("12.5%",NA))
})

test_that("publication exports create meaningful files", {
  p<-ggplot2::ggplot(data.frame(x=1:3,y=1:3),ggplot2::aes(.data$x,.data$y))+ggplot2::geom_point()+cr_theme()
  for(ext in c("pdf","png","tiff")) { f<-withr::local_tempfile(fileext=paste0(".",ext));cr_save_figure(p,f,size="single",dpi=300);expect_gt(file.info(f)$size,500) }
  if(capabilities("cairo")){f<-withr::local_tempfile(fileext=".svg");cr_save_figure(p,f);expect_gt(file.info(f)$size,500)}
})

test_that("QC status plot prints status words and uses shapes", {
  q<-cr_report_qc(c("A","B"),c("met","review"),"configured",c("PASS","WARN"));p<-cr_plot_qc_summary(q,"grayscale");expect_s3_class(p,"ggplot");expect_equal(p$data$status,c("PASS","WARN"))
})
