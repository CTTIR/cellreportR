# Summarise QC steps applied to an experiment

Summarise QC steps applied to an experiment

## Usage

``` r
cr_qc_summary(experiment)
```

## Arguments

- experiment:

  A `cr_experiment`.

## Value

A tibble with one row per QC step.

## Examples

``` r
exp <- cr_example_experiment(seed = 1, n_cells_per_well = 30)
exp <- cr_qc_filter(exp, min_area = 50)
cr_qc_summary(exp)
#> # A tibble: 1 × 7
#>   step         parameters cells_before cells_after cells_removed percent_removed
#>   <chr>        <chr>             <int>       <int>         <int>           <dbl>
#> 1 cr_qc_filter min_area=…         2911        2754           157            5.39
#> # ℹ 1 more variable: timestamp <dttm>
```
