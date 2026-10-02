# Export a report specification as versioned JSON

Named field labels are encoded as a JSON object. Date-time export
retains its existing whole-second representation; fractional precision
is not preserved by this format.

## Usage

``` r
cr_export_report_spec(spec, path, pretty = TRUE)
```

## Arguments

- spec:

  A `cr_report_spec`.

- path:

  Output JSON path.

- pretty:

  Pretty-print JSON.
