# Coerce to a DEA panel-data object

Returns `x` unchanged if it already is a `dea_panel_data` object;
otherwise passes it (and `...`) to
[`dea_panel_data`](https://pomelo64.github.io/deaviz/reference/dea_panel_data.md).

## Usage

``` r
as_dea_panel_data(x, ...)
```

## Arguments

- x:

  A `dea_panel_data` object or a long-format data frame.

- ...:

  Passed to
  [`dea_panel_data`](https://pomelo64.github.io/deaviz/reference/dea_panel_data.md)
  when coercion is needed.

## Value

A `dea_panel_data` object.

## Examples

``` r
pd <- as_dea_panel_data(taiwanese_banks, inputs = 3:5, outputs = 6:8,
                        id = "DMU", period = "Year")
```
