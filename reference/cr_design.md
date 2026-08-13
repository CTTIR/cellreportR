# Build an experimental design object

A `cr_design` records both the design table — one row per analysis unit
— and the roles its columns play: which column identifies the unit,
which holds the treatment, which level of that treatment is the
reference, and which columns together define a batch.

## Usage

``` r
cr_design(
  data,
  unit = NULL,
  treatment = "treatment",
  control_level = NULL,
  batch_vars = NULL,
  levels = list(),
  keep = NULL,
  call = rlang::caller_env()
)

# S3 method for class 'cr_design'
print(x, ...)
```

## Arguments

- data:

  A data frame carrying the design columns.

- unit:

  Name of the column identifying the analysis unit. If `NULL`, the first
  of `well`, `slide`, `well_id` or `unit` present in `data` is used.

- treatment:

  Name of the treatment (group) column. Default `"treatment"`.

- control_level:

  Optional value of `treatment` that is the reference level, for example
  the vehicle control.

- batch_vars:

  Optional character vector of columns that together define a batch.

- levels:

  Optional named list of factor level orders applied to the
  corresponding design columns.

- keep:

  Optional character vector of design columns to keep. The unit column
  is always kept. `NULL` keeps every column of `data`.

- call:

  The execution environment of the calling function. Used for error
  reporting; experts only.

- x:

  A `cr_design`.

- ...:

  Ignored.

## Value

An object of class `cr_design`:

- `table`:

  Tibble with one row per analysis unit.

- `unit`:

  Name of the unit column.

- `treatment`:

  Name of the treatment column.

- `control_level`:

  Reference level, or `NULL`.

- `batch_vars`:

  Character vector of batch columns.

- `levels`:

  The factor level orders that were applied.

`x`, invisibly.

## Details

Recording the roles alongside the table is what lets later stages
standardise each cell against the control of *its own* batch rather than
against one pooled reference. A batch is normally a combination of
columns (compound, run, plate, experiment, pre-treatment interval),
which a single batch variable cannot express.

`data` may be a per-unit table or a per-cell / per-file table; in the
latter case it is collapsed to unique rows. If a unit maps to more than
one combination of design values the collapse is ambiguous and the
offending columns are named in the error, since silently keeping the
first row would invent a design that was never run.

## See also

[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md),
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md),
[`cr_read_design()`](https://cttir.github.io/cellreportR/reference/cr_read_design.md).

Other constructors:
[`cr_build_experiment()`](https://cttir.github.io/cellreportR/reference/cr_build_experiment.md),
[`cr_dataset()`](https://cttir.github.io/cellreportR/reference/cr_dataset.md),
[`cr_validate_experiment()`](https://cttir.github.io/cellreportR/reference/cr_validate_experiment.md)

## Examples

``` r
units <- tibble::tibble(
  well = sprintf("A%02d", 1:6),
  treatment = rep(c("Vehicle", "CompoundA"), each = 3),
  plate = rep(c("Plate_1", "Plate_2"), 3),
  replicate = rep(1:3, 2)
)
design <- cr_design(units, control_level = "Vehicle",
                    batch_vars = c("plate"))
design
#> 
#> ── cr_design 
#> • units: 6 (column well)
#> • treatment: treatment with 2 levels
#> • reference: "Vehicle"
#> • batch: plate
```
