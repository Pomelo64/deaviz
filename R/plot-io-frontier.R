#' DEA efficient frontier for a single input/output pair
#'
#' Draws the classic two-dimensional DEA picture: the decision-making units in
#' \code{input}-by-\code{output} space, the production-possibility set shaded
#' beneath the frontier, and the efficient frontier itself for the chosen
#' returns-to-scale assumption. Optionally overlays the peer (reference) network
#' as arrows from each inefficient unit to its efficient targets.
#'
#' The whole plot is a single, self-consistent two-variable DEA: the frontier,
#' the colour scale, and the peer arrows are all derived from
#' \code{compute_efficiency()} run on the chosen \code{input}/\code{output} pair
#' at the chosen \code{rts}. A unit's colour is therefore its efficiency in
#' \emph{this} two-variable sub-model, which may differ from its efficiency in
#' the full multidimensional model -- so a point sitting on the frontier line
#' reads as efficient, as it should.
#'
#' @param x A \code{dea_data} object, or data coercible by
#'   \code{\link{as_dea_data}}.
#' @param input,output The single input and single output to plot, each given as
#'   a column name or as an integer position among the inputs/outputs.
#' @param rts Returns to scale for the frontier and efficiency scores:
#'   \code{"crs"} (default), \code{"vrs"}, \code{"drs"}, \code{"irs"} or
#'   \code{"fdh"}.
#' @param orientation \code{"in"} (default) or \code{"out"}; affects the
#'   efficiency scores and the direction of projection arrows.
#' @param peers_network Logical; if \code{TRUE}, draw arrows from inefficient
#'   units to their efficient reference set. Default \code{FALSE}. With a single
#'   DMU named in \code{labels}, only that unit's arrows are drawn; otherwise
#'   every inefficient unit's arrows are shown.
#' @param arrow_target \code{"peer"} (default) draws an arrow to each efficient
#'   peer DMU, with opacity proportional to its envelopment weight
#'   (\eqn{\lambda}); \code{"projection"} draws one arrow per inefficient unit to
#'   its projected point on the frontier (respecting \code{orientation}), at
#'   uniform opacity.
#' @param point_size Point size. Default \code{2}.
#' @param transparency Base point/arrow alpha, a number in \code{[0, 1]}.
#'   Default \code{0.7}.
#' @param fade Focus control when a single DMU is given to \code{labels}; see
#'   \code{\link{plot_io_scatter}}. Default \code{TRUE}.
#' @param label_frontier Logical; label the efficient (frontier) units. Default
#'   \code{TRUE}.
#' @param labels Labelling/focus mode: \code{"none"} (default), \code{"all"},
#'   \code{"id"}, \code{"max.overlaps"}, or a single DMU name to highlight.
#' @param max.overlaps.value Passed to \pkg{ggrepel}. Default \code{10}.
#' @param subtitle Plot subtitle. \code{NULL} (default) shows
#'   \dQuote{{input} and {output} sub-model {RTS} efficient frontier}; pass a
#'   string to override, or \code{NA} to suppress.
#' @param title Plot title.
#' @param interactive If \code{TRUE}, return a \pkg{plotly} object. Default
#'   \code{FALSE}.
#' @param ... Passed to the point geom.
#'
#' @return A \code{ggplot} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @references
#' Charnes, A., Cooper, W. W., & Rhodes, E. (1978). Measuring the efficiency of
#' decision making units. \emph{European Journal of Operational Research},
#' 2(6), 429--444. \doi{10.1016/0377-2217(78)90138-8}
#'
#' @seealso \code{\link{plot_io_scatter}}, \code{\link{plot_io_peer_network}},
#'   \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' d <- dea_data(
#'   chinese_cities,
#'   inputs  = c("industrial_labour_force", "working_funds", "investments"),
#'   outputs = c("gross_industrial_output", "profit_and_tax", "retail_sales"),
#'   id      = "DMU"
#' )
#' plot_io_frontier(d, input = "working_funds", output = "retail_sales",
#'                  rts = "vrs")
#' # peer network for one city, arrows weighted by lambda
#' plot_io_frontier(d, input = "working_funds", output = "retail_sales",
#'                  rts = "vrs", peers_network = TRUE, labels = "Beijing")
#'
#' @export
plot_io_frontier <- function(x, input, output,
                             rts = c("crs", "vrs", "drs", "irs", "fdh"),
                             orientation = c("in", "out"),
                             peers_network = FALSE,
                             arrow_target = c("peer", "projection"),
                             point_size = 2, transparency = 0.7, fade = TRUE,
                             label_frontier = TRUE,
                             labels = "none", max.overlaps.value = 10,
                             subtitle = NULL, title = NULL,
                             interactive = FALSE, ...) {
  rts          <- match.arg(rts)
  orientation  <- match.arg(orientation)
  arrow_target <- match.arg(arrow_target)
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  .deaviz_check_flag(peers_network, "peers_network")
  .deaviz_check_flag(label_frontier, "label_frontier")
  .deaviz_check_alpha(transparency)
  if (!is.numeric(point_size) || length(point_size) != 1L || point_size <= 0)
    stop("`point_size` must be a single positive number.", call. = FALSE)
  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)

  d <- as_dea_data(x)

  pick <- function(sel, choices, role) {
    if (is.numeric(sel)) {
      if (length(sel) != 1L || sel < 1 || sel > length(choices) ||
          sel != as.integer(sel))
        stop("`", role, "` must be a single name or a position in 1:",
             length(choices), ".", call. = FALSE)
      return(choices[sel])
    }
    if (is.character(sel) && length(sel) == 1L) {
      s <- sub("^[io]_", "", sel, ignore.case = TRUE)
      if (!s %in% choices)
        stop("`", role, "` '", sel, "' is not one of the ", role, "s: ",
             toString(choices), ".", call. = FALSE)
      return(s)
    }
    stop("`", role, "` must be a single ", role, " name or column position.",
         call. = FALSE)
  }
  xvar <- pick(input,  colnames(d$X), "input")
  yvar <- pick(output, colnames(d$Y), "output")

  # one-input/one-output sub-model: everything below is consistent with it
  sub    <- d
  sub$X  <- d$X[, xvar, drop = FALSE]
  sub$Y  <- d$Y[, yvar, drop = FALSE]
  model  <- compute_efficiency(sub, rts = rts, orientation = orientation,
                               dual = FALSE)
  eff_raw <- as.numeric(model$eff)
  lambda  <- model$lambda
  is_eff  <- abs(eff_raw - 1) < 1e-9
  # display score in [0, 1] (Benchmarking output-oriented eff is >= 1)
  eff     <- if (orientation == "out") 1 / eff_raw else eff_raw

  xv <- as.numeric(d$X[, xvar])
  yv <- as.numeric(d$Y[, yvar])
  df <- data.frame(dmu = d$labels, xv = xv, yv = yv,
                   efficiency = round(eff, 3), stringsAsFactors = FALSE)

  fr <- .deaviz_frontier_path(xv, yv, is_eff, rts)

  sub_default <- paste0(xvar, " and ", yvar, " sub-model ", toupper(rts),
                        " efficient frontier")
  subtitle <- if (is.null(subtitle)) sub_default
              else if (length(subtitle) == 1L && is.na(subtitle)) NULL
              else subtitle

  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)
  spec  <- .deaviz_label_spec(labels, df$dmu, max.overlaps.value)
  df$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(df$dmu == spec$which, transparency, flev) else transparency

  g <- ggplot2::ggplot()

  # production-possibility set (shaded) + frontier line
  if (nrow(fr$poly) > 2L)
    g <- g + ggplot2::geom_polygon(
      data = fr$poly, ggplot2::aes(x = .data$x, y = .data$y),
      fill = .deaviz_ring(), alpha = 0.08, colour = NA)
  g <- g + ggplot2::geom_path(
    data = fr$line, ggplot2::aes(x = .data$x, y = .data$y),
    colour = "#E69F00", linewidth = 1)

  # peer (reference) arrows
  if (peers_network) {
    idx <- which(lambda > 1e-6, arr.ind = TRUE)
    idx <- idx[idx[, 1] != idx[, 2] & !is_eff[idx[, 1]] & is_eff[idx[, 2]], ,
               drop = FALSE]
    if (spec$mode == "one") {
      foc <- match(spec$which, df$dmu)
      idx <- idx[idx[, 1] == foc, , drop = FALSE]
    }
    if (nrow(idx) > 0L) {
      if (arrow_target == "peer") {
        r <- idx[, 1]; c <- idx[, 2]; lam <- lambda[idx]
        edges <- data.frame(x = xv[r], y = yv[r], xend = xv[c], yend = yv[c],
                            a = transparency * pmax(0.15, lam / max(lam)))
      } else {
        r  <- unique(idx[, 1])
        if (orientation == "in") { px <- eff_raw[r] * xv[r]; py <- yv[r] }
        else                     { px <- xv[r]; py <- yv[r] * eff_raw[r] }
        edges <- data.frame(x = xv[r], y = yv[r], xend = px, yend = py,
                            a = transparency)
      }
      g <- g + ggplot2::geom_segment(
        data = edges,
        ggplot2::aes(x = .data$x, y = .data$y, xend = .data$xend,
                     yend = .data$yend, alpha = .data$a),
        colour = .deaviz_accent(),
        arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm"),
                               type = "closed"))
    }
  }

  # units, coloured by sub-model efficiency
  g <- g + ggplot2::geom_point(
    data = df,
    .deaviz_aes(ggplot2::aes(x = .data$xv, y = .data$yv,
                 colour = .data$efficiency, alpha = .data$.fa,
                 text = paste0(.data$dmu, "<br>Efficiency: ",
                               .data$efficiency)), interactive),
    size = point_size, ...) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_gradientn(colours = .deaviz_sequential(),
                                    name = "Sub-model\nefficiency")

  # label efficient (frontier) units
  if (label_frontier && any(is_eff)) {
    lab_df <- df[is_eff, , drop = FALSE]
    if (repel)
      g <- g + ggrepel::geom_text_repel(
        data = lab_df, ggplot2::aes(x = .data$xv, y = .data$yv,
                                    label = .data$dmu),
        size = 3, seed = 42, max.overlaps = max.overlaps.value,
        segment.colour = .deaviz_arrow(), box.padding = 0.4)
    else
      g <- g + ggplot2::geom_text(
        data = lab_df, ggplot2::aes(x = .data$xv, y = .data$yv,
                                    label = .data$dmu),
        size = 3, vjust = -0.6)
  }

  # single-DMU focus highlight (ring + label), consistent with other plots
  g <- .deaviz_text_labels(g, df, spec, repel, max.overlaps.value,
                           "xv", "yv", "dmu", ring = TRUE,
                           ring_size = point_size + 1.2)

  g <- g +
    ggplot2::coord_cartesian(xlim = c(0, max(xv) * 1.05),
                             ylim = c(0, max(yv) * 1.08)) +
    ggplot2::labs(x = xvar, y = yvar) +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}

