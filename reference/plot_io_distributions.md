# Distributions of inputs and outputs

Shows the distribution of every input and output, either as faceted
histograms (default) or as boxplots. By default the variables are
standardised so they share a common scale.

## Usage

``` r
plot_io_distributions(
  x,
  type = c("histogram", "box"),
  bins = 30,
  scale = TRUE,
  labels = "none",
  max.overlaps.value = 10,
  transparency = 0.7,
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

- type:

  `"histogram"` (default) or `"box"`.

- bins:

  Number of histogram bins (used when `type = "histogram"`).

- scale:

  Logical; if `TRUE` (default) variables are standardised (z-scored)
  before plotting.

- labels:

  Which DMUs to mark: `"none"` (default), `"all"` (a rug of every DMU on
  histograms, jittered points on boxplots), or the name/id of a single
  DMU to mark it with a dashed vertical line (histogram) or a point
  (boxplot).

- max.overlaps.value:

  Accepted for API consistency with the other plots; unused here
  (default `10`).

- transparency:

  Opacity of the markers/areas, a single number in `[0, 1]` (default
  `0.7`).

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

  Logical; if `FALSE` (default) returns a static ggplot2 object, if
  `TRUE` an interactive plotly object.

- ...:

  Additional arguments passed to the underlying geom (`geom_histogram`
  or `geom_boxplot`).

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
plot_io_distributions(df)

plot_io_distributions(df, type = "box")

```
