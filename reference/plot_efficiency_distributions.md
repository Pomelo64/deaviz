# Efficiency scores of the DMUs

Summarises the DEA efficiency scores of the decision-making units as a
histogram (default), a boxplot, or a per-DMU bar chart. More than one
returns-to-scale model can be requested at once: histograms are then
stacked vertically (one panel per model) and boxplots are drawn side by
side, each model in its own colour.

## Usage

``` r
plot_efficiency_distributions(
  x,
  rts = "crs",
  orientation = "in",
  type = c("histogram", "box", "bar"),
  bins = 30,
  labels = "none",
  max.overlaps.value = 10,
  transparency = 0.7,
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

- rts:

  Returns-to-scale model(s) passed to
  [`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md);
  a character vector with any of `"crs"` (default), `"vrs"`, `"drs"`,
  `"irs"`, `"fdh"`, `"add"`. Supplying more than one compares models.

- orientation:

  Measurement orientation passed to
  [`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md).

- type:

  `"histogram"` (default), `"box"`, or `"bar"` (one bar per DMU).

- bins:

  Number of histogram bins (used when `type = "histogram"`).

- labels:

  Which DMUs to mark: `"none"` (default), `"all"` (rug on histograms,
  jittered points on boxplots), or the name/id of a single DMU to mark
  with a dashed line (histogram), a point (boxplot), or a highlighted
  axis label (bar).

- max.overlaps.value:

  Accepted for API consistency; unused here (default `10`).

- transparency:

  Opacity of the markers/areas, a single number in `[0, 1]` (default
  `0.7`).

- subtitle:

  Optional subtitle shown beneath the title.

- title:

  Optional plot title.

- interactive:

  Logical; static ggplot2 (default) or interactive plotly.

- ...:

  Additional arguments passed to the underlying geom.

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
[`plot_io_efficients`](https://pomelo64.github.io/deaviz/reference/plot_io_efficients.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_efficiency_distributions(df, rts = "crs")

plot_efficiency_distributions(df, rts = c("crs", "vrs"), type = "box")
```
