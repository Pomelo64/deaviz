# deaviz (development version)

* New dataset `taiwanese_banks`: a balanced panel of 22 Taiwanese commercial
  banks over 2009-2011 (Kao & Liu, 2014, \doi{10.1016/j.omega.2013.09.001}),
  used as the worked example for `plot_panel_io_biplot()`.
* `plot_panel_io_biplot()` now accepts `inputs`, `outputs`, `id` and `period`
  as integer column positions as well as names, and repels the loading-vector
  labels (via ggrepel) so they no longer overlap.
* New `x_angle` argument on `plot_io_parcoo()`, `plot_io_heatmap()`,
  `plot_cem_heatmap()`, `plot_cem_weights_heatmap()` and
  `plot_io_distributions()` to rotate long x-axis tick labels for readability.
* A single DMU passed to `labels` now fades the rest of the plot into a focus
  view (keeping the chosen DMU's sub-network / trajectory); the `fade` argument
  tunes the fade level or disables it.

# deaviz 0.1.0

* First release: a from-scratch rebuild of the DEA-Viz visualization methods as
  an R package.
* All functions are built on a single validated `dea_data` object and follow a
  `compute_*` / `plot_*` naming convention.
* Analysis: `compute_efficiency()`, `compute_cross_efficiency()`,
  `compute_cross_efficiency_weights()`, `standardize_weights()`,
  `compute_multiplier_weights()`, `compute_som()`.
* Visualization: `plot_efficiency_bar()`, `plot_efficiency_comparison()`,
  `plot_cross_efficiency()`, `plot_cem_unfolding()`,
  `plot_cross_efficiency_weights_heatmap()`, `plot_pca_biplot()`, `plot_mds()`,
  `plot_porembski_network()`, `plot_panel_biplot()`, `plot_som()`,
  `plot_som_components()`, `plot_costa_frontier()`,
  `plot_parallel_coordinates()`, `plot_3d_scatter()`, `plot_histograms()`,
  `plot_dotplots()`, `plot_pairwise_scatter()`, `plot_input_output_heatmap()`.
* Ships the `chinese_cities` example dataset (35 cities, 3 inputs, 3 outputs).
* Consistent, colour-blind-safe visual style across all plots: Okabe-Ito
  qualitative palette, viridis sequential palette, and a shared minimal theme.
