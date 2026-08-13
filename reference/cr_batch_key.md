# Construct a batch key

A batch is rarely identified by a single column. Once an assay spans
several plates, acquisition runs or experiment days, the analytical
batch is the *combination* of those columns, and any analysis that
standardizes against a control has to respect that combination.
`cr_batch_key()` collapses any number of design or cell columns into one
character key that can be grouped on, joined on and reported.

## Usage

``` r
cr_batch_key(x, batch_vars, sep = " | ", na_label = "<NA>")
```

## Arguments

- x:

  A `cr_experiment` or a data frame. For a `cr_experiment` the design
  columns are joined onto the cells first; a column present in both
  tables is taken from `cells`.

- batch_vars:

  Character vector of column names that jointly define a batch, for
  example `c("compound", "run", "plate", "experiment", "interval")`.

- sep:

  Separator placed between the parts of the key.

- na_label:

  Label substituted for missing values.

## Value

A character vector with one key per row of `x` (one key per cell when
`x` is a `cr_experiment`).

## Details

Missing values are replaced by `na_label` rather than propagated, so
that two rows with an unrecorded plate are grouped together visibly
instead of silently producing `NA` keys.

## See also

[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md),
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)

Other batch standardization functions:
[`cr_batch_reference()`](https://cttir.github.io/cellreportR/reference/cr_batch_reference.md),
[`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md),
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
key <- cr_batch_key(exp, c("plate", "timepoint"))
head(unique(key))
#> [1] "P1 | 24" "P2 | 24"

# Works on a plain data frame too
cr_batch_key(data.frame(a = c("x", "y"), b = 1:2), c("a", "b"))
#> [1] "x | 1" "y | 2"
```
