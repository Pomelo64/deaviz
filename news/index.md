# Changelog

## deaviz 0.3.0

- New
  [`plot_io_3dfrontier()`](https://pomelo64.github.io/deaviz/reference/plot_io_3dfrontier.md):
  the three-dimensional counterpart of
  [`plot_io_frontier()`](https://pomelo64.github.io/deaviz/reference/plot_io_frontier.md).
  For two chosen inputs and one output it draws the units in three
  dimensions together with the efficient frontier as a semi-transparent
  piecewise-linear surface (`crs` or `vrs`), colours the units by their
  efficiency in that three-variable sub-model, and can overlay
  lambda-weighted peer arrows. The plot is interactive and requires
  `plotly` and `geometry`.

- Added a test suite validating the two- and three-dimensional frontier
  geometry against the `Benchmarking` solver: efficient units must lie
  on the drawn frontier, no unit may lie above it, and each unit’s
  radial projection must land on it.

## deaviz 0.2.0

- New
  [`dea_panel_data()`](https://pomelo64.github.io/deaviz/reference/dea_panel_data.md)
  (with
  [`as_dea_panel_data()`](https://pomelo64.github.io/deaviz/reference/as_dea_panel_data.md)
  and a [`print()`](https://rdrr.io/r/base/print.html) method): the
  panel counterpart of
  [`dea_data()`](https://pomelo64.github.io/deaviz/reference/dea_data.md).
  It validates the panel once and stores the column mapping, so
  [`plot_panel_io_biplot()`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_biplot.md)
  and
  [`plot_panel_io_parcoo()`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_parcoo.md)
  can be called on the object without repeating
  `inputs`/`outputs`/`id`/`period`.

- New
  [`plot_panel_io_parcoo()`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_parcoo.md):
  traces a chosen input/output or the per-period efficiency of every DMU
  across time, with the periods as parallel axes; `color_by_trend`
  colours each line by the DMU’s overall change (viridis, or a
  zero-anchored diverging scale with `"diverging"`).

- New
  [`plot_io_frontier()`](https://pomelo64.github.io/deaviz/reference/plot_io_frontier.md):
  the classic two-dimensional DEA frontier-and-envelope plot for a
  chosen input/output pair. Draws the units, the shaded
  production-possibility set, and the efficient frontier for the
  selected returns-to-scale (`crs`/`vrs`/`drs`/`irs`/`fdh`); colours
  points by their efficiency in that two-variable sub-model; and
  optionally overlays the peer (reference) network as lambda-weighted
  arrows from inefficient units to their targets, or projection arrows
  to the frontier.

- [`plot_io_parcoo()`](https://pomelo64.github.io/deaviz/reference/plot_io_parcoo.md)
  and
  [`plot_io_radar()`](https://pomelo64.github.io/deaviz/reference/plot_io_radar.md)
  gain a `variables` argument to show a subset of the inputs/outputs:
  `"all"` (default), `"inputs"`, `"outputs"`, or a vector of variable
  names or positions.

- New dataset `taiwanese_banks`: a balanced panel of 22 Taiwanese
  commercial banks over 2009-2011 (Kao & Liu, 2014, ), used as the
  worked example for
  [`plot_panel_io_biplot()`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_biplot.md).

- [`plot_panel_io_biplot()`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_biplot.md)
  now accepts `inputs`, `outputs`, `id` and `period` as integer column
  positions as well as names, and repels the loading-vector labels (via
  ggrepel) so they no longer overlap.

- New `x_angle` argument on
  [`plot_io_parcoo()`](https://pomelo64.github.io/deaviz/reference/plot_io_parcoo.md),
  [`plot_io_heatmap()`](https://pomelo64.github.io/deaviz/reference/plot_io_heatmap.md),
  [`plot_cem_heatmap()`](https://pomelo64.github.io/deaviz/reference/plot_cem_heatmap.md),
  [`plot_cem_weights_heatmap()`](https://pomelo64.github.io/deaviz/reference/plot_cem_weights_heatmap.md)
  and
  [`plot_io_distributions()`](https://pomelo64.github.io/deaviz/reference/plot_io_distributions.md)
  to rotate long x-axis tick labels for readability.

- A single DMU passed to `labels` now fades the rest of the plot into a
  focus view (keeping the chosen DMU’s sub-network / trajectory); the
  `fade` argument tunes the fade level or disables it.

## deaviz 0.1.0

CRAN release: 2026-07-02

- First release: a from-scratch rebuild of the DEA-Viz visualization
  methods as an R package.
- All functions are built on a single validated `dea_data` object and
  follow a `compute_*` / `plot_*` naming convention.
- Analysis:
  [`compute_efficiency()`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
  [`compute_cross_efficiency()`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
  [`compute_cross_efficiency_weights()`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
  [`standardize_weights()`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
  [`compute_multiplier_weights()`](https://pomelo64.github.io/deaviz/reference/compute_multiplier_weights.md),
  [`compute_som()`](https://pomelo64.github.io/deaviz/reference/compute_som.md).
- Visualization: `plot_efficiency_bar()`,
  `plot_efficiency_comparison()`, `plot_cross_efficiency()`,
  [`plot_cem_unfolding()`](https://pomelo64.github.io/deaviz/reference/plot_cem_unfolding.md),
  `plot_cross_efficiency_weights_heatmap()`, `plot_pca_biplot()`,
  `plot_mds()`, `plot_porembski_network()`, `plot_panel_biplot()`,
  `plot_som()`, `plot_som_components()`, `plot_costa_frontier()`,
  `plot_parallel_coordinates()`, `plot_3d_scatter()`,
  `plot_histograms()`, `plot_dotplots()`, `plot_pairwise_scatter()`,
  `plot_input_output_heatmap()`.
- Ships the `chinese_cities` example dataset (35 cities, 3 inputs, 3
  outputs).
- Consistent, colour-blind-safe visual style across all plots: Okabe-Ito
  qualitative palette, viridis sequential palette, and a shared minimal
  theme.
