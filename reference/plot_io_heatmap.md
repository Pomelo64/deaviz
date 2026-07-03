# Heatmap of standardised inputs and outputs

Draws a DMU-by-variable heatmap of the input and output values, with
DMUs on the y-axis and variables on the x-axis (inputs labelled `I_`,
outputs `O_`). By default the values are standardised column-wise so
they are comparable across variables.

## Usage

``` r
plot_io_heatmap(
  x,
  scale = TRUE,
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

  A `dea_data` object, or a data frame coerced by
  [`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md).

- scale:

  Logical; if `TRUE` (default) each variable is standardised (z-scored)
  before plotting.

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

  Additional arguments passed to `geom_tile`.

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## See also

[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_io_heatmap(df)

```
