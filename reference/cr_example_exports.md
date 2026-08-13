# Write a synthetic export tree

Writes a nested directory of single-acquisition export files whose
design information lives in the directory layout and the file names
rather than inside the files. This is the input the multi-file ingest
functions were written for, so that
[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md),
[`cr_parse_paths()`](https://cttir.github.io/cellreportR/reference/cr_parse_paths.md)
and
[`cr_extract_markers()`](https://cttir.github.io/cellreportR/reference/cr_extract_markers.md)
can be demonstrated on real files.

## Usage

``` r
cr_example_exports(
  dir = tempdir(),
  seed = 42,
  n_cells = 20,
  format = c("csv", "xlsx")
)
```

## Arguments

- dir:

  Directory to write the tree into. Created when it does not exist.

- seed:

  Random seed. `NULL` uses the current RNG state.

- n_cells:

  Number of cells written per file.

- format:

  File format, `"csv"` (default) or `"xlsx"`. Writing `"xlsx"` needs the
  `writexl` package.

## Value

A character vector of the written file paths, invisibly.

## Details

The layout below `dir` is `Run1/<compound>/<experiment>/<plate>/<file>`,
and the file names follow the grammar
`<compound>_<interval>_<dose>_<mode>_<replicate>` in which an absent
token is meaningful: a name carrying no exposure token is a vehicle
control. Parenthetical markers are attached to three files – a two-pass
acquisition, a repeated read and a reagent-omitted acquisition – and one
directory is marked as a partly filled plate.

Column headers are raw instrument names rather than analysis names, and
one of them carries a unit glyph, so that a
[`cr_column_map()`](https://cttir.github.io/cellreportR/reference/cr_column_map.md)
is genuinely required to read them.

## See also

[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md),
[`cr_path_spec()`](https://cttir.github.io/cellreportR/reference/cr_path_spec.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md),
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md).

Other example data:
[`cr_example_design()`](https://cttir.github.io/cellreportR/reference/cr_example_design.md),
[`cr_example_experiment()`](https://cttir.github.io/cellreportR/reference/cr_example_experiment.md),
[`cr_example_files()`](https://cttir.github.io/cellreportR/reference/cr_example_files.md),
[`cr_example_path()`](https://cttir.github.io/cellreportR/reference/cr_example_path.md),
[`cr_example_screen()`](https://cttir.github.io/cellreportR/reference/cr_example_screen.md)

## Examples

``` r
d <- file.path(tempdir(), "cr_example_exports")
files <- cr_example_exports(d, seed = 1, n_cells = 5)
basename(files)
#>  [1] "CompoundA_15min_vehicle_1.csv"                   
#>  [2] "CompoundA_15min_250uM_treated_1.csv"             
#>  [3] "CompoundA_15min_250uM_treated_1.1 (split).csv"   
#>  [4] "CompoundA_60min_vehicle_2.csv"                   
#>  [5] "CompoundA_60min_250uM_treated_2.csv"             
#>  [6] "CompoundA_60min_250uM_treated_2 (repeat).csv"    
#>  [7] "CompoundA_60min_250uM_treated_2.2.csv"           
#>  [8] "CompoundB_15min_vehicle_1.csv"                   
#>  [9] "CompoundB_15min_250uM_treated_1.csv"             
#> [10] "CompoundB_15min_250uM_treated_1 (no reagent).csv"

map <- cr_column_map(
  exact = c("Event Label" = "cell_id",
            "Target - Signal Mean" = "target_signal"),
  prefix = c("^Nuclei - Area" = "area")
)
cells <- cr_read_exports(d, column_map = map, progress = FALSE)
head(cells[, c("source_file", "cell_id", "target_signal", "area")], 3)
#> # A tibble: 3 × 4
#>   source_file                                   cell_id target_signal  area
#>   <chr>                                         <chr>           <dbl> <dbl>
#> 1 CompoundA_15min_250uM_treated_1.1 (split).csv E0001           2316.  146.
#> 2 CompoundA_15min_250uM_treated_1.1 (split).csv E0002            805.  201.
#> 3 CompoundA_15min_250uM_treated_1.1 (split).csv E0003            594.  227.
```
