#' Inputs and outputs of 35 major Chinese cities
#'
#' A benchmark data envelopment analysis (DEA) dataset describing 35 major
#' Chinese cities by three inputs and three outputs. Originally introduced by
#' Sueyoshi (1992), it is the example dataset used to illustrate the DEA-Viz
#' methods in Ashkiani (2019) and has appeared in several DEA studies.
#'
#' @format A data frame with 35 rows and 7 variables:
#' \describe{
#'   \item{DMU}{City name (the decision-making unit label).}
#'   \item{industrial_labour_force}{Input 1: industrial labour force.}
#'   \item{working_funds}{Input 2: working funds.}
#'   \item{investments}{Input 3: investment.}
#'   \item{gross_industrial_output}{Output 1: gross industrial output.}
#'   \item{profit_and_tax}{Output 2: profit and tax.}
#'   \item{retail_sales}{Output 3: retail sales.}
#' }
#'
#' @details Columns 2--4 are inputs and columns 5--7 are outputs; column 1 holds
#'   the DMU labels. Because the columns are not \code{i_}/\code{o_} prefixed,
#'   pass them explicitly to \code{\link{dea_data}} (see Examples).
#'
#' @source Sueyoshi, T. (1992). Measuring the industrial performance of Chinese
#'   cities by data envelopment analysis. \emph{Socio-Economic Planning
#'   Sciences}, 26(2), 75-88. \doi{10.1016/0038-0121(92)90015-W}
#'
#'   Reproduced as the worked example in Ashkiani, S. (2019), Four Essays on
#'   Data Visualization and Anomaly Detection of Data Envelopment Analysis
#'   Problems (PhD thesis), Universitat Autonoma de Barcelona.
#'
#' @examples
#' d <- dea_data(
#'   chinese_cities,
#'   inputs  = c("industrial_labour_force", "working_funds", "investments"),
#'   outputs = c("gross_industrial_output", "profit_and_tax", "retail_sales"),
#'   id      = "DMU"
#' )
#' d
"chinese_cities"

#' Inputs and outputs of 22 Taiwanese commercial banks, 2009-2011
#'
#' A balanced panel (long-format) data envelopment analysis (DEA) dataset
#' describing 22 Taiwanese commercial banks over three years (2009-2011) by
#' three inputs and three outputs. It is the worked example of Kao and Liu
#' (2014) on multi-period efficiency measurement, and is the example dataset for
#' \code{\link{plot_panel_io_biplot}}.
#'
#' @format A data frame with 66 rows (22 banks \eqn{\times} 3 years) and 8
#'   variables:
#' \describe{
#'   \item{DMU}{Bank name (the decision-making unit label).}
#'   \item{Year}{Period: 2009, 2010 or 2011.}
#'   \item{labour}{Input 1 (I1): labour.}
#'   \item{physical_capital}{Input 2 (I2): physical capital.}
#'   \item{purchased_funds}{Input 3 (I3): purchased funds.}
#'   \item{demand_deposits}{Output 1 (O1): demand deposits.}
#'   \item{short_term_loans}{Output 2 (O2): short-term loans.}
#'   \item{long_term_loans}{Output 3 (O3): medium- and long-term loans.}
#' }
#'
#' @details Columns 3-5 are inputs (I1-I3) and columns 6-8 are outputs (O1-O3);
#'   \code{DMU} and \code{Year} identify each observation. The input/output
#'   columns are not \code{i_}/\code{o_} prefixed, so pass them by position
#'   (e.g. \code{inputs = 3:5, outputs = 6:8}) or by name to
#'   \code{\link{plot_panel_io_biplot}} (see Examples).
#'
#' @source Kao, C. and Liu, S.-T. (2014). Multi-period efficiency measurement in
#'   data envelopment analysis: The case of Taiwanese commercial banks.
#'   \emph{Omega}, 47, 90-98. \doi{10.1016/j.omega.2013.09.001}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' plot_panel_io_biplot(
#'   taiwanese_banks, id = "DMU", period = "Year",
#'   inputs = 3:5, outputs = 6:8, labels = "Cathay"
#' )
"taiwanese_banks"
