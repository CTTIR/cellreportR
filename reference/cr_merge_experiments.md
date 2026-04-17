# Merge multiple experiments

Combines two or more `cr_experiment` objects that share the same schema
(channel panel, spatial unit). Useful for multi-plate studies.
Well/slide names must be unique across inputs (prefix them with a plate
identifier if necessary).

## Usage

``` r
cr_merge_experiments(...)
```

## Arguments

- ...:

  `cr_experiment` objects.

## Value

A single merged `cr_experiment`.

## Examples

``` r
e1 <- cr_example_experiment(seed = 1, n_cells_per_well = 10)
e2 <- cr_example_experiment(seed = 2, n_cells_per_well = 10)
e2$cells$well <- paste0("p2_", e2$cells$well)
e2$design$well <- paste0("p2_", e2$design$well)
merged <- cr_merge_experiments(e1, e2)
```
