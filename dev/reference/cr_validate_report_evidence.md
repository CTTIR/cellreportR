# Revalidate report evidence against its current source tree

Revalidate report evidence against its current source tree

## Usage

``` r
cr_validate_report_evidence(evidence, root)
```

## Arguments

- evidence:

  A
  [`cr_report_evidence()`](https://cttir.github.io/cellreportR/dev/reference/cr_report_evidence.md)
  object.

- root:

  Current root of the source tree, including after relocation.

## Value

Invisibly `TRUE`; invalid schemas, changed bytes or altered claims
error.
