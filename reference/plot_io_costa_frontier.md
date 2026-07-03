# Costa bi-dimensional efficient frontier

Draws the Costa et al. (2016) two-dimensional representation of a DEA
problem. Each DMU's multiplier weights are standardised and used to
collapse its inputs and outputs into a single weighted input `I` and
weighted output `O`; efficient units fall on the `O = I` diagonal (the
frontier) and inefficient units below it. Uses the
constant-returns-to-scale model; weights come from
[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md).

## Usage

``` r
plot_io_costa_frontier(
  x,
  orientation = c("in", "out"),
  point_size = 2,
  transparency = 0.7,
  fade = TRUE,
  labels = "none",
  max.overlaps.value = 10,
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

- orientation:

  Measurement orientation, `"in"` or `"out"`.

- point_size:

  Point size (default `2`).

- transparency:

  Point alpha in `[0, 1]` (default `0.7`).

- fade:

  Controls the single-DMU focus view. When one DMU is given to `labels`,
  all other marks (and, for the network plots, everything outside that
  DMU's sub-network; for the panel biplot, the other trajectories) are
  faded so the chosen DMU stands out. `TRUE` (default) uses a sensible
  fade level; `FALSE` disables it; a single number in `[0, 1]` sets the
  alpha of the faded marks directly, where larger values fade them less
  (e.g. `0.4` leaves them more visible).

- labels:

  Which DMUs to label: `"none"` (default), `"all"` (label every DMU;
  ggrepel with `max.overlaps = Inf`), `"max.overlaps"` (ggrepel using
  `max.overlaps.value`), or the name/id of a single DMU to highlight
  just that one. Use `"id"` to print each DMU's row number inside its
  own marker.

- max.overlaps.value:

  Passed to ggrepel when `labels = "max.overlaps"` (default `10`);
  larger values keep more crowded labels.

- subtitle:

  Optional subtitle shown beneath the title.

- title:

  Optional plot title.

- interactive:

  Logical; static ggplot2 (default) or interactive plotly.

- ...:

  Additional arguments passed to `geom_point`.

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## References

Bana e Costa, C. A., Soares de Mello, J. C. C. B., & Angulo Meza, L.
(2016). A new approach to the bi-dimensional representation of the DEA
efficient frontier with multiple inputs and outputs. *European Journal
of Operational Research*, 255(1), 175–186.
[doi:10.1016/j.ejor.2016.05.012](https://doi.org/10.1016/j.ejor.2016.05.012)

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_io_costa_frontier(df, orientation = "in")
```
