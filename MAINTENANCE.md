# Maintenance audit — 2026-10-30

## Hosted follow-up — 3 November 2026

Baseline `3faf2712a031`, hosted R check `41604839545`: the macOS TIFF
tests failed because CRAN R reported Cairo support but could not load its
XQuartz runtime libraries. Enable the existing shared workflow's
`macos-xquartz` input and correct the platform prerequisites in the README.
The workflow and its supported matrix are otherwise unchanged. The existing
informational oldrel-3 dependency failure (cytolib/BH before package checking)
is distinct from this repaired macOS failure.

Tracing the device failure exposed a second defect: `ggsave()` can return
without producing a figure, or draw on the caller/default device when a Cairo
initializer only warns. Publication figures now stage the figure and optional
sidecar, require nonempty output, preserve previous files on render/metadata
failure and restore them after ordinary publication failures. A failed restore
retains and identifies its backup. This is not a multi-file crash-atomic
transaction; callers must serialize writers. TIFF and laboratory-report Cairo
PDF initializers now stop before drawing if no device was opened.

Evidence retained under the audit's `hosted-followup/cellreportR` directory:

- Original device/output regression: ten failing assertions. Later TIFF and
  laboratory PDF initialization regressions each reproduced their failure.
  Unintended synthetic Rplots output is retained with hashes outside the
  package; it is excluded from the final exported source.
- Final graphics, rollback and real PDF reviewer gate: 140 passing assertions,
  no failures, warnings or skips. The complete final direct suite passes 1,957
  assertions, with the reviewer render gate enabled and no skipped tests.
- Final source archive: `R CMD check --as-cran`, zero errors, zero warnings,
  one incoming new-submission/development-version NOTE. Installed tests pass
  1,871 assertions with 32 existing CRAN-only skips; these cases are exercised
  by the complete direct suite above. Examples, donttest examples, vignettes,
  PDF and HTML manuals pass.
- Archive SHA-256:
  `9b0827faee70cd37ba6918c7251ec4047af50214f371c1c434621f3c39938356`.
  All 319 comparable source payloads match; DESCRIPTION changes are standard
  build reflow and derived author/packaging fields. Git metadata and diagnostic
  Rplots files are absent. All author metadata and public signatures remain.
- Actionlint and whitespace checks pass. House lint remains report-only:
  250 baseline, 256 final; additions are five synthetic condition fixtures and
  the explicit backup-recovery warning. No check was disabled or weakened.
- Independent reviews cover staging, multi-file rollback, retained recovery
  backups, graphics-device argument compatibility and both initialization
  guards. No material issue remains from those reviews.

First use: install R and the README's platform prerequisites (including XQuartz
for Cairo graphics with CRAN R on macOS), then `pak::pak("CTTIR/cellreportR")`.
Construct a ggplot and call `cr_save_figure(p, "figure.tiff", dpi = 300,
metadata = list(source = "my dataset"))`. The returned filename is available
only after publication succeeds. Actual installed-archive TIFF/PDF exports
and their SHA-256 sidecars are checked separately in the local evidence.

Native hosted macOS qualification follows the authorized main push. No release,
submission, manual deployment or source-data modification was performed.

## Original audit

Baseline: `11e105790487f8964f8fdf6e782b255a46742f09`, version 0.2.0.9000.
Work takes place in an isolated checkout. The clean original, manuscript-anchor
tag/release, source data, author metadata and API-lock snapshots are preserved.

## Purpose and acceptance criteria

The project converts segmented microscopy measurements into traceable assay
analyses, distinguishes cells from independent experimental units, and produces
reviewable research/laboratory reports from explicit results. The central
acceptance criterion is that the reported analysis level and design support the
estimate, uncertainty and sample-size claim actually computed.

This corrective development version will retain public function signatures,
declared dependencies and normal valid grouping keys. Intentional numerical
corrections will be documented with a migration path back to the immutable
manuscript anchor; existing analyses will not be silently rewritten. Report
content, sources and authorship remain caller-owned.

## Findings and roadmap

