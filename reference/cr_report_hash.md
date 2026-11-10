# Hash report-relevant structured data

Hash report-relevant structured data

## Usage

``` r
cr_report_hash(x, algorithm = "sha256")
```

## Arguments

- x:

  Any R object.

- algorithm:

  Algorithm supported by
  [`digest::digest()`](https://eddelbuettel.github.io/digest/man/digest.html),
  default SHA-256.

## Value

A character string holding the hexadecimal digest.

## Examples

``` r
cr_report_hash(list(report_id = "EXAMPLE-001", value = 1.42))
#> [1] "a5cc1fa588646b8aeb2955e3a72a6a8434ca39952055f457bdbf8e6dbb990be7"
```
