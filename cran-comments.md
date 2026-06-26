## Resubmission

This is a resubmission of deaviz 0.1.0, addressing the points raised in review:

* Function names in the Description now use parentheses (e.g. dea_data());
  package names remain in single quotes.
* Added method references with DOIs to the Description.
* Removed writes to .GlobalEnv: the SOM functions (R/compute-som.R,
  R/plot-io-som.R) no longer save/restore .Random.seed in the global
  environment.

## R CMD check results

On win-builder (R-devel and R-release): 0 errors | 0 warnings | 1 note.

The note is the expected "New submission" note, together with "possibly
misspelled words". The flagged words are author surnames from the Description
references (Bana, Soares, Mello, Angulo, Meza, Porembski, Breitenstein, Alpar,
Costa) and are spelled correctly.

## Test environments
* Local: Pop!_OS 24.04 LTS, R 4.3.3
* win-builder: R-devel and R-release
* GitHub Actions: Windows, macOS, Ubuntu (R-release and R-oldrel)

## Examples and Suggests

All modelling and plotting back-ends (Benchmarking, plotly, ggplot2, kohonen,
smacof, igraph, graphlayouts, MASS, lpSolve, lpSolveAPI) are in Suggests and
used conditionally via requireNamespace(). Every example that needs them is
wrapped in @examplesIf requireNamespace(...), and the vignette gates each such
chunk on the corresponding package, so both build when the Suggests are absent.

## Spelling

Proper nouns and domain terms flagged by the spell check (e.g. DEA, DMU,
Porembski, Costa, Bana, Soares, Mello, Angulo, Meza, Breitenstein, Alpar, Kao,
Liu, biplot) are intentional and listed in inst/WORDLIST.