# Build machine-readable report provenance

Build machine-readable report provenance

## Usage

``` r
cr_report_provenance(
  experiment = NULL,
  report_spec,
  output_file = NULL,
  analysis_metadata = list()
)
```

## Arguments

- experiment:

  Optional `cr_experiment`.

- report_spec:

  A `cr_report_spec` or `cr_lab_report`.

- output_file:

  Optional rendered file whose byte hash is recorded.

- analysis_metadata:

  Optional concise metadata about upstream result objects.
