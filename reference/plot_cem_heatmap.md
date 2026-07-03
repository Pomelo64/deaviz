# Heatmap of a cross-efficiency matrix

Draws the cross-efficiency matrix (CEM) as a heatmap: each cell is the
efficiency of the rated DMU (x-axis) evaluated with the weights of the
rating DMU (y-axis). The diagonal holds the simple (self) efficiencies.

## Usage

``` r
plot_cem_heatmap(
  x,
  labels = "all",
  max.overlaps.value = 10,
  transparency = 1,
  fade = TRUE,
  x_angle = NULL,
  subtitle = NULL,
  title = NULL,
  interactive = FALSE,
  ...
)
```

## Arguments

- x:

  A cross-efficiency matrix from
  [`compute_cross_efficiency`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
  or a `dea_data` object / data frame from which one is computed.

- labels:

  DMU tick labels: `"all"` (default) shows them, `"none"` hides them,
  and the name/id of a single DMU highlights that DMU's label(s) in
  colour.

- max.overlaps.value:

  Accepted for API consistency; unused here (default `10`).

- transparency:

  Opacity of the markers/areas, a single number in `[0, 1]` (default
  `1`).

- fade:

  Controls the single-DMU focus view. When one DMU is given to `labels`,
  all other marks (and, for the network plots, everything outside that
  DMU's sub-network; for the panel biplot, the other trajectories) are
  faded so the chosen DMU stands out. `TRUE` (default) uses a sensible
  fade level; `FALSE` disables it; a single number in `[0, 1]` sets the
  alpha of the faded marks directly, where larger values fade them less
  (e.g. `0.4` leaves them more visible).

- x_angle:

  Angle in degrees for the x-axis tick labels, useful when the
  input/output (or DMU) names on the x-axis are long and overlap. `NULL`
  (default) keeps the plot's standard orientation; for example
  `x_angle = 45` tilts the labels to make them readable.

- subtitle:

  Optional subtitle shown beneath the title.

- title:

  Optional plot title.

- interactive:

  Logical; static ggplot2 (default) or interactive plotly.

- ...:

  When `x` is data rather than a matrix, further arguments (e.g.
  `approach`, `epsilon`) passed to
  [`compute_cross_efficiency`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md).

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## References

Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
Derivations, meanings and uses. *Journal of the Operational Research
Society*, 45(5), 567–578.
[doi:10.1057/jors.1994.84](https://doi.org/10.1057/jors.1994.84)

## See also

[`compute_cross_efficiency`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
[`plot_cem_unfolding`](https://pomelo64.github.io/deaviz/reference/plot_cem_unfolding.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_cem_heatmap(compute_cross_efficiency(df))
```
