# User interface of the cellreportR Shiny application: the page shell,
# the brand bar, the persistent sidebar and the About panel. The tab
# bodies live in R/shiny-ui-panels.R.
#
# Every builder here is a plain function returning shiny tags, so the
# whole layout can be asserted in-process without a browser. The tabs
# follow the analysis order: data -> design -> quality control ->
# normalisation -> effect sizes -> dose-response -> figures -> report.


# Header strip with the logo, the app name and the dark-mode toggle.
.cr_brand_bar <- function() {
  shiny::div(
    class = "cr-brand",
    shiny::tags$img(
      src = "cr_www/logo.png", alt = "cellreportR logo",
      class = "cr-logo",
      onerror = "this.style.display='none'"
    ),
    shiny::span(class = "cr-title", "cellreportR"),
    shiny::span(class = "cr-sub", "microscopy assay analysis"),
    shiny::div(class = "ms-auto", .cr_dark_toggle())
  )
}


# A table panel with a download button above it and an optional slot for
# an empty-state message.
.cr_table_panel <- function(tbl_id, dl_id, label, msg_id = NULL) {
  shiny::tagList(
    shiny::div(
      class = "d-flex justify-content-end mb-2",
      shiny::downloadButton(dl_id, paste0("Download ", label, " (csv)"))
    ),
    if (!is.null(msg_id)) shiny::uiOutput(msg_id),
    DT::DTOutput(tbl_id)
  )
}


# Sidebar: where the data comes from and which channel / control every
# tab works on.
.cr_app_sidebar <- function() {
  bslib::sidebar(
    width = 350,
    shiny::tags$strong("1. Data source"),
    shiny::fileInput(
      "f_cells", "Upload segmented exports",
      accept = c(".csv", ".tsv", ".txt", ".rds", ".xlsx"),
      multiple = TRUE
    ),
    shiny::textInput(
      "dir_path", "\u2026or point at a directory",
      placeholder = "/path/to/exports"
    ),
    shiny::textInput("dir_pattern", "File pattern",
                     value = "\\.(csv|tsv|txt|xlsx)$"),
    shiny::checkboxInput("dir_recursive", "Search sub-directories",
                         value = TRUE),
    shiny::actionButton("btn_scan", "Read directory",
                        class = "btn-primary w-100"),
    shiny::hr(),
    shiny::tags$strong("2. Design"),
    shiny::fileInput("f_design", "Design table (csv / xlsx)",
                     accept = c(".csv", ".tsv", ".xlsx")),
    shiny::actionButton("btn_example", "Load example data",
                        class = "w-100"),
    shiny::hr(),
    shiny::tags$strong("3. Analysis target"),
    shiny::selectInput("sel_channel", "Marker channel", choices = NULL),
    shiny::selectInput("sel_control", "Control level", choices = NULL),
    shiny::hr(),
    shiny::downloadButton("dl_experiment", "Experiment (rds)",
                          class = "w-100")
  )
}



.cr_about_panel <- function() {
  shiny::tagList(
    shiny::div(
      class = "cr-about",
      shiny::h2("cellreportR"),
      shiny::p(shiny::tags$em(
        "Analysis and reporting for cell culture assays evaluated by ",
        "microscopy, from segmented single-cell exports to a finished ",
        "report."
      )),
      shiny::p(
        "The application walks through the same pipeline as the ",
        "package functions: read segmented exports, specify the ",
        "design, apply quality control at cell and unit level, ",
        "normalise, estimate effect sizes with confidence intervals ",
        "at both the unit of replication and the single cell, and ",
        "export figures, tables and a report."
      ),
      shiny::h3("Unit of replication"),
      shiny::p(
        "Effect sizes are estimated on unit means by default. ",
        "Single-cell intervals are much narrower on the same data ",
        "because cells within a unit are not independent; they are ",
        "offered for comparison and are anticonservative."
      ),
      shiny::h3("Author"),
      shiny::tags$ul(shiny::tags$li("R. Heller (aut, cre)")),
      shiny::h3("License"),
      shiny::p("MIT (c) 2026 R. Heller. See ",
               shiny::tags$code("LICENSE"), " in the repository."),
      shiny::h3("Project links"),
      shiny::tags$ul(
        shiny::tags$li(shiny::tags$a(
          href = "https://github.com/CTTIR/cellreportR",
          "GitHub repository", target = "_blank")),
        shiny::tags$li(shiny::tags$a(
          href = "https://cttir.github.io/cellreportR/",
          "Documentation site", target = "_blank")),
        shiny::tags$li(shiny::tags$a(
          href = "https://github.com/CTTIR/cellreportR/issues",
          "Issue tracker", target = "_blank"))
      ),
      shiny::h3("How to cite"),
      shiny::p(shiny::tags$small(
        "Retrieve the current entry inside R with ",
        shiny::tags$code('citation("cellreportR")'), "."
      ))
    )
  )
}


.cr_app_ui <- function() {
  .cr_app_resources()
  bslib::page_sidebar(
    title = NULL,
    theme = .cr_app_theme(dark = FALSE),
    fillable = TRUE,
    shiny::tags$head(
      shiny::tags$link(rel = "stylesheet", type = "text/css",
                       href = "cr_www/custom.css")
    ),
    .cr_brand_bar(),
    sidebar = .cr_app_sidebar(),
    bslib::card(
      bslib::card_header("Status"),
      shiny::verbatimTextOutput("status"),
      full_screen = TRUE,
      height = "18vh",
      min_height = "110px"
    ),
    bslib::navset_card_tab(
      id = "tabs",
      full_screen = TRUE,
      height = "62vh",
      .cr_panel_data(),
      .cr_panel_design(),
      .cr_panel_qc(),
      .cr_panel_normalise(),
      .cr_panel_effects(),
      .cr_panel_dose(),
      .cr_panel_figures(),
      .cr_panel_report()
    ),
    bslib::card(
      bslib::card_header("About"),
      .cr_about_panel(),
      full_screen = TRUE,
      height = "18vh",
      min_height = "110px"
    )
  )
}

# Version 0.1.0
