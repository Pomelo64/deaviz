#' deaviz: Visualization of Data Envelopment Analysis Problems
#'
#' \pkg{deaviz} collects high-dimensional visualization methods for data
#' envelopment analysis (DEA) in a single package. It is built around one
#' validated data object, \code{\link{dea_data}}, which every function accepts
#' (data frames are coerced automatically). Analysis functions are named
#' \code{compute_*} and return values; visualization functions are named
#' \code{plot_*}.
#'
#' @section Workflow:
#' Build a \code{dea_data} object (or pass a data frame, recognised by
#' \code{i_}/\code{o_} column prefixes or explicit \code{inputs}/\code{outputs}),
#' then call any \code{compute_*} or \code{plot_*} function on it. The
#' \code{\link[Benchmarking]{dea}} solver in the \pkg{Benchmarking} package is
#' the computational engine; plotting uses \pkg{plotly} and \pkg{ggplot2}. These
#' and the other modelling packages are listed in \code{Suggests}: each function
#' checks for the ones it needs and gives an informative error if they are
#' missing.
#'
#' @keywords internal
#' @aliases deaviz-package
#' @references
#' Ashkiani, S. (2019). \emph{Four Essays on Data Visualization and Anomaly
#' Detection of Data Envelopment Analysis Problems} [PhD thesis, Universitat
#' Autonoma de Barcelona]. \url{https://ddd.uab.cat/record/240333}
#'
#' Adler, N., & Raveh, A. (2008). Presenting DEA graphically. \emph{Omega},
#' 36(5), 715--729.
#'
#' Bana e Costa, C. A., Soares de Mello, J. C. C. B., & Angulo Meza, L. (2016).
#' A new approach to the bi-dimensional representation of the DEA efficient
#' frontier with multiple inputs and outputs. \emph{European Journal of
#' Operational Research}, 255(1), 175--186. \doi{10.1016/j.ejor.2016.05.012}
#'
#' Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
#' Derivations, meanings and uses. \emph{Journal of the Operational Research
#' Society}, 45(5), 567--578. \doi{10.1057/jors.1994.84}
#'
#' Porembski, M., Breitenstein, K., & Alpar, P. (2005). Visualizing efficiency
#' and reference relations in data envelopment analysis with an application to
#' the branches of a German bank. \emph{Journal of Productivity Analysis},
#' 23(2), 203--221. \doi{10.1007/s11123-005-1328-5}
#'
#' Ashkiani, S., & Mar-Molinero, C. (2017). Visualization of cross-efficiency
#' matrices using multidimensional unfolding. In \emph{Recent Applications of
#' Data Envelopment Analysis}.
#' @importFrom rlang .data
"_PACKAGE"
