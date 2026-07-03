# Cross-efficiency and benevolent weights

Functions for the cross-efficiency analysis of a DEA problem: the
cross-efficiency matrix itself (`compute_cross_efficiency`), the
benevolent multiplier weights used to build it
(`compute_cross_efficiency_weights`), and a helper to put those weights
on a common scale (`standardize_weights`).

## Usage

``` r
compute_cross_efficiency(
  x,
  approach = c("benevolent", "aggressive"),
  epsilon = 0
)

compute_cross_efficiency_weights(
  x,
  approach = c("benevolent", "aggressive"),
  epsilon = 0,
  normalize = TRUE
)

standardize_weights(weights)
```

## Arguments

- x:

  A `dea_data` object, or a data frame coerced by
  [`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md).

- approach:

  Secondary goal: `"benevolent"` (maximise others' weighted output) or
  `"aggressive"` (minimise it).

- epsilon:

  Lower bound applied to every multiplier weight. The default `0`
  reproduces the plain model (weights may be zero); set a small positive
  value (e.g. `1e-6`) to enforce strictly positive, non-Archimedean
  weights.

- normalize:

  Logical; if `TRUE` (default) inputs and outputs are max-normalised
  column-wise before solving, so the returned weights are on a
  comparable scale (useful for plotting).

- weights:

  A list with `input_weights` and `output_weights` matrices, such as the
  result of `compute_cross_efficiency_weights`.

## Value

`compute_cross_efficiency` returns an \\n \times n\\ numeric matrix
whose entry `[k, j]` is the efficiency of DMU `j` evaluated with the
weights of DMU `k` (rows are rating units, columns are rated units). Row
and column names are the DMU labels.

`compute_cross_efficiency_weights` returns a list with matrices
`input_weights` and `output_weights` (one row per DMU, labelled).

`standardize_weights` returns a list of the same shape as `weights`,
row-standardised and rounded to 5 digits.

## Functions

- `compute_cross_efficiency()`: Compute the cross-efficiency matrix.

- `compute_cross_efficiency_weights()`: Secondary-goal multiplier
  weights for every DMU.

- `standardize_weights()`: Row-standardise a set of weights so that,
  within each DMU, the input weights sum to one and the output weights
  sum to one.

## Secondary-goal model

Multiplier (weight) solutions in DEA are not unique, so cross-efficiency
requires a secondary goal to choose among a unit's optimal weights. For
unit \\o\\ the model fixes the unit's own efficiency at its CRS score
\\\theta_o\\ and then, among all weight vectors that keep it there,
optimises the total weighted output of the *other* units – maximising it
for the `"benevolent"` approach, minimising it for the `"aggressive"`
one. The unit's own efficiencies \\\theta_o\\ and the fall-back weights
come from a single
[`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html) solve.

## References

Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
Derivations, meanings and uses. *Journal of the Operational Research
Society*, 45(5), 567–578.
[doi:10.1057/jors.1994.84](https://doi.org/10.1057/jors.1994.84)

Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
Derivations, meanings and uses. *Journal of the Operational Research
Society*, 45(5), 567–578.
[doi:10.1057/jors.1994.84](https://doi.org/10.1057/jors.1994.84)

Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
Derivations, meanings and uses. *Journal of the Operational Research
Society*, 45(5), 567–578.
[doi:10.1057/jors.1994.84](https://doi.org/10.1057/jors.1994.84)

## See also

[`compute_efficiency`](https://pomelo64.github.io/deaviz/reference/compute_efficiency.md),
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)

## Examples

``` r
df <- data.frame(
  dmu   = c("A", "B", "C", "D"),
  i_x1  = c(4, 7, 8, 4),
  i_x2  = c(3, 3, 1, 2),
  o_y   = c(1, 1, 1, 1)
)
ce <- compute_cross_efficiency(df, approach = "benevolent")
round(ce, 3)
#>      A     B   C D
#> A 1.00 0.571 0.5 1
#> B 0.75 0.632 1.0 1
#> C 0.75 0.632 1.0 1
#> D 0.75 0.632 1.0 1
colMeans(ce)   # each unit's average cross-efficiency
#>         A         B         C         D 
#> 0.8125000 0.6165414 0.8750000 1.0000000 
```
