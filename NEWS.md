# deaviz 0.1.0

Initial release. `deaviz` provides high-dimensional visualization methods for
Data Envelopment Analysis (DEA), built around a single validated `dea_data()`
object and following a `compute_*()` / `plot_*()` naming convention.

## Data object

* `dea_data()` constructs the validated input/output object that every function
  consumes; `as_dea_data()` coerces existing data. `print()` methods are
  provided for the `dea_data` and `dea_som` classes.

## Analysis

* `compute_efficiency()` --- radial DEA efficiency scores (CRS, VRS, DRS, IRS or
  FDH; input- or output-oriented).
* `compute_cross_efficiency()`, `compute_cross_efficiency_weights()` and
  `standardize_weights()` --- cross-efficiency scores and their weight profiles.
* `compute_multiplier_weights()` --- optimal input/output multipliers.
* `compute_som()` --- a self-organizing map of the input/output profiles.

## Visualization

* Data and efficiency overview: `plot_io_distributions()`,
  `plot_efficiency_distributions()`, `plot_io_efficients()`,
  `plot_io_scatter()`, `plot_io_heatmap()`.
* Frontier and projections: `plot_io_costa_frontier()`, `plot_io_pca_biplot()`,
  `plot_io_mds()`, `plot_io_3dscatter()`.
* Benchmarking networks: `plot_io_lambda_network()`, `plot_io_peer_network()`.
* Cross-efficiency: `plot_cem_heatmap()`, `plot_cem_unfolding()`,
  `plot_cem_weights_heatmap()`.
* Profiles: `plot_io_radar()` (with its `coord_radar()` coordinate system) and
  `plot_io_parcoo()`.
* Self-organizing maps: `plot_io_som()`, `plot_io_som_components()`.
* Panel data: `plot_panel_io_biplot()` draws each DMU's trajectory over time.

## Cross-cutting features

* Passing a single DMU to `labels` fades the rest of the plot into a focus
  view; the `fade` argument tunes the level or disables it.
* `x_angle` rotates long x-axis tick labels on `plot_io_distributions()`,
  `plot_io_heatmap()`, `plot_io_parcoo()`, `plot_cem_heatmap()` and
  `plot_cem_weights_heatmap()`.
* Many plots accept `interactive = TRUE` to return a `plotly` widget.
* Consistent, colour-blind-safe style throughout: the Okabe-Ito qualitative
  palette, a viridis sequential palette, and a shared minimal theme.

## Datasets

* `chinese_cities` --- 35 Chinese cities with three inputs and three outputs
  (Sueyoshi, 1992).
* `taiwanese_banks` --- a balanced panel of 22 Taiwanese commercial banks over
  2009-2011 (Kao & Liu, 2014), the worked example for `plot_panel_io_biplot()`.