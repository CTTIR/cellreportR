# Build an ingested data set

A `cr_dataset` is what comes out of ingest: the cells of every export,
the per-file provenance that lets any row be traced back to the
acquisition it came from, and optionally the design those files encode.
It is the object to inspect before committing to an analysis, and it
converts to a `cr_experiment` with
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md).

## Usage

``` r
cr_dataset(
  cells,
  design = NULL,
  unit_var = NULL,
  provenance = NULL,
  file_col = "source_path",
  metadata = list(),
  call = rlang::caller_env()
)

# S3 method for class 'cr_dataset'
print(x, ...)

# S3 method for class 'cr_dataset'
summary(object, ...)
```

## Arguments

- cells:

  A data frame of cells, typically from
  [`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md).

- design:

  Optional
  [`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md)
  object, or a data frame that is passed to
  [`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md).

- unit_var:

  Name of the analysis unit column. Defaults to the design's unit
  column, or the first of `well`, `slide`, `well_id` or `unit` present
  in `cells`.

- provenance:

  Optional per-file table. When `NULL` it is derived from `cells`: one
  row per file with its cell count and every column that is constant
  within the file.

- file_col:

  Name of the file column used for provenance. Default `"source_path"`.

- metadata:

  Optional list of arbitrary user metadata.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

- x:

  A `cr_dataset`.

- ...:

  Ignored.

- object:

  A `cr_dataset`.

## Value

An object of class `cr_dataset`:

- `cells`:

  Tibble of per-cell measurements.

- `provenance`:

  Tibble with one row per source file, or `NULL`.

- `design`:

  A `cr_design`, or `NULL`.

- `unit_var`:

  Name of the analysis unit column, or `NULL`.

- `metadata`:

  List of user metadata.

`x`, invisibly.

A tibble with one row per source file, or `NULL` when the data set
carries no provenance.

## See also

[`cr_read_exports()`](https://cttir.github.io/cellreportR/reference/cr_read_exports.md),
[`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md),
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md).

Other constructors:
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md),
[`cr_design()`](https://cttir.github.io/cellreportR/reference/cr_design.md),
[`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md)

## Examples

``` r
cells <- tibble::tibble(
  source_path = rep(c("a.csv", "b.csv"), each = 3),
  source_file = rep(c("a.csv", "b.csv"), each = 3),
  well = rep(c("A01", "A02"), each = 3),
  treatment = rep(c("Vehicle", "CompoundA"), each = 3),
  target_signal = c(10, 12, 11, 30, 33, 29)
)
ds <- cr_dataset(cells)
ds
#> 
#> ── cr_dataset 
#> • cells: 6 x 5
#> • source files: 2
#> • unit column: well
#> • units: 2
#> • design: not set
ds$provenance
#> # A tibble: 2 × 5
#>   source_path source_file well  treatment n_cells
#>   <chr>       <chr>       <chr> <chr>       <int>
#> 1 a.csv       a.csv       A01   Vehicle         3
#> 2 b.csv       b.csv       A02   CompoundA       3
```
