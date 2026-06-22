#' Heatmap of a cross-efficiency matrix
#'
#' Draws the cross-efficiency matrix (CEM) as a heatmap: each cell is the
#' efficiency of the rated DMU (x-axis) evaluated with the weights of the rating
#' DMU (y-axis). The diagonal holds the simple (self) efficiencies.
#'
#' @param x A cross-efficiency matrix from
#'   \code{\link{compute_cross_efficiency}}, or a \code{dea_data} object / data
#'   frame from which one is computed.
#' @param labels DMU tick labels: \code{"all"} (default) shows them,
#'   \code{"none"} hides them, and the name/id of a single DMU highlights
#'   that DMU's label(s) in colour.
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... When \code{x} is data rather than a matrix, further arguments
#'   (e.g. \code{approach}, \code{epsilon}) passed to
#'   \code{\link{compute_cross_efficiency}}.
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{1}).
#' @param subtitle Optional subtitle shown beneath the title.
#' @param fade Controls the single-DMU focus view. When one DMU is given to
#'   \code{labels}, all other marks (and, for the network plots, everything
#'   outside that DMU's sub-network; for the panel biplot, the other
#'   trajectories) are faded so the chosen DMU stands out. \code{TRUE} (default)
#'   uses a sensible fade level; \code{FALSE} disables it; a single number in
#'   \code{[0, 1]} sets the alpha of the faded marks directly, where larger
#'   values fade them less (e.g. \code{0.4} leaves them more visible).
#' @param x_angle Angle in degrees for the x-axis tick labels, useful when
#'   the input/output (or DMU) names on the x-axis are long and overlap.
#'   \code{NULL} (default) keeps the plot's standard orientation; for
#'   example \code{x_angle = 45} tilts the labels to make them readable.
#' @return A \pkg{ggplot2} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @references
#' Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
#' Derivations, meanings and uses. \emph{Journal of the Operational Research
#' Society}, 45(5), 567--578. \doi{10.1057/jors.1994.84}
#' @seealso \code{\link{compute_cross_efficiency}}, \code{\link{plot_cem_unfolding}}
#'
#' @importFrom rlang .data
#' @examplesIf all(vapply(c("Benchmarking", "lpSolve"), requireNamespace, logical(1), quietly = TRUE))
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_cem_heatmap(compute_cross_efficiency(df))
#'
#' @export
plot_cem_heatmap <- function(x, labels = "all", max.overlaps.value = 10,
                             transparency = 1, fade = TRUE, x_angle = NULL, subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  .deaviz_check_alpha(transparency)
  if (is.matrix(x)) {
    cem <- x
  } else {
    if (!requireNamespace("Benchmarking", quietly = TRUE) ||
        !requireNamespace("lpSolve", quietly = TRUE))
      stop("Packages 'Benchmarking' and 'lpSolve' are required to compute the ",
           "cross-efficiency matrix.", call. = FALSE)
    cem <- compute_cross_efficiency(x, ...)
  }
  if (!is.numeric(cem) || nrow(cem) != ncol(cem))
    stop("`x` must be a square cross-efficiency matrix (e.g. from ",
         "compute_cross_efficiency()) or data from which to compute one.",
         call. = FALSE)

  lab <- rownames(cem)
  if (is.null(lab)) lab <- paste0("DMU", seq_len(nrow(cem)))
  spec       <- .deaviz_label_spec(labels, lab, max.overlaps.value)
  show_ticks <- spec$mode != "none"

  if (interactive)
    return(.deaviz_plotly_heatmap(
      z = cem, x = lab, y = lab, title = title, colorbar_title = "CEM",
      zmin = 0, zmax = 1, xtitle = "Rated DMU", ytitle = "Rating DMU",
      show_x_labels = show_ticks, show_y_labels = show_ticks))

  long <- data.frame(
    rated  = factor(rep(lab, each = nrow(cem)), levels = lab),
    rating = factor(rep(lab, times = ncol(cem)), levels = rev(lab)),
    value  = as.vector(cem),
    stringsAsFactors = FALSE
  )

  long$.ta <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(long$rated) == spec$which |
                       as.character(long$rating) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$rated, y = .data$rating,
                                          fill = .data$value)) +
    ggplot2::geom_tile(ggplot2::aes(alpha = .data$.ta)) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_fill_viridis_c(name = "CEM", limits = c(0, 1)) +
    ggplot2::labs(x = "Rated DMU", y = "Rating DMU") +
    .deaviz_theme() +
    ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90,
                                                       vjust = 0.5, hjust = 1))

  if (!show_ticks)
    g <- g + ggplot2::theme(axis.text = ggplot2::element_blank())
  if (spec$mode == "one") {
    n  <- length(lab)
    xi <- match(spec$which, lab)        # column (rated DMU)
    yi <- match(spec$which, rev(lab))   # row (rating DMU)
    g <- g +
      ggplot2::annotate("rect", xmin = xi - 0.5, xmax = xi + 0.5,
                        ymin = 0.5, ymax = n + 0.5, fill = NA,
                        colour = .deaviz_ring(), linewidth = 0.7) +
      ggplot2::annotate("rect", xmin = 0.5, xmax = n + 0.5,
                        ymin = yi - 0.5, ymax = yi + 0.5, fill = NA,
                        colour = .deaviz_ring(), linewidth = 0.7)
  }
  g <- g + .deaviz_x_angle(x_angle)
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
