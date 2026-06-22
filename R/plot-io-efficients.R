#' Counts of efficient and inefficient DMUs
#'
#' Classifies the DMUs as efficient or inefficient (efficiency score equal to 1
#' within a tolerance) and draws a bar chart of the counts, annotated with the
#' percentage of DMUs in each group.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param rts Returns to scale passed to \code{\link{compute_efficiency}}.
#' @param orientation Measurement orientation passed to
#'   \code{\link{compute_efficiency}}.
#' @param tol Tolerance for treating a score as efficient (default
#'   \code{1e-6}).
#' @param labels Logical; if \code{TRUE} (default) the count and percentage are
#'   printed on each bar.
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... Additional arguments passed to \code{geom_col}.
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
#' @param subtitle Optional subtitle shown beneath the title.
#' @return A \pkg{ggplot2} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @seealso \code{\link{plot_efficiency_distributions}}, \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_efficients(df, rts = "crs")
#'
#' @export
plot_io_efficients <- function(x,
                               rts = c("crs", "vrs", "drs", "irs",
                                       "fdh", "add"),
                               orientation = "in", tol = 1e-6, labels = TRUE,
                               transparency = 0.7, subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_alpha(transparency)
  rts <- match.arg(rts)
  .deaviz_check_flag(labels, "labels")
  if (!is.numeric(tol) || length(tol) != 1L || tol < 0)
    stop("`tol` must be a single non-negative number.", call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)

  d   <- as_dea_data(x)
  eff <- as.numeric(compute_efficiency(d, rts = rts, orientation = orientation,
                                       dual = FALSE)$eff)
  status <- factor(ifelse(abs(eff - 1) < tol, "Efficient", "Inefficient"),
                   levels = c("Efficient", "Inefficient"))

  tab <- data.frame(status = levels(status),
                    count  = as.integer(table(status)),
                    stringsAsFactors = FALSE)
  tab$status <- factor(tab$status, levels = c("Efficient", "Inefficient"))
  tab$pct    <- 100 * tab$count / sum(tab$count)
  tab$label  <- sprintf("%d (%.1f%%)", tab$count, tab$pct)

  g <- ggplot2::ggplot(tab, ggplot2::aes(x = .data$status, y = .data$count,
                                         fill = .data$status)) +
    ggplot2::geom_col(alpha = transparency, ...) +
    ggplot2::scale_fill_manual(values = .deaviz_status_colours()) +
    ggplot2::labs(x = NULL, y = "Number of DMUs") +
    .deaviz_theme() +
    ggplot2::theme(legend.position = "none")
  if (labels)
    g <- g + ggplot2::geom_text(ggplot2::aes(label = .data$label),
                                vjust = -0.3)

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
