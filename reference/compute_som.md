# Fit a self-organizing map to a DEA problem

Trains a hexagonal self-organizing map (SOM) on the standardised
input/output data and records, for every node, the mean DEA efficiency
of the DMUs mapped to it. The result feeds
[`plot_io_som`](https://pomelo64.github.io/deaviz/reference/plot_io_som.md)
(and other SOM views), so the map is trained once and reused.

## Usage

``` r
compute_som(
  x,
  rts = c("crs", "vrs"),
  xdim = 8,
  ydim = 8,
  rlen = 1000,
  seed = NULL,
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

- xdim, ydim:

  Grid dimensions (positive integers; default `8` each).

- rlen:

  Number of training iterations (default `1000`).

- seed:

  Optional single number; if supplied, SOM training is made reproducible
  without permanently changing the session's random state.

- ...:

  Further arguments passed to
  [`som`](https://rdrr.io/pkg/kohonen/man/supersom.html).

## Value

An object of class `dea_som`: a list with the fitted `som` (a `kohonen`
object), the DMU `labels`, per-DMU `efficiency`, per-node mean
`node_efficiency` (`NA` for empty nodes), and the grid dimensions.

## See also

[`plot_io_som`](https://pomelo64.github.io/deaviz/reference/plot_io_som.md),
[`som`](https://rdrr.io/pkg/kohonen/man/supersom.html)

## Examples

``` r
df <- data.frame(
  dmu  = paste0("D", 1:12),
  i_x1 = runif(12, 2, 9), i_x2 = runif(12, 1, 5),
  o_y1 = runif(12, 3, 9), o_y2 = runif(12, 1, 4)
)
som <- compute_som(df, xdim = 4, ydim = 4, seed = 1)
som
#> <dea_som>
#>   grid           : 4 x 4 hexagonal (16 nodes)
#>   DMUs           : 12
#>   RTS            : CRS
#>   occupied nodes : 10
```