| Priority | Evidence and impact | Outcome, changes and validation |
| --- | --- | --- |
| Essential | `cr_test(level="replicate")` computes effect sizes on cells. A seeded fixture gives d=2.12 in the result, versus d=4.29 from the replicate summaries used by the test. The result summary mixes replication levels. | Compute effect sizes at the requested level; use replicate effects for `both`, with the cell result available explicitly. Compare against independently computed unit summaries and validate report/plot consumers. Document changed estimates and intervals. |
| Essential | `.cr_fit_blocked()` accepts a treatment completely confounded with plate: a synthetic shift of 20 receives a nominal within-block interval 17.6–22.4. R drops a later block coefficient while retaining the earlier treatment coefficient. | Reject non-estimable or saturated blocked designs; retain a skipped-contrast explanation. Test complete confounding, supported crossed designs and row-order invariance. |
| Essential | `cr_power_grid()` falls back to observed sizing when the conservative interval spans zero, allowing `sufficient=TRUE` despite no conservative target. Bounds and vector lengths are also insufficiently checked. | Base sufficiency exclusively on the conservative target; validate ordered intervals and compatible lengths. Preserve observed sizing as explicitly descriptive output. Test both signs, crossing-zero and missing intervals against `stats::power.t.test()`. |
| Essential | `cr_batch_key()` maps `(A | B, C)` and `(A, B | C)` to the same key; missing values also collide with literal `<NA>`. `.cr_stat_groups()` uses unescaped text concatenation. Distinct biological batches can be pooled. | Refuse ambiguous public keys without changing valid keys; group internal statistics by typed tuples. Verify separate batch control denominators and missing/literal-label cases. |
| Essential | `cr_compare_levels()` joins numeric strata using only shared text columns, yielding four rows from two contrasts. `.cr_join_design()` adds `.x/.y` suffixes to repeated treatment metadata and breaks valid experiments. | Reject ambiguous comparison joins and require explicit keys when needed; share the existing documented cell/design join policy. Exercise imported cells through counting, tests and effect grids. |
| Essential | The signed-rank branch pairs rows by position and silently truncates unequal arms, while reporting the original counts. No matched-pair identifier is accepted by this interface. | Refuse this unidentifiable pairing path with a clear migration to explicitly matched vectors and `stats::wilcox.test(..., paired=TRUE)`. A designed matched-pair API is a separate future enhancement. |
| Everyday use | README screening code passes a `cr_dataset` into experiment-only stages and names a nonexistent summarized response column. | Replace it with an executed example using the bundled synthetic screen, documented experimental units and actual output columns. |
| Reporting integrity | The render path writes the optional audit after the report without checking that the paths differ or applying overwrite protection to the audit. | Reproduce the collision, protect report/audit destinations before rendering, and retain failure-path evidence. Qualify real PDF/HTML outputs and the existing reviewer browser gate. |
| Essential | Installed `sva` confirms the one-row ComBat call errors and returns median centering instead. The output does not identify this substituted method. | Refuse unsupported single-channel ComBat; retain explicit median centering and document migration to a scientifically designed feature-by-sample analysis. Test refusal and the actual centering calculation. |
| Scientific limitation | `cr_power_analysis()` simulates independent cells before averaging; it has no between-unit random effect or intraclass correlation. Its description overstates hierarchical power modeling. | Describe the existing simulation accurately without silently replacing its model. Defer a validated correlated-data power model and new public API. |
| Installation | Real reviewer downloads and required render tests fail because the template resolves TeX Gyre Heros as an OS font. The minimal toolchain lacks the font package; even after installation the OS font lookup resolves Helvetica. | Load the four TeX-distributed font files directly, check them in preflight, and document `tex-gyre`. Repeat real PDF and browser qualification. |
| Release blocker | DOI `10.5281/zenodo.21889928` returns HTTP 404 from both `doi.org` and the Zenodo record API on 2026-10-30. Citation/deposit metadata still labels the current tree 0.2.0 and supplies a historical release date. | Remove the unresolved DOI from current public citation metadata, align draft versions and omit unreleased dates; preserve author identities and this prior DOI for investigation. Confirm or mint the correct DOI during authorized deposition. |
| Essential integration | The bundled Shiny screen has ten compounds sharing dose labels. The effects handler omits `by`, pooling them into three contrasts; its default control is the first alphabetic dose instead of the declared Vehicle. Target changes can relabel previously computed effects. | Add explicit strata with compound selected when available, use the declared control initially, retain strata in plots/downloads, and invalidate stale effects on target or data changes. Verify both in-process and installed-browser journeys. |
| Export portability | The complete installed test suite passes 1,914 assertions but emits one warning: macOS Quartz ignores the requested TIFF compression. | Select native Cairo only when R also reports TIFF support; keep an explicit uncompressed Quartz-configured fallback. This R has Cairo but no native TIFF support, so checking Cairo alone is insufficient. Check actual TIFF compression metadata and rerun the package check. |
| Qualification | Baseline: 605 tests, 1,810 assertions passed, three render errors from six missing TeX components; no test skips/warnings. Hosted checks at the baseline passed. | Install the missing isolated toolchain components, retain the baseline evidence, run API lock, complete tests with the required render gate, clean package checks, first use, documentation and real-browser qualification. |

