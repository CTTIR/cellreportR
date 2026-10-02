# Import a versioned report specification from JSON

Date-only timestamps retain Date class; ISO timestamps with Z or numeric
offsets are restored as UTC date-times. Legacy space-separated UTC times
with minutes or seconds (optionally ending in UTC) are also accepted.
Custom-section lists and named field-label objects retain their
structure. This cannot recover names or fractional seconds lost in older
exports and does not guarantee equality of whole-report hashes after a
JSON round trip.

## Usage

``` r
cr_import_report_spec(path, validate = TRUE)
```

## Arguments

- path:

  Input JSON path.

- validate:

  Validate the reconstructed specification.
