# Optional browser qualification gate

Install the candidate package and the Node `playwright-core` package; provide Chromium with `CELLREPORT_REVIEW_BROWSER` (default `/usr/bin/chromium`). This manual gate is additional to testthat and requires Pandoc/LaTeX for real HTML/PDF downloads. It starts no listener automatically during package checks.

Create a dedicated empty directory and set `CELLREPORT_REVIEW_TEST_OUTPUT` to it. Set `TMPDIR`, `TMP`, `TEMP`, XDG cache/config, font cache and TeX write roots to approved writable directories before both processes. Disable automatic TeX installation (the server sets the corresponding tinytex option). Start `Rscript --vanilla tests/browser/reviewer-server.R`, then `node tests/browser/reviewer.cjs` from an environment that can resolve playwright-core. The server binds only 127.0.0.1:18743; stop that server after completion. Tests mutate only their anonymous CSV fixture. Do not point this harness at a real report or an existing source directory.

The gate checks responsive claim cards, literal text escaping, keyboard disclosure, separate browser contexts/session URLs, real specification/audit/HTML/PDF and figure downloads, source mutation refusal on refresh and captured direct download URLs, and absence of arbitrary root/sibling file serving. Browser context routing permits only the test origin and blocks other page requests. This does not provide process-level network isolation, authentication or a browser security audit. The figure fixture has only a PDF signature; real report PDFs are rendered separately.

The release qualification must also run testthat with `CELLREPORTR_REQUIRE_REVIEWER_RENDER=true`; ordinary package checks may skip that explicit system-toolchain gate. Do not substitute an optional skip for release evidence.
