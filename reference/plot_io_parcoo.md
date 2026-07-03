# Parallel coordinates plot of a DEA problem

Draws a parallel-coordinates plot with one axis per input and output,
each axis min-max scaled to `[0, 1]` so they are comparable. Each DMU is
one line; lines are coloured by efficient/inefficient status.

## Usage

``` r
plot_io_parcoo(
  x,
  variables = "all",
  efficiency = c("crs", "vrs", "none"),
  orientation = "in",
  labels = "none",
  max.overlaps.value = 10,
  transparency = 0.7,
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

- variables:

  Which variables to show: `"all"` (default), `"inputs"`, `"outputs"`,
  or a vector of variable names or positions (positions index the inputs
  followed by the outputs).

- efficiency:

  Efficiency model used to colour the lines by efficient/inefficient
  status: `"crs"` (default), `"vrs"` or `"none"`.

- orientation:

  Measurement orientation for the efficiency scores, passed to
  [`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md)
  (default `"in"`).

- labels:

  Which DMUs to label at the right-hand axis: `"none"` (default),
  `"all"`, `"max.overlaps"`, or the name/id of a single DMU (also
  highlights that DMU's line).

- max.overlaps.value:

  Passed to ggrepel when `labels = "max.overlaps"` (default `10`).

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

  Additional arguments passed to `geom_line`.

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
[`plot_io_radar`](https://pomelo64.github.io/deaviz/reference/plot_io_radar.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_io_parcoo(df, efficiency = "crs")
```
