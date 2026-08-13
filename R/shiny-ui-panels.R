# Tab bodies of the Shiny application, one builder per nav panel.
# Assembled by .cr_app_ui() in R/shiny-ui.R. Each returns a bslib nav
# panel and reads only the input and output ids the server registers.


.cr_panel_data <- function() {
  bslib::nav_panel(
    "Data",
    shiny::tagList(
      shiny::uiOutput("msg_cells"),
      bslib::layout_columns(
        col_widths = c(8, 4),
        bslib::card(
          bslib::card_header("Cells (first 200 rows)"),
          DT::DTOutput("tbl_cells")
        ),
        bslib::card(
          bslib::card_header("Files read"),
          DT::DTOutput("tbl_provenance")
        )
      ),
      bslib::card(
        bslib::card_header("Detected channels"),
        shiny::verbatimTextOutput("txt_channels")
      )
    )
  )
}


.cr_panel_design <- function() {
  bslib::nav_panel(
    "Design",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::tags$p(
          class = "text-muted small",
          "Derive one design row per unit from the imported cells, ",
          "assign treatment levels, then build the experiment. Cells ",
          "in the table can be edited in place."
        ),
        shiny::selectInput("sel_unit_col", "Column identifying one unit",
                           choices = NULL),
        shiny::actionButton("btn_design_skeleton",
                            "Derive design from cells", class = "w-100"),
        shiny::hr(),
        shiny::selectInput("sel_units", "Units", choices = NULL,
                           multiple = TRUE),
        shiny::textInput("txt_treatment", "Treatment level",
                         value = "treated"),
        shiny::numericInput("num_dose", "Dose", value = 0),
        shiny::textInput("txt_group", "Group", value = "treated"),
        shiny::actionButton("btn_assign", "Assign to selected units",
                            class = "w-100"),
        shiny::hr(),
        shiny::actionButton("btn_build", "Build experiment",
                            class = "btn-primary w-100")
      ),
      shiny::uiOutput("msg_design"),
      DT::DTOutput("tbl_design")
    )
  )
}


.cr_panel_qc <- function() {
  bslib::nav_panel(
    "Quality control",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::tags$strong("Cell-level filters"),
        shiny::numericInput("qc_min_area", "Minimum area", value = NA),
        shiny::numericInput("qc_max_area", "Maximum area", value = NA),
        shiny::numericInput("qc_min_circ", "Minimum circularity",
                            value = NA, min = 0, max = 1, step = 0.05),
        shiny::numericInput("qc_doublet_k",
                            "Doublet cut-off (x median area)",
                            value = 2.5, min = 1.1, step = 0.1),
        shiny::checkboxInput("qc_doublets", "Remove doublets",
                             value = FALSE),
        shiny::hr(),
        shiny::tags$strong("Unit gate against its own control"),
        shiny::selectInput("qc_batch", "Batch variables", choices = NULL,
                           multiple = TRUE),
        shiny::selectInput("qc_statistic", "Unit centre",
                           choices = c("median", "mean")),
        shiny::selectInput("qc_reference", "Control centre",
                           choices = c("median", "mean")),
        shiny::selectInput("qc_direction", "A unit must be",
                           choices = c("greater", "less")),
        shiny::numericInput("qc_min_cells", "Minimum cells per unit",
                            value = 1, min = 1),
        shiny::actionButton("btn_gate", "Evaluate gate",
                            class = "w-100"),
        shiny::helpText(
          "Rows selected in the exclusion table are dropped together ",
          "with the units that fail the gate."
        ),
        shiny::hr(),
        shiny::actionButton("btn_qc_apply", "Apply QC",
                            class = "btn-primary w-100"),
        shiny::actionButton("btn_qc_reset", "Reset to imported state",
                            class = "w-100 mt-1")
      ),
      shiny::uiOutput("msg_qc"),
      bslib::navset_card_underline(
        bslib::nav_panel(
          "Exclusion table",
          .cr_table_panel("tbl_units", "dl_units", "unit table")
        ),
        bslib::nav_panel(
          "Disputed verdicts",
          DT::DTOutput("tbl_disputed")
        ),
        bslib::nav_panel(
          "Gate figure",
          shiny::plotOutput("plt_gate", height = "380px")
        ),
        bslib::nav_panel(
          "Area distribution",
          shiny::plotOutput("plt_area", height = "340px")
        ),
        bslib::nav_panel(
          "QC log",
          DT::DTOutput("tbl_qc_log")
        )
      )
    )
  )
}


.cr_panel_normalise <- function() {
  bslib::nav_panel(
    "Normalisation",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::selectInput(
          "norm_method", "Method",
          choices = c("robust z-score" = "robust_zscore",
                      "z-score" = "zscore",
                      "control ratio (log2)" = "control",
                      "background subtraction" = "background",
                      "quantile" = "quantile")
        ),
        shiny::helpText(
          "The control ratio uses the control level selected in the ",
          "sidebar as its reference."
        ),
        shiny::selectInput("norm_batch", "Batch variable (optional)",
                           choices = c("(none)" = "")),
        shiny::actionButton("btn_normalize", "Apply normalisation",
                            class = "btn-primary w-100"),
        shiny::actionButton("btn_norm_reset", "Reset to imported state",
                            class = "w-100 mt-1")
      ),
      shiny::uiOutput("msg_norm"),
      shiny::plotOutput("plt_norm", height = "420px")
    )
  )
}


