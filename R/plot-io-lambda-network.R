#' DEA reference (lambda) network
#'
#' Projects the DMUs into two dimensions with Sammon mapping and draws the DEA
#' reference network on top: each DMU is a node coloured by efficiency status,
#' and an edge joins unit \eqn{r} to a reference peer \eqn{c} whenever the
#' envelopment weight \eqn{\lambda_{rc}} exceeds \code{edge_threshold}. Edge
#' width is proportional to \eqn{\lambda}, shown in the legend.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param rts Returns to scale, passed to \code{\link{compute_efficiency}}:
#'   \code{"crs"} or \code{"vrs"}.
#' @param edge_threshold Minimum envelopment weight for an edge to be drawn
#'   (single non-negative number, default \code{0.1}).
#' @param labels Which DMUs to label: \code{"none"} (default), \code{"all"}
#'   (label every DMU; \pkg{ggrepel} with \code{max.overlaps = Inf}),
#'   \code{"max.overlaps"} (\pkg{ggrepel} using \code{max.overlaps.value}),
#'   or the name/id of a single DMU to highlight just that one.
#'   Use \code{"id"} to print each DMU's row number inside its own marker.
#' @param max.overlaps.value Passed to \pkg{ggrepel} when
#'   \code{labels = "max.overlaps"} (default \code{10}); larger values keep
#'   more crowded labels.
#' @param transparency Node alpha in \code{[0, 1]} (default \code{0.7}); lower
#'   values reveal overlapping nodes.
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... Further arguments passed to \code{\link[MASS]{sammon}}
#'   (e.g. \code{niter}).
#'
#' @param subtitle Optional subtitle shown beneath the title.
#' @param fade Controls the single-DMU focus view. When one DMU is given to
#'   \code{labels}, all other marks (and, for the network plots, everything
#'   outside that DMU's sub-network; for the panel biplot, the other
#'   trajectories) are faded so the chosen DMU stands out. \code{TRUE} (default)
#'   uses a sensible fade level; \code{FALSE} disables it; a single number in
#'   \code{[0, 1]} sets the alpha of the faded marks directly, where larger
#'   values fade them less (e.g. \code{0.4} leaves them more visible).
#' @return A \pkg{ggplot2} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @references
#' Porembski, M., Breitenstein, K., & Alpar, P. (2005). Visualizing efficiency
#' and reference relations in data envelopment analysis with an application to
#' the branches of a German bank. \emph{Journal of Productivity Analysis},
#' 23(2), 203--221. \doi{10.1007/s11123-005-1328-5}
#'
#' Sammon, J. W. (1969). A nonlinear mapping for data structure analysis.
#' \emph{IEEE Transactions on Computers}, C-18(5), 401--409.
#' \doi{10.1109/T-C.1969.222678}
#' @seealso \code{\link{compute_efficiency}}, \code{\link{plot_io_peer_network}},
#'   \code{\link[MASS]{sammon}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("MASS", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_lambda_network(df, rts = "crs")
#'
#' @export
plot_io_lambda_network <- function(x, rts = c("crs", "vrs"),
                                   edge_threshold = 0.1, labels = "none",
                                   max.overlaps.value = 10,
                                   transparency = 0.7, fade = TRUE, subtitle = NULL, title = NULL,
                                   interactive = FALSE, ...) {
  rts <- match.arg(rts)
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  if (!is.numeric(edge_threshold) || length(edge_threshold) != 1L ||
      !is.finite(edge_threshold) || edge_threshold < 0)
    stop("`edge_threshold` must be a single non-negative number.", call. = FALSE)
  if (!is.numeric(transparency) || length(transparency) != 1L ||
      transparency < 0 || transparency > 1)
    stop("`transparency` must be a single number in [0, 1].", call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE) ||
      !requireNamespace("MASS", quietly = TRUE))
    stop("Packages 'Benchmarking' and 'MASS' are required for this plot.",
         call. = FALSE)

  d        <- as_dea_data(x)
  data_mat <- cbind(d$X, d$Y)
  sds <- apply(data_mat, 2, stats::sd)
  if (any(sds == 0))
    stop("Sammon mapping cannot use constant (zero-variance) column(s): ",
         toString(colnames(data_mat)[sds == 0]), ".", call. = FALSE)

  proj <- MASS::sammon(stats::dist(scale(data_mat)), k = 2, trace = FALSE, ...)
  pts  <- proj$points

  model  <- compute_efficiency(d, rts = rts, dual = FALSE)
  eff    <- as.numeric(model$eff)
  lambda <- model$lambda

  nodes <- data.frame(
    dmu        = d$labels,
    x          = pts[, 1],
    y          = pts[, 2],
    efficiency = round(eff, 3),
    status     = factor(ifelse(abs(eff - 1) < 1e-9, "Efficient", "Inefficient"),
                        levels = c("Efficient", "Inefficient")),
    stringsAsFactors = FALSE
  )

  idx <- which(lambda > edge_threshold, arr.ind = TRUE)
  idx <- idx[idx[, 1] != idx[, 2], , drop = FALSE]
  edges <- data.frame(
    x = pts[idx[, 1], 1], y = pts[idx[, 1], 2],
    xend = pts[idx[, 2], 1], yend = pts[idx[, 2], 2],
    lambda = lambda[idx],
    from = d$labels[idx[, 1]], to = d$labels[idx[, 2]],
    stringsAsFactors = FALSE
  )
  lim   <- range(pts)
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  spec <- .deaviz_label_spec(labels, nodes$dmu, max.overlaps.value)
  focus <- spec$mode == "one" && !is.null(flev)
  if (focus) {
    inc  <- edges$from == spec$which | edges$to == spec$which
    near <- unique(c(spec$which, edges$from[inc], edges$to[inc]))
    nodes$.fa  <- .deaviz_fade_alpha(nodes$dmu %in% near, transparency, flev)
    if (nrow(edges) > 0L) edges$.ea <- .deaviz_fade_alpha(inc, 0.6, flev)
  } else {
    nodes$.fa <- transparency
    if (nrow(edges) > 0L) edges$.ea <- 0.6
  }

  g <- ggplot2::ggplot()
  if (nrow(edges) > 0L)
    g <- g + ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend,
                   yend = .data$yend, linewidth = .data$lambda,
                   alpha = .data$.ea),
      colour = .deaviz_accent()) +
      ggplot2::scale_linewidth_continuous(name = "lambda",
                                          range = c(0.2, 1.6))

  g <- g + ggplot2::geom_point(
    data = nodes,
    .deaviz_aes(ggplot2::aes(x = .data$x, y = .data$y, colour = .data$status,
                 alpha = .data$.fa,
                 text = paste0(.data$dmu, "<br>Efficiency: ",
                               .data$efficiency)), interactive),
    size = 3) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_manual(name = paste0("DMU (", toupper(rts), ")"),
                                 values = .deaviz_status_colours())

  g <- .deaviz_text_labels(g, nodes, spec, repel, max.overlaps.value,
                           "x", "y", "dmu", ring = TRUE, ring_size = 4.2)

  g <- g +
    ggplot2::coord_fixed(xlim = lim, ylim = lim) +
    ggplot2::labs(x = NULL, y = NULL) +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
