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

## Value

A list with report, software, version, QC, analysis-metadata,
output-hash and event entries, ready for JSON export.

## Examples

``` r
spec <- cr_report_spec(
  report = list(report_id = "EXAMPLE-001"),
  result = list(value = 1.42, unit = "a.u.", classification = "INTERMEDIATE"),
  authorization = list(authorized_by = "Example Authorizer")
)
qc <- cr_report_qc("Cells per well", observed = "1520",
                   acceptance = ">= 500", status = "PASS")
report <- cr_lab_report(spec = spec, qc = qc)
provenance <- cr_report_provenance(report_spec = report)
names(provenance)
#>  [1] "schema"                "schema_version"        "report"               
#>  [4] "software"              "versions"              "result_source"        
#>  [7] "classification_source" "experiment"            "qc"                   
#> [10] "analysis_metadata"     "output_file_hash"      "events"               
```
