# Compute DEA multiplier (weight) solutions

Solves the input-oriented, constant-returns-to-scale (CCR) *multiplier*
DEA model for every decision-making unit and returns the optimal
efficiency scores together with the input and output weights. A
non-Archimedean lower bound `epsilon` keeps all weights strictly
positive.

## Usage

``` r
compute_multiplier_weights(x, epsilon = 1e-06)
```

## Arguments

- x:

  A `dea_data` object, or a data frame coerced by
  [`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md).

- epsilon:

  Non-Archimedean lower bound on every multiplier weight; must be a
  single non-negative number. Defaults to `1e-6`.

## Value

A list with components

- `eff`:

  named numeric vector of efficiency scores.

- `input_weights`:

  matrix of input multipliers (one row per DMU, one column per input).

- `output_weights`:

  matrix of output multipliers (one row per DMU, one column per output).

All rows are labelled with the DMU labels carried by `x`.

## Details

For unit \\o\\ the model maximises the weighted output \\u^\top y_o\\
subject to the normalisation \\v^\top x_o = 1\\ and \\u^\top y_j -
v^\top x_j \le 0\\ for every unit \\j\\, with \\u, v \ge \epsilon\\. The
optimal value is the unit's efficiency score.

DEA multiplier solutions are generally **not unique**: efficient units
and degenerate vertices admit alternative optimal weight vectors. This
function returns *one* optimal solution (the vertex the solver settles
on), not a canonical one. Treat the returned weights accordingly when
they feed downstream calculations such as cross-efficiency.

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md)
for scores via [`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html);
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)
for the data contract.

## Examples

``` r
df <- data.frame(i_x = c(2, 3, 4), o_y = c(1, 2, 2))
w <- compute_multiplier_weights(df)
w$eff
#>    1    2    3 
#> 0.75 1.00 0.75 
w$input_weights
#>           x
#> 1 0.5000000
#> 2 0.3333333
#> 3 0.2500000
```
