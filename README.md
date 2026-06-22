# deaviz

High-dimensional visualization methods for **data envelopment analysis (DEA)**,
gathered into a single R package. It brings together techniques that have
appeared in the literature but remained scattered and largely unimplemented:
cross-efficiency matrix unfolding, the Porembski reference-set graph, PCA
biplots, multidimensional-scaling colour-plots, self-organizing maps, the Costa
bi-dimensional efficient frontier, parallel coordinates, radar charts,
panel-data trajectory biplots, peer and reference networks, and a set of
descriptive plots.

The methods follow the author's PhD thesis (Ashkiani, 2019).

## Design

Everything is built around one validated object, `dea_data`, which every
function accepts (plain data frames are coerced automatically). Functions follow
a consistent naming convention `plot_<source>_<method>`:

- `compute_*` — analysis, returns values (efficiency scores, cross-efficiency
  matrices, multiplier weights, a fitted SOM).
- `plot_io_*` — plots built from inputs/outputs (the `io`).
- `plot_cem_*` — plots of the cross-efficiency matrix (the `cem`).
- `plot_efficiency_*` — plots of the efficiency scores.
- `plot_panel_io_*` — plots of panel (long-format) input/output data.

Most plotting functions share the same four arguments:

- `interactive` — `FALSE` (default) returns a static **ggplot2** object;
  `TRUE` returns an interactive **plotly** object.
- `labels` — `TRUE` (default) shows the identifying text labels for that plot
  (DMU names on points and networks, DMU ticks on heatmaps, variable names on
  distributions and radar, and so on).
- `title` — an optional plot title.
- `...` — passed through to the underlying geom (or to the relevant `compute_*`
  function for the plots that take raw data).

A shared colour scheme is used throughout: the colour-blind-safe Okabe–Ito
palette for categories and viridis for continuous scales.

The `Benchmarking` package is the DEA engine. The modelling and plotting
packages are in `Suggests`; each function checks for the ones it needs and
errors informatively if they are missing.

## Installation

```r
# install.packages("devtools")
devtools::install_local("deaviz")          # from the package directory

# install the suggested engines you intend to use, e.g.:
install.packages(c("Benchmarking", "ggplot2", "plotly", "lpSolve",
                   "smacof", "kohonen", "MASS", "ggrepel"))
```

## Quick start

```r
library(deaviz)

# Build the data object (the example data is not i_/o_ prefixed,
# so name the inputs and outputs explicitly)
d <- dea_data(
  chinese_cities,
  inputs  = c("industrial_labour_force", "working_funds", "investments"),
  outputs = c("gross_industrial_output", "profit_and_tax", "retail_sales"),
  id      = "DMU"
)

# Analysis
eff <- compute_efficiency(d, rts = "crs")          # Farrell efficiency
ce  <- compute_cross_efficiency(d)                 # cross-efficiency matrix

# Visualization (static ggplot2 by default)
plot_efficiency_distributions(d)
plot_io_pca_biplot(d)
plot_cem_heatmap(ce)
plot_cem_unfolding(ce)
plot_io_costa_frontier(d)
plot_io_peer_network(d, size_by_peers = TRUE)

# The same plot, interactive (plotly), with labels turned off
plot_io_pca_biplot(d, interactive = TRUE, labels = FALSE)
```

With your own data you can skip the explicit `inputs`/`outputs` by prefixing
columns `i_` (inputs) and `o_` (outputs); `dea_data()` then recognises them
automatically.

## Function overview

| Area | Functions |
|------|-----------|
| Data object | `dea_data()`, `as_dea_data()` |
| Efficiency analysis | `compute_efficiency()`, `compute_multiplier_weights()` |
| Cross-efficiency analysis | `compute_cross_efficiency()`, `compute_cross_efficiency_weights()`, `standardize_weights()` |
| SOM analysis | `compute_som()` |
| Descriptive (inputs/outputs) | `plot_io_distributions()`, `plot_io_scatter()`, `plot_io_heatmap()`, `plot_io_parcoo()`, `plot_io_radar()` |
| Efficiency plots | `plot_efficiency_distributions()`, `plot_io_efficients()` |
| Projections & frontier | `plot_io_pca_biplot()`, `plot_io_mds()`, `plot_io_costa_frontier()`, `plot_io_3dscatter()` |
| Reference networks | `plot_io_lambda_network()`, `plot_io_peer_network()` |
| Panel data | `plot_panel_io_biplot()` |
| Self-organizing maps | `plot_io_som()`, `plot_io_som_components()` |
| Cross-efficiency matrix | `plot_cem_heatmap()`, `plot_cem_unfolding()`, `plot_cem_weights_heatmap()` |
| Data | `chinese_cities` |

## Citation

If you use this package, please cite the thesis it is based on:

> Ashkiani, S. (2019). *Four Essays on Data Visualization and Anomaly Detection
> of Data Envelopment Analysis Problems* [PhD thesis, Universitat Autonoma de
> Barcelona]. https://ddd.uab.cat/record/240333

See `citation("deaviz")` for the BibTeX entry.

## License

GPL-3.
