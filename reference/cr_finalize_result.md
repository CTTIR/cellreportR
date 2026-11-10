# Apply a caller-selected QC finalization rule

Apply a caller-selected QC finalization rule

## Usage

``` r
cr_finalize_result(
  classification,
  qc_status,
  failed_statuses = "FAIL",
  invalid_label = "INVALID",
  invalidate = TRUE
)
```

## Arguments

- classification:

  Character vector.

- qc_status:

  Character vector, recycled against `classification`.

- failed_statuses:

  QC labels treated as failed.

- invalid_label:

  Label used for failed QC.

- invalidate:

  Whether failed QC replaces the supplied classification.

## Value

Character vector of classifications in which entries with a failed QC
status are replaced by `invalid_label` when `invalidate = TRUE`.

## Examples

``` r
cr_finalize_result(c("POSITIVE", "NEGATIVE"), qc_status = c("PASS", "FAIL"))
#> [1] "POSITIVE" "INVALID" 
```
