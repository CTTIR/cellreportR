# Revalidate report evidence against its current source tree

Revalidate report evidence against its current source tree

## Usage

``` r
cr_validate_report_evidence(evidence, root)
```

## Arguments

- evidence:

  A
  [`cr_report_evidence()`](https://cttir.github.io/cellreportR/reference/cr_report_evidence.md)
  object.

- root:

  Current root of the source tree, including after relocation.

## Value

Invisibly `TRUE`; invalid schemas, changed bytes or altered claims
error.

## Examples

``` r
root <- tempfile()
dir.create(root)
writeLines(c("group,value", "control,1.25"), file.path(root, "result.csv"))
evidence <- cr_report_evidence(root,
  tables = list(result = list(path = "result.csv", format = "csv", key = "group")),
  claims = list(mean = list(table = "result", key = c(group = "control"),
                            column = "value", format = "number", digits = 2)))
cr_validate_report_evidence(evidence, root)
unlink(root, recursive = TRUE)
```
