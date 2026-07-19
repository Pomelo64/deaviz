# Construct a validated DEA panel-data object

`dea_panel_data()` is the panel (multi-period) counterpart of
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md):
it records, once, which columns of a long-format data frame identify the
DMU and the period and which are the inputs and outputs, validates the
panel structure, and returns an object that the `plot_panel_*` functions
accept directly – so the column mapping does not have to be repeated in
every call.

## Usage

``` r
dea_panel_data(
  data,
  inputs = NULL,
  outputs = NULL,
  id = "Label",
  period = "Period"
)
```

## Arguments

- data:

  A data frame in long format: one row per DMU-period.

- inputs, outputs:

  Column selectors (names or integer positions) for the inputs and
  outputs. If `NULL` (default), columns prefixed `i_` / `o_` are used.

- id, period:

  Columns (name or position) identifying the DMU and the period.
  Defaults `"Label"` and `"Period"`.

## Value

An object of class `dea_panel_data`: a list with the validated `data`
plus the resolved `inputs`, `outputs`, `id` and `period` column names,
the DMU `labels`, the sorted `periods`, and a `balanced` flag.

## Details

Validation: `id` and `period` must each name a single column with no
missing values, each DMU may appear at most once per period, and all
input/output columns must be numeric. As in
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md),
when `inputs`/`outputs` are not given, columns prefixed `i_` / `o_` are
detected automatically.

## See also

[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md),
[`plot_panel_io_biplot`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_biplot.md),
[`plot_panel_io_parcoo`](https://pomelo64.github.io/deaviz/reference/plot_panel_io_parcoo.md)

## Examples

``` r
pd <- dea_panel_data(taiwanese_banks, inputs = 3:5, outputs = 6:8,
                     id = "DMU", period = "Year")
pd
#> A DEA panel: 22 DMUs x 3 periods (balanced) 
#>   periods: 2009, 2010, 2011 
#>   inputs:  labour, physical_capital, purchased_funds 
#>   outputs: demand_deposits, short_term_loans, long_term_loans 
```
