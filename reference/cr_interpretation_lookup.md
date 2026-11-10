# Look up explicit interpretation text

Look up explicit interpretation text

## Usage

``` r
cr_interpretation_lookup(classification, dictionary, default = NA_character_)
```

## Arguments

- classification:

  Character vector.

- dictionary:

  Named character vector or named list.

- default:

  Value used for unknown or missing classifications.

## Value

Character vector of interpretation texts, one per classification;
`default` where no dictionary entry matches.

## Examples

``` r
dictionary <- c(POSITIVE = "Signal above the configured limit.")
cr_interpretation_lookup(c("POSITIVE", "UNKNOWN"), dictionary,
                         default = "No interpretation configured.")
#> [1] "Signal above the configured limit." "No interpretation configured."     
```