# Build the frontier polyline and the envelope polygon for a single
# input/output pair, given which units are efficient and the RTS. The efficient
# set defines the vertices; CRS is a ray through the most productive unit, VRS
# the convex NW hull, FDH a staircase, and DRS/IRS splice the CRS ray with the
# VRS hull at the most-productive-scale-size point.
.deaviz_frontier_path <- function(xv, yv, is_eff, rts) {
  xend  <- max(xv) * 1.05
  ratio <- yv / xv
  slope <- max(ratio)
  effi  <- which(is_eff)
  mp    <- effi[which.max(ratio[effi])]
  if (!length(mp)) mp <- which.max(ratio)
  xm <- xv[mp]

  ex <- xv[is_eff]; ey <- yv[is_eff]
  o  <- order(ex); ex <- ex[o]; ey <- ey[o]
  n  <- length(ex)

  line <- switch(rts,
    crs = data.frame(x = c(0, xend), y = c(0, slope * xend)),
    vrs = data.frame(x = c(ex[1], ex, xend),
                     y = c(0,     ey, ey[n])),
    fdh = {
      xs <- c(ex[1], ex[1]); ys <- c(0, ey[1])
      for (i in seq_len(n)[-1]) {
        xs <- c(xs, ex[i], ex[i]); ys <- c(ys, ey[i - 1], ey[i])
      }
      data.frame(x = c(xs, xend), y = c(ys, ey[n]))
    },
    drs = {
      keep <- ex >= xm; hx <- ex[keep]; hy <- ey[keep]
      data.frame(x = c(0, hx, xend), y = c(0, hy, hy[length(hy)]))
    },
    irs = {
      keep <- ex <= xm; hx <- ex[keep]; hy <- ey[keep]
      data.frame(x = c(hx[1], hx, xend), y = c(0, hy, slope * xend))
    }
  )

  poly <- rbind(line,
                data.frame(x = c(line$x[nrow(line)], line$x[1]), y = c(0, 0)))
  list(line = line, poly = poly)
}
