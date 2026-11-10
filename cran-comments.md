## Submission

This is a new submission.

## R CMD check results

0 errors | 0 warnings | 1 note

* checking CRAN incoming feasibility ... NOTE
  Maintainer: 'Raban Heller <raban.heller@uni-ulm.de>'
  New submission

  This is the expected note for a first submission.

## Test environments

* Local: macOS (aarch64-apple-darwin), R 4.6.1,
  `R CMD check --as-cran --no-manual`. The PDF manual was built locally
  with TinyTeX (TeX Live 2026) via `R CMD Rd2pdf` without errors; the check
  run itself used `--no-manual`.
* GitHub Actions (r-lib/actions v2, `--as-cran`): macos-latest (release),
  windows-latest (release), ubuntu-latest (devel, release, oldrel-1), plus an
  informational ubuntu-latest oldrel-3 row.

## Notes

* The package is pure R with no compiled code.
* Two suggested packages, 'flowCore' and 'sva', are on Bioconductor rather
  than CRAN. Both are used only behind `requireNamespace()` guards, and the
  tests and examples that touch them skip cleanly when they are absent.
* The interactive front-end and the browser-driven tests skip on CRAN and
  wherever no Chromium binary is available. Report rendering is skipped when
  Pandoc is unavailable, and the LaTeX/PDF report tests are skipped on CRAN.
* No examples, tests or vignettes access the network. All example data are
  synthetic, generated in-session under an explicit seed, and written only
  below `tempdir()`.
