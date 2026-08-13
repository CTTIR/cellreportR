# Export a set of tables to CSV or Excel

Writes the named list produced by
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md).
Excel output can go into one workbook with a sheet per table; CSV always
writes one file per table into a directory, because a CSV file holds
exactly one table.

## Usage

``` r
cr_export_tables(tables, path, format = c("csv", "xlsx"), one_file = TRUE)
```

## Arguments

- tables:

  A named list of data frames, or a single data frame.

- path:

  Destination. For a single Excel workbook this is the file path;
  otherwise it is a directory, which is created when needed.

- format:

  `"csv"` (default) or `"xlsx"`.

- one_file:

  Whether to write one Excel workbook with a sheet per table. Ignored
  for CSV.

## Value

A character vector of written paths (invisibly).

## See also

[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md),
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md).

Other reporting:
[`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md),
[`cr_export_results()`](https://cttir.github.io/cellreportR/reference/cr_export_results.md),
[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md),
[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md),
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
tabs <- cr_tables(exp)
out <- tempfile("tables_")
paths <- cr_export_tables(tabs, out)
basename(paths)
#> [1] "disposition.csv" "design.csv"      "channels.csv"   
```
