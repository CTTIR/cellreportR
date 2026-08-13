# Export results to CSV, Excel or RDS

Writes a single flat table of results. Anything the reporting layer
produces is accepted: a `cr_report`, a `cr_result`, the list returned by
[`cr_test_all()`](https://cttir.github.io/cellreportR/reference/cr_test_all.md),
a named list of tables, or a plain data frame.

## Usage

``` r
cr_export_results(results, path, format = NULL)
```

## Arguments

- results:

  A `cr_report`, a `cr_result`, a list of `cr_result` objects, a named
  list of data frames, or a data frame.

- path:

  Output file path. The extension determines the format unless `format`
  is given.

- format:

  One of `"csv"`, `"xlsx"`, `"rds"`. `NULL` (default) infers it from the
  extension of `path`, falling back to `"csv"`.

## Value

The output path (invisibly).

## See also

[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md)
to write several tables at once and
[`cr_macros()`](https://cttir.github.io/cellreportR/reference/cr_macros.md)
to emit individual numbers.

Other reporting:
[`cr_export_plots()`](https://cttir.github.io/cellreportR/reference/cr_export_plots.md),
[`cr_export_tables()`](https://cttir.github.io/cellreportR/reference/cr_export_tables.md),
[`cr_render_report()`](https://cttir.github.io/cellreportR/reference/cr_render_report.md),
[`cr_report()`](https://cttir.github.io/cellreportR/reference/cr_report.md),
[`cr_table_qc()`](https://cttir.github.io/cellreportR/reference/cr_table_qc.md),
[`cr_tables()`](https://cttir.github.io/cellreportR/reference/cr_tables.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
rep <- cr_report(exp)
f <- tempfile(fileext = ".csv")
cr_export_results(rep$tables$disposition, f)
utils::read.csv(f)
#>        treatment n_units n_cells median_cells_per_unit
#> 1 CompoundA_high      16     324                  20.5
#> 2  CompoundA_low      16     341                  21.0
#> 3      CompoundB      16     350                  23.0
#> 4      CompoundC      16     335                  20.0
#> 5     PosControl      16     303                  19.0
#> 6      Untreated      16     308                  19.0
#> 7        (total)      96    1961                  20.0
```
