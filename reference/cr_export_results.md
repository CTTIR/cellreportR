# Export results to CSV, Excel or RDS

Export results to CSV, Excel or RDS

## Usage

``` r
cr_export_results(results, path, format = NULL)
```

## Arguments

- results:

  Either a single `cr_result`, a list of `cr_result`s (with optional
  summary attribute), or a tibble.

- path:

  Output file path. Extension determines the format unless `format` is
  given.

- format:

  One of `"csv"`, `"xlsx"`, `"rds"`.

## Value

The output path (invisibly).

## Examples

``` r
# \donttest{
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
all_res <- cr_test_all(exp, "marker_1", "Untreated",
                       level = "replicate")
f <- tempfile(fileext = ".csv")
cr_export_results(all_res, f)
# }
```
