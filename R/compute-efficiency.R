#' Compute DEA efficiency scores
#'
#' Computes data envelopment analysis (DEA) efficiency scores for a set of
#' decision-making units, under any of the returns-to-scale assumptions
#' supported by \code{\link[Benchmarking]{dea}}. The numerical work is done by
#' the \pkg{Benchmarking} package; this function wraps it so the input/output
#' data follow the \code{\link{dea_data}} contract and the call sits inside one
#' consistent entry point.
#'
#' The returns-to-scale assumption is selected with \code{rts}: in particular
#' \code{"crs"} (constant) and \code{"vrs"} (variable) are the two most common
#' models, but \code{"drs"}, \code{"irs"}, \code{"irs2"}, \code{"fdh"} and
#' \code{"add"} are available as well.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}} using the default \code{i_}/\code{o_} prefix
#'   detection. For non-default column selection (explicit \code{inputs}/
#'   \code{outputs}/\code{id}), build the object first with
#'   \code{\link{dea_data}} and pass it in.
#' @param rts Returns to scale, one of \code{"crs"}, \code{"vrs"}, \code{"drs"},
#'   \code{"irs"}, \code{"irs2"}, \code{"fdh"} or \code{"add"}.
#' @param orientation Measurement orientation, forwarded to
#'   \code{\link[Benchmarking]{dea}} (e.g. \code{"in"}, \code{"out"} or
#'   \code{"graph"}).
#' @param dual Logical; if \code{TRUE} the multiplier (dual) solution is also
#'   returned. Set \code{FALSE} to skip it when only the scores are needed.
#' @param slack Logical; if \code{TRUE} slacks are computed as well.
#' @param ... Further arguments forwarded to \code{\link[Benchmarking]{dea}}.
#'
#' @return The \code{Farrell} object returned by
#'   \code{\link[Benchmarking]{dea}}, whose \code{$eff} component holds the
#'   efficiency scores.
#'
#' @seealso \code{\link[Benchmarking]{dea}}, which performs the computation;
#'   \code{\link{dea_data}} for the data contract.
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(i_x = c(2, 3, 4), o_y = c(1, 2, 2))
#' compute_efficiency(df, rts = "crs")$eff
#' compute_efficiency(df, rts = "vrs")$eff
#'
#' @export
compute_efficiency <- function(x,
                               rts = c("crs", "vrs", "drs", "irs",
                                       "irs2", "fdh", "add"),
                               orientation = "in", dual = TRUE,
                               slack = FALSE, ...) {
  rts <- match.arg(rts)
  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency scores.",
         call. = FALSE)
  d <- as_dea_data(x)
  Benchmarking::dea(X = d$X, Y = d$Y, RTS = rts,
                    ORIENTATION = orientation, DUAL = dual, SLACK = slack, ...)
}
