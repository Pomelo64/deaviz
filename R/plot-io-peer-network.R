#' DEA peer (target) network
#'
#' Draws a directed network of DMUs: each inefficient unit has arrows pointing to
#' its efficient peers (the targets in its DEA reference set, i.e. the efficient
#' units with a positive envelopment weight). Arrowheads stop short of the target
#' node so the direction stays readable. Nodes are coloured by efficiency status
#' and, optionally, efficient nodes are sized by how often they are a target.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param rts Returns to scale, passed to \code{\link{compute_efficiency}}:
#'   \code{"crs"} or \code{"vrs"}.
#' @param layout Node layout: \code{"pca"} (default, first two principal
#'   components of the standardised inputs/outputs), \code{"mds"} (classical
#'   multidimensional scaling), \code{"circle"}, \code{"fr"}
#'   (Fruchterman-Reingold force-directed) or \code{"stress"} (stress
#'   majorization). The last two require the \pkg{igraph} package (and
#'   \pkg{graphlayouts} for true stress majorization; otherwise a Kamada-Kawai
#'   layout is used).
#' @param size_by_peers Logical; if \code{TRUE}, efficient nodes are sized by the
#'   number of inefficient units that target them. If \code{FALSE} (default) all
#'   nodes have the same size.
#' @param tol Tolerance for a positive envelopment weight (default \code{1e-6}).
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
#' @param ... Additional arguments passed to \code{geom_point}.
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
#' @seealso \code{\link{compute_efficiency}}, \code{\link{plot_io_lambda_network}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_peer_network(df, rts = "crs", size_by_peers = TRUE)
#'
#' @export
plot_io_peer_network <- function(x, rts = c("crs", "vrs"),
                                 layout = c("pca", "mds", "circle", "fr",
                                            "stress"),
                                 size_by_peers = FALSE, tol = 1e-6,
                                 labels = "none", max.overlaps.value = 10,
                                 transparency = 0.7, fade = TRUE,
                                 subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  rts    <- match.arg(rts)
  layout <- match.arg(layout)
  .deaviz_check_flag(size_by_peers, "size_by_peers")
  if (!is.numeric(tol) || length(tol) != 1L || tol < 0)
    stop("`tol` must be a single non-negative number.", call. = FALSE)
  if (!is.numeric(transparency) || length(transparency) != 1L ||
      transparency < 0 || transparency > 1)
    stop("`transparency` must be a single number in [0, 1].", call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required for this plot.", call. = FALSE)

  d        <- as_dea_data(x)
  data_mat <- cbind(d$X, d$Y)
  n        <- nrow(data_mat)
  sds <- apply(data_mat, 2, stats::sd)
  if (any(sds == 0))
    stop("The layout cannot use constant (zero-variance) column(s): ",
         toString(colnames(data_mat)[sds == 0]), ".", call. = FALSE)

  model  <- compute_efficiency(d, rts = rts, dual = FALSE)
  eff    <- as.numeric(model$eff)
  lambda <- model$lambda
  is_eff <- abs(eff - 1) < 1e-9
  lab    <- d$labels
  if (is.null(lab)) lab <- paste0("DMU", seq_len(n))

  # directed edges: inefficient r -> efficient target c (lambda_rc > tol)
  idx <- which(lambda > tol, arr.ind = TRUE)
  idx <- idx[idx[, 1] != idx[, 2] & !is_eff[idx[, 1]] & is_eff[idx[, 2]], ,
             drop = FALSE]

  pos <- switch(layout,
    pca    = stats::prcomp(data_mat, center = TRUE, scale. = TRUE)$x[, 1:2],
    mds    = stats::cmdscale(stats::dist(scale(data_mat)), k = 2),
    circle = {
      a <- seq(0, 2 * pi, length.out = n + 1)[seq_len(n)]
      cbind(cos(a), sin(a))
    },
    fr     = ,
    stress = {
      if (!requireNamespace("igraph", quietly = TRUE))
        stop("Package 'igraph' is required for layout = '", layout, "'.",
             call. = FALSE)
      ig <- igraph::make_empty_graph(n = n, directed = TRUE)
      if (nrow(idx) > 0L) ig <- igraph::add_edges(ig, as.vector(t(idx[, 1:2])))
      if (layout == "fr") igraph::layout_with_fr(ig)
      else if (requireNamespace("graphlayouts", quietly = TRUE))
        graphlayouts::layout_with_stress(ig)
      else igraph::layout_with_kk(ig)
    }
  )
  pos <- as.matrix(pos)

  peer_count <- integer(n)
  if (nrow(idx) > 0L) {
    tt <- table(idx[, 2])
    peer_count[as.integer(names(tt))] <- as.integer(tt)
  }

  # shorten each edge so the arrowhead stops short of the target node
  edges <- NULL
  if (nrow(idx) > 0L) {
    x0 <- pos[idx[, 1], 1]; y0 <- pos[idx[, 1], 2]
    x1 <- pos[idx[, 2], 1]; y1 <- pos[idx[, 2], 2]
    dx <- x1 - x0; dy <- y1 - y0
    len <- sqrt(dx^2 + dy^2); len[len == 0] <- 1
    gap <- 0.025 * max(diff(range(pos[, 1])), diff(range(pos[, 2])))
    edges <- data.frame(x = x0, y = y0,
                        xend = x1 - dx / len * gap,
                        yend = y1 - dy / len * gap,
                        from = lab[idx[, 1]], to = lab[idx[, 2]],
                        stringsAsFactors = FALSE)
  }

  nodes <- data.frame(
    dmu    = lab, x = pos[, 1], y = pos[, 2],
    status = factor(ifelse(is_eff, "Efficient", "Inefficient"),
                    levels = c("Efficient", "Inefficient")),
    peers  = peer_count,
    stringsAsFactors = FALSE
  )
  lim   <- range(pos)
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  spec  <- .deaviz_label_spec(labels, nodes$dmu, max.overlaps.value)
  focus <- spec$mode == "one" && !is.null(flev)
  if (focus) {
    inc  <- !is.null(edges) & FALSE
    if (!is.null(edges)) inc <- edges$from == spec$which | edges$to == spec$which
    near <- if (is.null(edges)) spec$which
            else unique(c(spec$which, edges$from[inc], edges$to[inc]))
    nodes$.fa <- .deaviz_fade_alpha(nodes$dmu %in% near, transparency, flev)
    if (!is.null(edges)) edges$.ea <- .deaviz_fade_alpha(inc, 0.6, flev)
  } else {
    nodes$.fa <- transparency
    if (!is.null(edges)) edges$.ea <- 0.6
  }

  g <- ggplot2::ggplot()
  if (!is.null(edges))
    g <- g + ggplot2::geom_segment(
      data = edges,
      ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend,
                   yend = .data$yend, alpha = .data$.ea),
      colour = .deaviz_accent(), linewidth = 0.4,
      arrow = ggplot2::arrow(length = ggplot2::unit(0.2, "cm"),
                             type = "closed"))

  if (size_by_peers) {
    g <- g + ggplot2::geom_point(
      data = nodes,
      .deaviz_aes(ggplot2::aes(x = .data$x, y = .data$y, colour = .data$status,
                   size = .data$peers,
                   alpha = .data$.fa,
                   text = paste0(.data$dmu, "<br>targeted ", .data$peers,
                                 " time(s)")), interactive),
      ...) +
      ggplot2::scale_size_continuous(name = "times targeted",
                                     range = c(2.5, 9))
  } else {
    g <- g + ggplot2::geom_point(
      data = nodes,
      .deaviz_aes(ggplot2::aes(x = .data$x, y = .data$y, colour = .data$status,
                   alpha = .data$.fa, text = .data$dmu), interactive),
      size = 4, ...)
  }

  g <- g + ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_manual(name = paste0("DMU (", toupper(rts), ")"),
                                        values = .deaviz_status_colours())

  rsz <- if (size_by_peers && spec$mode == "one") {
    rng <- range(nodes$peers)
    base <- if (diff(rng) == 0) 5
            else 2.5 + (nodes$peers[match(spec$which, nodes$dmu)] - rng[1]) /
                       diff(rng) * 6.5
    base + 1.4
  } else 5.4
  g <- .deaviz_text_labels(g, nodes, spec, repel, max.overlaps.value,
                           "x", "y", "dmu", ring = TRUE, ring_size = rsz)

  g <- g +
    ggplot2::coord_fixed(xlim = lim, ylim = lim) +
    ggplot2::labs(x = NULL, y = NULL) +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
