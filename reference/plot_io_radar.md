# Radar plot of inputs and outputs

Draws a radar (spider) plot with one axis per input and output, each
min-max scaled to `[0, 1]`, and one closed polygon per DMU with straight
edges. Polygons are coloured by efficient/inefficient status. A radial
counterpart to
[`plot_io_parcoo`](https://pomelo64.github.io/deaviz/reference/plot_io_parcoo.md).

## Usage

``` r
plot_io_radar(
  x,
  variables = "all",
  efficiency = c("crs", "vrs", "none"),
  orientation = "in",
  labels = "none",
  max.overlaps.value = 10,
  transparency = 0.7,
  fade = TRUE,
  subtitle = NULL,
  title = NULL,
  interactive = FALSE,
  ...
)
```

## Arguments

- x:

  A `dea_data` object, or a data frame coerced by
  [`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md).

- variables:

  Which variables to show: `"all"` (default), `"inputs"`, `"outputs"`,
  or a vector of variable names or positions (positions index the inputs
  followed by the outputs).

- efficiency:

  Efficiency model used to colour the DMUs by efficient/inefficient
  status: `"crs"` (default), `"vrs"` or `"none"`.

- orientation:

  Measurement orientation for the efficiency scores.

- labels:

  DMU emphasis: `"none"` (default) or `"all"` draw every DMU normally;
  the name/id of a single DMU outlines that DMU's polygon in bold so it
  stands out. (Variable axis labels are always shown.)

- max.overlaps.value:

  Accepted for API consistency; unused here (default `10`).

- transparency:

  Opacity of the markers/areas, a single number in `[0, 1]` (default
  `0.7`).

- fade:

  Controls the single-DMU focus view. When one DMU is given to `labels`,
  all other marks (and, for the network plots, everything outside that
  DMU's sub-network; for the panel biplot, the other trajectories) are
  faded so the chosen DMU stands out. `TRUE` (default) uses a sensible
  fade level; `FALSE` disables it; a single number in `[0, 1]` sets the
  alpha of the faded marks directly, where larger values fade them less
  (e.g. `0.4` leaves them more visible).

- subtitle:

  Optional subtitle shown beneath the title.

- title:

  Optional plot title.

- interactive:

  Logical; if `FALSE` (default) a static ggplot2 radar; if `TRUE` an
  interactive plotly `scatterpolar`.

- ...:

  Additional arguments passed to `geom_polygon` (static mode).

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## See also

[`plot_io_parcoo`](https://pomelo64.github.io/deaviz/reference/plot_io_parcoo.md),
[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_io_radar(df, efficiency = "crs")
```
