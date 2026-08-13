# print.cr_experiment output is stable

    Code
      print(exp)
    Message
      -- cr_experiment ---------------------------------------------------------------
      * Cells: 960 across 96 wells
      * Channels: "DAPI", "marker_1", "marker_2", and "marker_3"
      * Design: 6 treatment groups
      * QC steps applied: 0
      i Metadata fields: project and sop

# summary.cr_experiment output is stable

    Code
      summary(exp)
    Output
      # A tibble: 6 x 3
        treatment      n_wells n_cells
        <chr>            <int>   <int>
      1 CompoundA_high      16     160
      2 CompoundA_low       16     160
      3 CompoundB           16     160
      4 CompoundC           16     160
      5 PosControl          16     160
      6 Untreated           16     160

# print.cr_result output is stable at cell level

    Code
      print(res)
    Message
      -- cr_result -------------------------------------------------------------------
      * Channel: "marker_1"
      * Treatment: "CompoundA_high"
      * Control: "Untreated"
      * Test: "mann_whitney"
      i Cell-level p = 0
      i Effect sizes: cohens_d, hedges_g, cliffs_delta, and rank_biserial

# print.cr_result output is stable at both levels

    Code
      print(res)
    Message
      -- cr_result -------------------------------------------------------------------
      * Channel: "marker_1"
      * Treatment: "CompoundA_high"
      * Control: "Untreated"
      * Test: "welch"
      i Cell-level p = 8.87e-48
      i Replicate-level p = 2.57e-12
      i Effect sizes: cohens_d, hedges_g, cliffs_delta, and rank_biserial

# print.cr_result reports an AUC when the result carries one

    Code
      print(res)
    Message
      -- cr_result -------------------------------------------------------------------
      * Channel: "marker_1"
      * Treatment: "CompoundA_high"
      * Control: "Untreated"
      * Test: "logistic"
      i Cell-level p = 1.8e-18
      i Effect sizes: cohens_d and cliffs_delta
      i AUC = 0.983

# summary.cr_result output is stable

    Code
      summary(res)
    Message
      -- cr_result -------------------------------------------------------------------
      * Channel: "marker_1"
      * Treatment: "CompoundA_high"
      * Control: "Untreated"
      * Test: "mann_whitney"
      i Cell-level p = 0
      i Effect sizes: cohens_d, hedges_g, cliffs_delta, and rank_biserial

# print.cr_report output is stable when empty

    Code
      print(cr_report(exp, render = FALSE))
    Message
      -- cr_report -------------------------------------------------------------------
      * Analyses: 0
      * Plots queued: 0

# print.cr_report output is stable with a summary and plots

    Code
      print(rep)
    Message
      -- cr_report -------------------------------------------------------------------
      * Analyses: 0
      * Plots queued: 1
    Output
      # A tibble: 2 x 4
        group          estimate ci_low ci_high
        <chr>             <dbl>  <dbl>   <dbl>
      1 CompoundA_low      0.31  -0.1     0.72
      2 CompoundA_high     1.42   0.55    2.29

# summary.cr_report output is stable

    Code
      summary(cr_report(exp, render = FALSE))
    Message
      -- cr_report -------------------------------------------------------------------
      * Analyses: 0
      * Plots queued: 0

# print.cr_qc_gate output is stable

    Code
      print(gate)
    Message
      
      -- QC gate ---------------------------------------------------------------------
      Signal marker_1 vs "Untreated" of the same batch
      Rule: unit median must be greater than the control median
      * 96 units, 80 gated
      * 3 fail vs the control median
      * 13 fail vs the control mean
      * 3 excluded under the chosen rule
      ! 10 verdicts depend on which control centre is used.

# print.cr_design output is stable

    Code
      print(design)
    Message
      
      -- cr_design 
      * units: 96 (column well)
      * treatment: treatment with 6 levels
      * reference: "Untreated"
      * batch: plate

# print.cr_dataset output is stable

    Code
      print(ds)
    Message
      
      -- cr_dataset 
      * cells: 960 x 10
      * source files: unknown
      * unit column: well
      * units: 96
      * design: set

# summary.cr_dataset output is stable

    Code
      summary(ds)
    Output
      NULL

# print.cr_column_map output is stable

    Code
      print(map)
    Message
      <cr_column_map>
      * exact rules: 2
      * prefix rules: 1
      * keep: 3 columns

# print.cr_filename_grammar output is stable

    Code
      print(grammar)
    Message
      <cr_filename_grammar>
      * tokens: interval and dose
      * core patterns: 0
      * prefixes stripped: 0
      * replicate: "[0-9]+(?:\\.[0-9]+)?"

# print.cr_merge_rules output is stable

    Code
      print(cr_merge_rules())
    Message
      <cr_merge_rules>
      * merge suffix: "\\.1$"
      * gated on marker: "merge_unit"
      * kept separate: "\\.2$"
      * merge repeated reads: TRUE

# print.cr_path_spec output is stable for named levels

    Code
      print(spec)
    Message
      <cr_path_spec>
      * levels: run / compound / plate
      * grammar tokens: none
      * markers: none
      * strict: TRUE

# print.cr_path_spec output is stable for indexed levels

    Code
      print(spec)
    Message
      <cr_path_spec>
      * levels: run[1] / compound[2]
      * grammar tokens: dose
      * markers: set
      * strict: FALSE

# print.cr_path_spec output is stable with nothing set

    Code
      print(cr_path_spec())
    Message
      <cr_path_spec>
      * levels: <none>
      * grammar tokens: none
      * markers: none
      * strict: TRUE

