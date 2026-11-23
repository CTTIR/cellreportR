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

The 4PL model fitted is: \$\$y = d + \frac{a - d}{1 + \exp(b\\(x -
e))}\$\$ where `x` is the dose on the fitting scale (`log10(dose)` when
`log_dose = TRUE`, the untransformed dose otherwise), `a` and `d` are
the asymptotes approached at low and at high `x` when `b` is positive
(and the reverse when `b` is negative), `e` is the inflection point on
the fitting scale, and `b` is the slope on that scale. The 3PL model is
the same curve with `d` fixed at zero.

With `log_dose = TRUE` this is the four-parameter log-logistic curve \\y
= d + (a - d) / (1 + (\mathrm{dose} / \mathrm{EC50})^h)\\ with
\\\mathrm{EC50} = 10^e\\ and Hill slope \\h = b / \ln 10\\. `params`
reports `e` and `b` on the fitting scale;
[`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md)
back-transforms `e` to the dose scale. With `log_dose = FALSE` the curve
is logistic in the dose itself and `b` is not a Hill slope. The
`log_dose = TRUE` curve is the log-logistic parameterization that
carries the logarithm of the half-maximal dose as a parameter (Ritz et
al. 2015, Eq. 3, p. 3), written with base-10 instead of natural
logarithms; `a` and `d` take the place of the two limits called `d` and
`c` there.

When the nonlinear fit cannot be obtained (for example with fewer
distinct doses than parameters) a straight line is fitted instead and
the `model` element of the result reads `"linear"`; check it before
interpreting `params`, and note that
[`cr_ic50()`](https://cttir.github.io/cellreportR/reference/cr_ic50.md)
then returns `NA`.

## References

Ritz C, Baty F, Streibig JC, Gerhard D (2015). Dose-response analysis
using R. *PLoS ONE* 10(12), e0146021, section "Built-in dose-response
models", Eqs. 2 and 3, p. 3.
[doi:10.1371/journal.pone.0146021](https://doi.org/10.1371/journal.pone.0146021)

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
