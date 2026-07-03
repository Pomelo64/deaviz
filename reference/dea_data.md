# Create a DEA data object

Builds a validated `dea_data` object from a data frame, classifying
columns into inputs and outputs. By default columns are recognised by an
`i_` prefix (inputs) and an `o_` prefix (outputs); the prefixes are
stripped from the stored names for display. Columns can also be selected
explicitly via `inputs`/`outputs`, which overrides the prefixes. Any
remaining column is treated as metadata; a non-numeric one (or an
explicit `id`) supplies the DMU labels.

## Usage

``` r
dea_data(data, inputs = NULL, outputs = NULL, id = NULL)
```

## Arguments

- data:

  A data frame (or object coercible to one) with named columns: at least
  one input column and one output column.

- inputs, outputs:

  Optional column selectors (character names or integer positions). When
  supplied they take precedence over the `i_`/`o_` prefixes. A column
  may not be assigned to both.

- id:

  Optional single column (name or position) holding DMU labels. If
  `NULL`, the first unclassified *non-numeric* column is used, falling
  back to the row names. Numeric id columns (e.g. integer DMU codes) are
  *not* auto-detected, because they cannot be told apart from an input
  or output that lacks an `i_`/`o_` prefix; name such a column here
  explicitly.

## Value

An object of class `dea_data`: a list with components

- `X`:

  numeric matrix of inputs (one row per DMU).

- `Y`:

  numeric matrix of outputs (one row per DMU).

- `labels`:

  character vector of DMU labels.

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
[`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md)

## Examples

``` r
df <- data.frame(
  city  = c("A", "B", "C"),
  i_lab = c(10, 12, 9),
  i_cap = c(5, 6, 4),
  o_gdp = c(100, 130, 90)
)
dea_data(df)
#> <dea_data>
#>   DMUs    : 3
#>   Inputs  : 2 (lab, cap)
#>   Outputs : 1 (gdp)

# explicit selection, no prefixes needed:
df2 <- setNames(df, c("city", "lab", "cap", "gdp"))
dea_data(df2, inputs = c("lab", "cap"), outputs = "gdp", id = "city")
#> <dea_data>
#>   DMUs    : 3
#>   Inputs  : 2 (lab, cap)
#>   Outputs : 1 (gdp)

# numeric DMU id codes must be named explicitly:
df3 <- data.frame(dmu = 1001:1003, i_x = c(2, 3, 4), o_y = c(1, 2, 2))
dea_data(df3, id = "dmu")
#> <dea_data>
#>   DMUs    : 3
#>   Inputs  : 1 (x)
#>   Outputs : 1 (y)
```
