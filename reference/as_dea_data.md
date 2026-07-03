# Coerce to a dea_data object

Coerce to a dea_data object

## Usage

``` r
as_dea_data(x, ...)
```

## Arguments

- x:

  A `dea_data` object, or a data frame passed on to
  [`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md).

- ...:

  Passed to
  [`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)
  when `x` is not already a `dea_data` object.

## Value

A `dea_data` object.

## Examples

``` r
df <- data.frame(city = c("A", "B"), i_x = c(4, 7), o_y = c(5, 8))
d <- as_dea_data(df)   # coerces a data frame to dea_data
as_dea_data(d)         # already a dea_data: returned unchanged
#> <dea_data>
#>   DMUs    : 2
#>   Inputs  : 1 (x)
#>   Outputs : 1 (y)
```
