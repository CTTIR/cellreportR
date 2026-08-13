## R CMD check results

0 errors | 0 warnings | 1 note

The one NOTE is the expected new-submission note:

* "New submission" — this is the first CRAN release of cellreportR.

The incoming checks also flag the CRAN status badge in `README.md`
(`https://CRAN.R-project.org/package=cellreportR`) as an invalid URL. It
resolves once the package is published; it is kept so the badge is
correct from the first accepted version onwards.

(Local builds occasionally surface a single transient "unable to verify
current time" NOTE driven by the build host's network posture; it is not
raised by the package itself.)

## Test environments

* Local: Ubuntu Linux, R 4.6.1
* GitHub Actions: ubuntu-latest (release, devel, oldrel-1),
  macos-latest (release), windows-latest (release)

## Notes

* The package is pure R with no compiled code.
* Two suggested packages, `flowCore` and `sva`, are on Bioconductor
  rather than CRAN. Both are used only behind `requireNamespace()`
  guards, and the tests and examples that touch them skip cleanly when
  they are absent.
* The interactive front-end and the browser-driven tests skip on CRAN and
  wherever no Chromium binary is available. Report rendering skips when
  pandoc is unavailable.
* No examples, tests or vignettes access the network. All example data is
  synthetic, generated in-session from a documented model under an
  explicit seed, and written only below `tempdir()`.
