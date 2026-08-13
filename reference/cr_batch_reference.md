# Per-batch control reference statistics

Summarizes the control cells of every batch: how many there are, and
their mean, median and standard deviation for one channel. This table is
the reference that
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)
divides by, and it is worth inspecting on its own – a batch with very
few control cells, or none at all, is visible here before any
standardized value is computed.

## Usage

``` r
cr_batch_reference(
  experiment,
  channel,
  control_level,
  batch_vars,
  control_var = "treatment",
  sd_floor = 1e-08
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel column to summarize. Must be numeric.

- control_level:

  Value (or values) of `control_var` that mark the control cells of a
  batch.

- batch_vars:

  Character vector of columns that jointly define a batch. See
  [`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md).

- control_var:

  Column holding the treatment assignment. Defaults to `"treatment"`.

- sd_floor:

  Lower bound for the control standard deviation. A batch whose control
  cells are identical would otherwise divide by zero.

## Value

A tibble with one row per batch and the columns

- `batch_vars`:

  The columns that define the batch.

- `batch_key`:

  The collapsed batch key.

- `n_cells`:

  Cells in the batch.

- `ctrl_n`:

  Control cells with a finite channel value.

- `ctrl_mean`, `ctrl_median`, `ctrl_sd`:

  Control statistics; `NA` when the batch has no control cells.

- `has_control`:

  Whether the batch can be standardized.

## Details

Both centres are reported deliberately. A right-skewed signal has
`mean > median`, so a downstream gate that compares a well's median
against a control *mean* is silently stricter than the rule it states.
Keeping both lets each consumer compare like with like.

## See also

[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md),
[`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md)

Other batch standardization functions:
[`cr_batch_key()`](https://cttir.github.io/cellreportR/reference/cr_batch_key.md),
[`cr_correct_batch()`](https://cttir.github.io/cellreportR/reference/cr_correct_batch.md),
[`cr_standardize_batch()`](https://cttir.github.io/cellreportR/reference/cr_standardize_batch.md)

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 20)
exp$design$plate <- rep(c("P1", "P2"), length.out = nrow(exp$design))
cr_batch_reference(exp, channel = "marker_1",
                   control_level = "Untreated", batch_vars = "plate")
#> # A tibble: 2 × 8
#>   plate batch_key n_cells ctrl_n ctrl_mean ctrl_median ctrl_sd has_control
#>   <chr> <chr>       <int>  <int>     <dbl>       <dbl>   <dbl> <lgl>      
#> 1 P1    P1            946    165      806.        450.   1270. TRUE       
#> 2 P2    P2           1015    143      632.        525.    374. TRUE       
```
