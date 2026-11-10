# Print a laboratory report specification

Print a laboratory report specification

## Usage

``` r
cr_print_report_spec(x, ...)
```

## Arguments

- x:

  A `cr_report_spec`.

- ...:

  Unused.

## Value

`x`, invisibly.

## Examples

``` r
spec <- cr_report_spec(
  report = list(report_id = "EXAMPLE-001"),
  result = list(value = 1.42, unit = "a.u.", classification = "INTERMEDIATE"),
  authorization = list(authorized_by = "Example Authorizer")
)
cr_print_report_spec(spec)
#> <cr_report_spec> 1.0 
#>   Report: EXAMPLE-001 version 1.0 [ DRAFT ]
#>   Result: INTERMEDIATE 
```
