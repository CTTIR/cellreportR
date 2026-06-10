# Extract IC50 / EC50 from a dose-response fit

Extract IC50 / EC50 from a dose-response fit

## Usage

``` r
cr_ic50(fit, level = 0.95)
```

## Arguments

- fit:

  A `cr_dose_response` returned by
  [`cr_dose_response()`](https://cttir.github.io/cellreportR/reference/cr_dose_response.md).

- level:

  Confidence level for the interval (default 0.95).

## Value

A tibble with `estimate`, `ci_low`, `ci_high`, `parameter` (IC50 or
EC50) and `units`.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
                          500, exp$design$dose)
fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
cr_ic50(fit)
#> # A tibble: 1 × 5
#>   parameter estimate ci_low ci_high units
#>   <chr>        <dbl>  <dbl>   <dbl> <chr>
#> 1 IC50            NA     NA      NA NA   
```
