# Compute DEA efficiency scores

Computes data envelopment analysis (DEA) efficiency scores for a set of
decision-making units, under any of the returns-to-scale assumptions
supported by [`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html). The
numerical work is done by the Benchmarking package; this function wraps
it so the input/output data follow the
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)
contract and the call sits inside one consistent entry point.

## Usage

``` r
compute_efficiency(
  x,
  rts = c("crs", "vrs", "drs", "irs", "irs2", "fdh", "add"),
  orientation = "in",
  dual = TRUE,
  slack = FALSE,
  ...
)
```

## Arguments

- x:

  A `dea_data` object, or a data frame coerced by
  [`as_dea_data`](https://pomelo64.github.io/deaviz/reference/as_dea_data.md)
  using the default `i_`/`o_` prefix detection. For non-default column
  selection (explicit `inputs`/ `outputs`/`id`), build the object first
  with
  [`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)
  and pass it in.

- rts:

  Returns to scale, one of `"crs"`, `"vrs"`, `"drs"`, `"irs"`, `"irs2"`,
  `"fdh"` or `"add"`.

- orientation:

  Measurement orientation, forwarded to
  [`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html) (e.g. `"in"`,
  `"out"` or `"graph"`).

- dual:

  Logical; if `TRUE` the multiplier (dual) solution is also returned.
  Set `FALSE` to skip it when only the scores are needed.

- slack:

  Logical; if `TRUE` slacks are computed as well.

- ...:

  Further arguments forwarded to
  [`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html).

## Value

The `Farrell` object returned by
[`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html), whose `$eff`
component holds the efficiency scores.

## Details

The returns-to-scale assumption is selected with `rts`: in particular
`"crs"` (constant) and `"vrs"` (variable) are the two most common
models, but `"drs"`, `"irs"`, `"irs2"`, `"fdh"` and `"add"` are
available as well.

## See also

[`dea`](https://rdrr.io/pkg/Benchmarking/man/dea.html), which performs
the computation;
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)
for the data contract.

## Examples

``` r
df <- data.frame(i_x = c(2, 3, 4), o_y = c(1, 2, 2))
compute_efficiency(df, rts = "crs")$eff
#> [1] 0.75 1.00 0.75
compute_efficiency(df, rts = "vrs")$eff
#> [1] 1.00 1.00 0.75
```
