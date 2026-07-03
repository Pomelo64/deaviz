# DEA reference (lambda) network

Projects the DMUs into two dimensions with Sammon mapping and draws the
DEA reference network on top: each DMU is a node coloured by efficiency
status, and an edge joins unit \\r\\ to a reference peer \\c\\ whenever
the envelopment weight \\\lambda\_{rc}\\ exceeds `edge_threshold`. Edge
width is proportional to \\\lambda\\, shown in the legend.

## Usage

``` r
plot_io_lambda_network(
  x,
  rts = c("crs", "vrs"),
  edge_threshold = 0.1,
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

- rts:

  Returns to scale, passed to
  [`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md):
  `"crs"` or `"vrs"`.

- edge_threshold:

  Minimum envelopment weight for an edge to be drawn (single
  non-negative number, default `0.1`).

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

  Node alpha in `[0, 1]` (default `0.7`); lower values reveal
  overlapping nodes.

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

  Further arguments passed to
  [`sammon`](https://rdrr.io/pkg/MASS/man/sammon.html) (e.g. `niter`).

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## References

Porembski, M., Breitenstein, K., & Alpar, P. (2005). Visualizing
efficiency and reference relations in data envelopment analysis with an
application to the branches of a German bank. *Journal of Productivity
Analysis*, 23(2), 203–221.
[doi:10.1007/s11123-005-1328-5](https://doi.org/10.1007/s11123-005-1328-5)

Sammon, J. W. (1969). A nonlinear mapping for data structure analysis.
*IEEE Transactions on Computers*, C-18(5), 401–409.
[doi:10.1109/T-C.1969.222678](https://doi.org/10.1109/T-C.1969.222678)

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
[`plot_io_peer_network`](https://pomelo64.github.io/deaviz/reference/plot_io_peer_network.md),
[`sammon`](https://rdrr.io/pkg/MASS/man/sammon.html)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:6),
  i_x1 = c(4, 7, 8, 4, 2, 5),
  i_x2 = c(3, 3, 1, 2, 4, 2),
  o_y  = c(5, 8, 6, 7, 3, 9)
)
plot_io_lambda_network(df, rts = "crs")
```
