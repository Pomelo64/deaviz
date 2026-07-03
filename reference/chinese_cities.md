# Inputs and outputs of 35 major Chinese cities

A benchmark data envelopment analysis (DEA) dataset describing 35 major
Chinese cities by three inputs and three outputs. Originally introduced
by Sueyoshi (1992), it is the example dataset used to illustrate the
DEA-Viz methods in Ashkiani (2019) and has appeared in several DEA
studies.

## Usage

``` r
chinese_cities
```

## Format

A data frame with 35 rows and 7 variables:

- DMU:

  City name (the decision-making unit label).

- industrial_labour_force:

  Input 1: industrial labour force.

- working_funds:

  Input 2: working funds.

- investments:

  Input 3: investment.

- gross_industrial_output:

  Output 1: gross industrial output.

- profit_and_tax:

  Output 2: profit and tax.

- retail_sales:

  Output 3: retail sales.

## Source

Sueyoshi, T. (1992). Measuring the industrial performance of Chinese
cities by data envelopment analysis. *Socio-Economic Planning Sciences*,
26(2), 75-88.
[doi:10.1016/0038-0121(92)90015-W](https://doi.org/10.1016/0038-0121%2892%2990015-W)

Reproduced as the worked example in Ashkiani, S. (2019), Four Essays on
Data Visualization and Anomaly Detection of Data Envelopment Analysis
Problems (PhD thesis), Universitat Autonoma de Barcelona.

## Details

Columns 2–4 are inputs and columns 5–7 are outputs; column 1 holds the
DMU labels. Because the columns are not `i_`/`o_` prefixed, pass them
explicitly to
[`dea_data`](https://pomelo64.github.io/deaviz/reference/dea_data.md)
(see Examples).

## Examples

``` r
d <- dea_data(
  chinese_cities,
  inputs  = c("industrial_labour_force", "working_funds", "investments"),
  outputs = c("gross_industrial_output", "profit_and_tax", "retail_sales"),
  id      = "DMU"
)
d
#> <dea_data>
#>   DMUs    : 35
#>   Inputs  : 3 (industrial_labour_force, working_funds, investments)
#>   Outputs : 3 (gross_industrial_output, profit_and_tax, retail_sales)
```
