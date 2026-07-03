# MDS co-plot of a DEA problem

Places the DMUs in two dimensions by multidimensional scaling (Adler and
Raveh, 2008) and colours them by a chosen quantity: a DEA efficiency
score, or one of the input/output variables (or their output-to-input
ratios).

## Usage

``` r
plot_io_mds(
  x,
  transform = c("none", "ratio"),
  dist_method = c("euclidean", "manhattan", "maximum", "canberra", "minkowski"),
  mds_type = c("ratio", "interval", "ordinal", "mspline"),
  encode = "crs",
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

- transform:

  What to compute distances on: `"none"` (the original inputs and
  outputs) or `"ratio"` (all output/input ratios).

- dist_method:

  Distance measure, passed to
  [`dist`](https://rdrr.io/r/stats/dist.html).

- mds_type:

  Scaling level, passed to
  [`smacofSym`](https://rdrr.io/pkg/smacof/man/smacofSym.html).

- encode:

  What to colour by: an efficiency model (`"crs"`, `"vrs"`, `"drs"`,
  `"irs"`, `"fdh"`, `"add"`) or the name of one of the distance-space
  columns.

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

  Optional plot title. If `NULL` (default) one is generated.

- interactive:

  Logical; static ggplot2 (default) or interactive plotly.

- ...:

  Additional arguments passed to `geom_point`.

## Value

A ggplot2 object, or a plotly object when `interactive = TRUE`.

## References

Adler, N., & Raveh, A. (2008). Presenting DEA graphically. *Omega*,
36(5), 715–729.

de Leeuw, J., & Mair, P. (2009). Multidimensional scaling using
majorization: SMACOF in R. *Journal of Statistical Software*, 31(3),
1–30. [doi:10.18637/jss.v031.i03](https://doi.org/10.18637/jss.v031.i03)

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
[`smacofSym`](https://rdrr.io/pkg/smacof/man/smacofSym.html)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:8),
  i_x1 = c(4, 7, 8, 4, 2, 5, 6, 3),
  i_x2 = c(3, 3, 1, 2, 4, 2, 5, 1),
  o_y  = c(5, 8, 6, 7, 3, 9, 4, 6)
)
plot_io_mds(df, encode = "crs")
```
