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

## Value

`path`, invisibly.

## Examples

``` r
spec <- cr_report_spec(
  report = list(report_id = "EXAMPLE-001"),
  result = list(value = 1.42, unit = "a.u.", classification = "INTERMEDIATE"),
  authorization = list(authorized_by = "Example Authorizer")
)
path <- tempfile(fileext = ".json")
cr_export_report_spec(spec, path)
imported <- cr_import_report_spec(path)
imported$report$report_id
#> [1] "EXAMPLE-001"
unlink(path)
```
