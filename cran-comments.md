## Submission

This is a new submission: deaviz 0.1.0.

## R CMD check results

On win-builder (R-devel and R-release) and R-hub: 0 errors | 0 warnings | 1 note.

The note is the standard "New submission" note for a first-time package.

Two further items can appear in a local `R CMD check --as-cran` but are
environmental rather than package issues, and do not occur on CRAN's check
machines:

* "checking for future file timestamps ... NOTE: unable to verify current time"
  -- the local machine could not reach a time server to validate timestamps.

* "'qpdf' is needed for checks on size reduction of PDFs" (WARNING) -- the
  system tool 'qpdf' was not installed locally. The package contains no PDFs
  (the vignette is HTML and the package is built with --no-manual), and qpdf is
  available on CRAN's machines.

## Test environments

* Local: Pop!_OS 24.04 LTS, R 4.3.3 (0 errors; the two environmental items above)
* win-builder: R-devel and R-release
* R-hub: Windows, macOS, Linux

## Examples and Suggests

All modelling and plotting back-ends (Benchmarking, plotly, ggplot2, kohonen,
smacof, igraph, graphlayouts, MASS, lpSolve, lpSolveAPI) are in Suggests and
used conditionally via requireNamespace(). Every example that needs them is
wrapped in @examplesIf requireNamespace(...), and the vignette gates each such
chunk on the corresponding package, so both build when the Suggests are absent.

## Spelling

The spell check may flag domain terms and proper nouns (e.g. DEA, DMU,
Porembski, Sammon, Costa, Kao, Liu, biplot, smacof). These are intentional and
listed in inst/WORDLIST.
