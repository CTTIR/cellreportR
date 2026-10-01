# Fit a dose-response curve

Fits a dose-response model to well-level summaries of a treatment across
doses. Supports 4-parameter log-logistic (`"4pl"`), 3-parameter
log-logistic with fixed lower asymptote at zero (`"3pl"`), and a simple
linear model (`"linear"`).

## Usage

``` r
cr_dose_response(
  experiment,
  channel,
  treatment = NULL,
  model = c("4pl", "3pl", "linear"),
  log_dose = TRUE
)
```

## Arguments

- experiment:

  A `cr_experiment`.

- channel:

  Channel name.

- treatment:

  Character. Names of treatments to include (for example a compound at
  several doses). If `NULL`, the entire design is used after filtering
  by `dose > 0`.

- model:

  `"4pl"`, `"3pl"` or `"linear"`.

- log_dose:

  If `TRUE`, the fit is done on log10 doses. Doses must all be positive
  in that case.

## Value

A list with class `"cr_dose_response"` containing the fitted model, the
data used for the fit, the estimated parameters, and helper predictions.

## Details

The 4PL model fitted is: \$\$y = d + \frac{a - d}{1 + (x / e)^b}\$\$
where `a` is the top asymptote, `d` the bottom asymptote, `e` the
inflection point (EC50 / IC50), and `b` the Hill slope.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
# Add a synthetic dose-response sub-design
exp$design$dose <- ifelse(exp$design$treatment == "CompoundA_high",
                          500, exp$design$dose)
fit <- cr_dose_response(exp, channel = "marker_1", model = "4pl")
print(fit$params)
#> # A tibble: 2 × 3
#>   parameter estimate std_error
#>   <chr>        <dbl>     <dbl>
#> 1 intercept   -3887.        NA
#> 2 slope        3217.        NA
```