The API-lock tests remain mandatory and their snapshots are not to be accepted
to hide a regression. The version change and migration notes distinguish these
corrections from the frozen manuscript software. Publication requires review of
affected analyses; no source manuscript or historical result will be modified.

Authoritative method references:
[R model aliasing](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/alias.html)
explains why a retained coefficient does not establish independent estimability;
[R power calculations](https://stat.ethz.ch/R-manual/R-devel/library/stats/html/power.t.test.html)
defines the per-group sample-size calculation used here. The [fontspec manual](https://ctan.math.illinois.edu/macros/unicodetex/latex/fontspec/fontspec.pdf) documents loading fonts by filename, including explicit style files. The [R bitmap-device documentation](https://stat.ethz.ch/R-manual/R-devel/library/grDevices/html/png.html) describes platform-specific compression support. The [sva manual](https://bioconductor.org/packages/release/bioc/manuals/sva/man/sva.pdf) specifies a probe-by-sample matrix and design covariates for ComBat.

## Verification and handover

Completed repairs include replication-consistent effect estimates, estimable
blocked models, unambiguous grouping/joins, conservative sample-size decisions,
explicit refusal of unidentified pairing and unsupported single-channel ComBat,
report/audit output protection, portable PDF fonts and runnable screening code.
The application now keeps selected strata in its effects, forest facets and
downloads, initializes the declared control, and invalidates results when the
analysis target changes.
No API-lock snapshot, manuscript anchor, original checkout or source dataset was
changed. Public signatures, authors and declared dependencies are preserved.

Observed evidence (detailed logs under `../../evidence/cellreportR/`):

- Baseline: 605 tests; 1,810 assertions passed; three real PDF errors from the
  incomplete TeX environment. The intermediate complete run had 1,850 passing
  assertions and exposed the font-resolution failures; these were not accepted.
- After correction: 46 focused tests, 234 assertions, zero failures, errors,
  warnings or skips. Includes all API locks, analysis/output regressions, the
  required reviewer render gate, standard PDF and long-content PDF fixtures.
- Installed-package Chromium gate: all 20 recorded checks pass at 320, 390 and
  1,280 px, including keyboard disclosure, escaped text, isolated session URLs,
  real HTML/PDF/specification/audit downloads, source-change refusal on refresh
  and captured URLs, and refusal to serve arbitrary source/sibling files.
  No external browser requests occurred; this is not OS network isolation.
  The owned loopback server was stopped. The figure-download fixture is only
  a PDF signature; the report download is a real two-page PDF with embedded
  TeX Gyre Heros fonts, rendered and visually inspected on both pages.
- README screening example: 1,340 cells, 73 experimental units and six contrasts;
  seven Excel sheets checked against their originating table row counts. The
  exported effect figure was rendered and visually checked after replacing a
  clipped example subtitle. A real flowCore FCS write/read round trip passed.
- Existing lint is report-only in CI: 3,456 baseline style findings. Changes
  introduce no new findings; unrelated formatting is deferred. Actionlint and
  `git diff --check` pass. Shellcheck/pyflakes are not installed for actionlint.
- The complete affected Shiny server/helper suite and API locks pass. The
  two new application tests contribute 12 passing assertions. Installed-browser
  use of the ten-compound example yields 30 contrasts against Vehicle; all
  downloaded estimates and p-values agree with a scripted stratified analysis.
  Target changes clear stale output. Chart/table dimensions, scrolling, CSV and
  PNG downloads were exercised; both the table and exported forest plot were
  visually inspected. Both owned Shiny listeners were stopped.
- Documentation: 178 built HTML pages, 7,143 local references, no missing files.
  Pandoc reports deprecated math-option flags from its callers; the build
  succeeds. No package checks were weakened to hide these diagnostics.
- Final source archive installs into a fresh library and its first-use analysis
  returns five finite replicate-level contrasts with correct citation metadata.
  All 318 matching source files agree byte-for-byte; Git metadata and this audit
  are absent. No high-confidence private-key and access-token patterns were
  found in 328 scanned tracked text files under 2 MB (not a history/secrets audit).
- First complete source-package check: zero errors and check warnings, two
  notes (new submission/development version; missing optional V8 math renderer).
  Its installed suite passed 1,914 assertions with zero failures/skips and one
  TIFF warning. The warning was investigated: this R has Cairo but no native
  TIFF support. The corrected fallback and actual TIFF metadata pass the
  focused export/API suite (37 assertions, no warnings). V8 is now installed
  in the isolated toolchain. The final complete `--as-cran` check passes with
  zero errors, zero warnings and one NOTE (new submission/development version).
  All 1,918 installed-test assertions pass, with zero failures, warnings or
  skips; both manuals and all vignette rebuilds pass. Native compressed Cairo
  TIFF output remains a hosted-platform check; the local fallback is verified.

### First use

Prerequisites: R >= 4.1, the declared imports and optional `writexl` for the
screening workbook. Shiny needs `bslib` and `DT`. FCS import uses Bioconductor
`flowCore`. PDF reports need `rmarkdown`, `knitr`, Pandoc and XeLaTeX; the TeX Live
components installed for this qualification were `koma-script`, `microtype`,
`needspace`, `lastpage`, `draftwatermark`, `tex-gyre` and `enumitem`, alongside the
existing base packages. The font files are resolved directly through TeX.
Automatic TeX installation was disabled during validation.

On this machine, dependencies and the isolated installed package are available:

```sh
AUDIT_ROOT=/Users/rh/Documents/GitHub/.repository-audits/cttir-public-20261030
export R_LIBS_USER="$AUDIT_ROOT/evidence/cellreportR/archive-library:$AUDIT_ROOT/tools/R-library"
Rscript --vanilla -e 'library(cellreportR); e <- cr_example_experiment(seed=42, n_cells_per_well=20); r <- cr_test_all(e, "marker_1", "Untreated", level="replicate"); print(attr(r,"summary"))'
```

Run the README screening block for the complete QC, unit/cell comparison, power,
Excel, figure and numeric-macro workflow. For a separate checkout, install its
imports, then use `R CMD INSTALL .`; do not install the historical GitHub main
branch and assume it contains these unpublished corrections.

### Remaining release gates and deferred work

- Review corrected estimates against each affected manuscript/analysis before
  adopting this development version. Preserve the immutable historical anchor
  for exact reproduction. No real study result has been recalculated here.
- Verify the publication record or obtain the correct DOI during authorized
  deposition. Prior value `10.5281/zenodo.21889928` returns 404 from both the DOI
  resolver and Zenodo record API on 2026-10-30. It remains recorded here and in
  Git history, but is no longer advertised as a current verified citation.
- Select the final release version/date, update draft deposit metadata, run the
  hosted OS/R matrix on the accepted commit, and review before publication.
  No push, release, submission, hosted candidate CI or production deployment
  has been performed. This qualification used macOS ARM64 and synthetic data.
- A validated model of between-unit variation for power, an explicit matched-
  pair API and multi-feature ComBat integration require separately designed
  scientific work. Existing independent-cell power simulations are scenarios,
  not a general hierarchical model or guaranteed bound on real study power.
- Broad style cleanup is outside this corrective release. Deployment access
  controls, clinical validation and real-user operating procedures remain the
  responsibility of the intended deployment and are not established by these
  local fixtures.
