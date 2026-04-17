# Confusion matrix for a logistic `cr_result`

Confusion matrix for a logistic `cr_result`

## Usage

``` r
cr_confusion_matrix(result, threshold = 0.5)
```

## Arguments

- result:

  A `cr_result` from
  [`cr_logistic()`](https://r-heller.github.io/cellreportR/reference/cr_logistic.md).

- threshold:

  Classification threshold on predicted probability (default `0.5`).

## Value

A tibble with `sensitivity`, `specificity`, `ppv`, `npv`, `accuracy`,
and the confusion-matrix counts.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
res <- cr_logistic(exp, "marker_1", "CompoundA_high", "Untreated")
cr_confusion_matrix(res, 0.5)
#> # A tibble: 1 × 10
#>   threshold sensitivity specificity   ppv   npv accuracy    tp    tn    fp    fn
#>       <dbl>       <dbl>       <dbl> <dbl> <dbl>    <dbl> <int> <int> <int> <int>
#> 1       0.5       0.927        0.95 0.952 0.925    0.938   472   456    24    37
```