.cr_panel_effects <- function() {
  bslib::nav_panel(
    "Effect sizes",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::radioButtons(
          "eff_level", "Level",
          choices = c("Unit of replication" = "unit",
                      "Single cell" = "cell"),
          selected = "unit"
        ),
        shiny::selectInput(
          "eff_method", "Effect size shown",
          choices = c("Cohen's d" = "cohens_d",
                      "Hedges' g" = "hedges_g",
                      "Cliff's delta" = "cliffs_delta")
        ),
        shiny::numericInput("eff_conf", "Confidence level",
                            value = 0.95, min = 0.5, max = 0.999,
                            step = 0.01),
        shiny::helpText(
          "All three effect sizes are estimated; the picker chooses ",
          "which one the forest plot draws."
        ),
        shiny::actionButton("btn_effects", "Estimate effect sizes",
                            class = "btn-primary w-100"),
        shiny::hr(),
        shiny::downloadButton("dl_effects", "Effect table (csv)",
                              class = "w-100"),
        shiny::downloadButton("dl_forest", "Forest plot (png)",
                              class = "w-100 mt-1")
      ),
      shiny::uiOutput("msg_effects"),
      bslib::card(
        bslib::card_header("Forest plot"),
        shiny::plotOutput("plt_forest", height = "380px")
      ),
      bslib::card(
        bslib::card_header("Effect size table"),
        DT::DTOutput("tbl_effects")
      )
    )
  )
}


.cr_panel_dose <- function() {
  bslib::nav_panel(
    "Dose-response",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::selectInput("dr_model", "Model",
                           choices = c("4pl", "3pl", "linear")),
        shiny::checkboxInput("dr_log_dose", "Log dose", value = TRUE),
        shiny::selectInput("dr_treatment", "Restrict to treatment",
                           choices = c("(all)" = "")),
        shiny::actionButton("btn_fit", "Fit curve",
                            class = "btn-primary w-100"),
        shiny::downloadButton("dl_dose", "Curve (png)",
                              class = "w-100 mt-1"),
        shiny::helpText(
          "Needs a numeric dose column in the design with more than one ",
          "level."
        )
      ),
      shiny::uiOutput("msg_dose"),
      bslib::card(
        bslib::card_header("Fitted curve"),
        shiny::plotOutput("plt_dose", height = "380px")
      ),
      bslib::card(
        bslib::card_header("Parameters"),
        DT::DTOutput("tbl_dose")
      )
    )
  )
}


.cr_panel_figures <- function() {
  bslib::nav_panel(
    "Figures",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::selectInput(
          "plot_type", "Figure",
          choices = c("Plate map" = "plate",
                      "Intensity by treatment" = "intensity",
                      "Intensity histogram" = "histogram",
                      "Quality control" = "qc",
                      "Spatial map" = "spatial")
        ),
        shiny::numericInput("plot_w_in", "Width (in)", value = 10,
                            min = 3, max = 30, step = 0.5),
        shiny::numericInput("plot_h_in", "Height (in)", value = 6,
                            min = 3, max = 30, step = 0.5),
        shiny::numericInput("plot_dpi", "DPI", value = 600,
                            min = 72, max = 1200, step = 50),
        shiny::actionButton("btn_queue_plot", "Queue for report",
                            class = "btn-primary w-100"),
        shiny::downloadButton("dl_plot", "Download figure (png)",
                              class = "w-100 mt-1")
      ),
      shiny::plotOutput("plt_view", height = "520px")
    )
  )
}


.cr_panel_report <- function() {
  bslib::nav_panel(
    "Report",
    bslib::layout_sidebar(
      sidebar = bslib::sidebar(
        width = 320, position = "right",
        shiny::textInput("rep_title", "Title",
                         value = "cellreportR analysis report"),
        shiny::textInput("rep_author", "Author", value = ""),
        shiny::selectInput("rep_format", "Format",
                           choices = c("html", "pdf")),
        shiny::actionButton("btn_tests", "Run pairwise comparisons",
                            class = "w-100"),
        shiny::helpText(
          "Pairwise comparisons feed the results section of the ",
          "report and can take a minute on large data sets."
        ),
        shiny::hr(),
        shiny::downloadButton("dl_report", "Download report",
                              class = "btn-primary w-100"),
        shiny::downloadButton("dl_results", "Results (csv)",
                              class = "w-100 mt-1"),
        shiny::downloadButton("dl_plots_zip", "Queued figures (zip)",
                              class = "w-100 mt-1")
      ),
      shiny::uiOutput("msg_report"),
      bslib::layout_columns(
        col_widths = c(6, 6),
        bslib::card(
          bslib::card_header("Comparison summary"),
          DT::DTOutput("tbl_results")
        ),
        bslib::card(
          bslib::card_header("Queued figures"),
          DT::DTOutput("tbl_queued")
        )
      )
    )
  )
}

# Version 0.1.0
