# Construct a concise report QC table

Construct a concise report QC table

## Usage

``` r
cr_report_qc(
  criterion = character(),
  observed = character(),
  acceptance = character(),
  status = character(),
  source = character()
)
```

## Arguments

- criterion, observed, acceptance, status:

  Vectors defining reportable QC rows.

- source:

  Optional source identifiers.

## Value

A tibble with character columns `criterion`, `observed`, `acceptance`,
`status` and `source`.

## Examples

``` r
cr_report_qc(criterion = c("Cells per well", "Focus"),
             observed = c("1520", "sharp"),
             acceptance = c(">= 500", "visual check"),
             status = c("PASS", "PASS"))
#> # A tibble: 2 × 5
#>   criterion      observed acceptance   status source
#>   <chr>          <chr>    <chr>        <chr>  <chr> 
#> 1 Cells per well 1520     >= 500       PASS   NA    
#> 2 Focus          sharp    visual check PASS   NA    
```
