# Unfolding map of a cross-efficiency matrix

Applies multidimensional unfolding (Ashkiani and Mar-Molinero, 2017) to
a cross-efficiency matrix, placing each DMU twice – once as a "rating"
unit (the weights it applies) and once as a "rated" unit – so that a
rating unit sits close to the units it scores highly. Dissimilarities
are taken as `1 - CEM`.

## Usage

``` r
plot_cem_unfolding(
  x,
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

  A cross-efficiency matrix from
  [`compute_cross_efficiency`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
  or a `dea_data` object / data frame from which one is computed.

- labels:

  Which DMUs to label: `"none"` (default), `"all"` (label every DMU;
  ggrepel with `max.overlaps = Inf`), `"max.overlaps"` (ggrepel using
  `max.overlaps.value`), or the name/id of a single DMU to highlight
  just that one. Use `"id"` to print each DMU's row number inside its
  own marker.

- max.overlaps.value:

  Passed to ggrepel when `labels = "max.overlaps"` (default `10`);
  larger values keep more crowded labels.

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

  Logical; static ggplot2 (default) or interactive plotly.

- ...:

  When `x` is data rather than a matrix, further arguments (e.g.
  `approach`, `epsilon`) passed to
  [`compute_cross_efficiency`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md).

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## References

Ashkiani, S., & Mar-Molinero, C. (2017). Visualization of
cross-efficiency matrices using multidimensional unfolding. In *Recent
Applications of Data Envelopment Analysis*.

## See also

[`compute_cross_efficiency`](https://pomelo64.github.io/deaviz/reference/cross-efficiency.md),
[`unfolding`](https://rdrr.io/pkg/smacof/man/smacofRect.html)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
ce <- compute_cross_efficiency(df)
plot_cem_unfolding(ce)
```
