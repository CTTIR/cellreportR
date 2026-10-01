# Deterministically classify numeric results using explicit boundaries

Deterministically classify numeric results using explicit boundaries

## Usage

``` r
cr_classify_result(
  value,
  negative_upper,
  positive_lower,
  labels = c(negative = "NEGATIVE", indeterminate = "INDETERMINATE", positive =
    "POSITIVE")
)
```

## Arguments

- value:

  Numeric vector.

- negative_upper, positive_lower:

  Explicit finite boundaries. Values at `negative_upper` are negative;
  values at `positive_lower` are positive; values between are
  indeterminate.

- labels:

  Named character vector containing `negative`, `indeterminate`, and
  `positive`.

## Value

Character vector with missing/non-finite inputs returned as `NA`.
