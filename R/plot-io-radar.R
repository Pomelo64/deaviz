#' Radar plot of inputs and outputs
#'
#' Draws a radar (spider) plot with one axis per input and output, each min-max
#' scaled to \code{[0, 1]}, and one closed polygon per DMU with straight edges.
#' Polygons are coloured by efficient/inefficient status. A radial counterpart to
#' \code{\link{plot_io_parcoo}}.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param efficiency Efficiency model used to colour the DMUs by
#'   efficient/inefficient status: \code{"crs"} (default), \code{"vrs"} or
#'   \code{"none"}.
#' @param orientation Measurement orientation for the efficiency scores.
#' @param labels DMU emphasis: \code{"none"} (default) or \code{"all"} draw
#'   every DMU normally; the name/id of a single DMU outlines that DMU's
#'   polygon in bold so it stands out. (Variable axis labels are always
#'   shown.)
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; if \code{FALSE} (default) a static \pkg{ggplot2}
#'   radar; if \code{TRUE} an interactive \pkg{plotly} \code{scatterpolar}.
#' @param ... Additional arguments passed to \code{geom_polygon} (static mode).
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
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
#' @seealso \code{\link{plot_io_parcoo}}, \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_radar(df, efficiency = "crs")
#'
#' @export
plot_io_radar <- function(x, efficiency = c("crs", "vrs", "none"),
                          orientation = "in", labels = "none",
                          max.overlaps.value = 10,
                          transparency = 0.7, fade = TRUE, subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_alpha(transparency)
  efficiency <- match.arg(efficiency)

  d    <- as_dea_data(x)
  io   <- as.data.frame(cbind(d$X, d$Y))
  vars <- colnames(io)
  lab  <- d$labels
  if (is.null(lab)) lab <- paste0("DMU", seq_len(nrow(io)))

  status <- NULL
  if (efficiency != "none") {
    if (!requireNamespace("Benchmarking", quietly = TRUE))
      stop("Package 'Benchmarking' is required to colour by efficiency.",
           call. = FALSE)
    eff <- as.numeric(compute_efficiency(d, rts = efficiency,
                                         orientation = orientation,
                                         dual = FALSE)$eff)
    status <- factor(ifelse(abs(eff - 1) < 1e-9, "Efficient", "Inefficient"),
                     levels = c("Efficient", "Inefficient"))
  }

  scaled <- as.data.frame(lapply(io, function(v) {
    rg <- range(v); if (diff(rg) == 0) rep(0.5, length(v)) else (v - rg[1]) / diff(rg)
  }))
  colnames(scaled) <- vars

  if (interactive) {
    if (!requireNamespace("plotly", quietly = TRUE))
      stop("Package 'plotly' is required for interactive = TRUE.", call. = FALSE)
    sc <- .deaviz_status_colours()
    cols <- if (is.null(status)) rep(.deaviz_primary(), nrow(scaled))
            else unname(sc[as.character(status)])
    p <- plotly::plot_ly(type = "scatterpolar", mode = "lines")
    for (i in seq_len(nrow(scaled))) {
      r <- as.numeric(scaled[i, ])
      p <- plotly::add_trace(p, r = c(r, r[1]), theta = c(vars, vars[1]),
                             name = lab[i],
                             legendgroup = if (is.null(status)) NULL
                                           else as.character(status[i]),
                             line = list(color = cols[i]))
    }
    return(plotly::layout(p, title = title,
                          polar = list(radialaxis = list(visible = TRUE,
                                                         range = c(0, 1)))))
  }

  long <- data.frame(
    dmu      = rep(lab, times = ncol(scaled)),
    variable = factor(rep(vars, each = nrow(scaled)), levels = vars),
    value    = unlist(scaled, use.names = FALSE),
    status   = if (is.null(status)) NA else rep(status, times = ncol(scaled)),
    stringsAsFactors = FALSE
  )

  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  spec <- .deaviz_label_spec(labels, lab, max.overlaps.value)
  long$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(long$dmu) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$variable, y = .data$value,
                                          group = .data$dmu))
  if (is.null(status)) {
    g <- g + ggplot2::geom_polygon(ggplot2::aes(alpha = .data$.fa), fill = NA,
                                   colour = .deaviz_primary(), ...) +
      ggplot2::scale_alpha_identity()
  } else {
    g <- g +
      ggplot2::geom_polygon(ggplot2::aes(colour = .data$status,
                                         alpha = .data$.fa), fill = NA, ...) +
      ggplot2::scale_alpha_identity() +
      ggplot2::scale_colour_manual(
        name = paste0("DMU (", toupper(efficiency), ")"),
        values = .deaviz_status_colours())
  }

  g <- g +
    coord_radar() +
    ggplot2::ylim(0, 1) +
    ggplot2::labs(x = NULL, y = NULL) +
    .deaviz_theme()

  if (spec$mode == "one") {
    one <- long[as.character(long$dmu) == spec$which, , drop = FALSE]
    g <- g + ggplot2::geom_polygon(
      data = one,
      ggplot2::aes(x = .data$variable, y = .data$value, group = .data$dmu),
      fill = NA, colour = .deaviz_ring(), linewidth = 1.2,
      inherit.aes = FALSE) +
      ggplot2::labs(subtitle = paste0("DMU: ", spec$which))
  }
  if (!is.null(subtitle)) g <- g + ggplot2::labs(subtitle = subtitle)

  g
}
