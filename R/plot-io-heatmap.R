#' Heatmap of standardised inputs and outputs
#'
#' Draws a DMU-by-variable heatmap of the input and output values, with DMUs on
#' the y-axis and variables on the x-axis (inputs labelled \code{I_}, outputs
#' \code{O_}). By default the values are standardised column-wise so they are
#' comparable across variables.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param scale Logical; if \code{TRUE} (default) each variable is standardised
#'   (z-scored) before plotting.
#' @param labels DMU tick labels: \code{"all"} (default) shows them,
#'   \code{"none"} hides them, and the name/id of a single DMU highlights
#'   that DMU's label(s) in colour.
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... Additional arguments passed to \code{geom_tile}.
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
#' @seealso \code{\link{dea_data}}
#'
#' @importFrom rlang .data
#' @examples
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_heatmap(df)
#'
#' @export
plot_io_heatmap <- function(x, scale = TRUE, labels = "all",
                            max.overlaps.value = 10, transparency = 1, fade = TRUE, x_angle = NULL, subtitle = NULL, title = NULL,
                            interactive = FALSE, ...) {
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  .deaviz_check_alpha(transparency)
  .deaviz_check_flag(scale, "scale")

  d   <- as_dea_data(x)
  mat <- cbind(d$X, d$Y)
  colnames(mat) <- c(paste0("I_", colnames(d$X)),
                     paste0("O_", colnames(d$Y)))

  if (scale) {
    sds <- apply(mat, 2L, stats::sd)
    if (any(sds == 0))
      stop("Column(s) with zero variance cannot be standardised: ",
           toString(colnames(mat)[sds == 0]), ".", call. = FALSE)
    mat <- scale(mat)
  }

  y_lab <- d$labels
  if (is.null(y_lab)) y_lab <- paste0("DMU", seq_len(nrow(mat)))
  spec       <- .deaviz_label_spec(labels, y_lab, max.overlaps.value)
  show_ticks <- spec$mode != "none"

  if (interactive)
    return(.deaviz_plotly_heatmap(
      z = mat, x = colnames(mat), y = y_lab, title = title,
      colorbar_title = if (scale) "z-score" else "value", hoverfmt = ".2f",
      show_y_labels = show_ticks))

  long <- data.frame(
    dmu      = factor(rep(y_lab, times = ncol(mat)), levels = rev(y_lab)),
    variable = factor(rep(colnames(mat), each = nrow(mat)),
                      levels = colnames(mat)),
    value    = as.vector(mat),
    stringsAsFactors = FALSE
  )

  long$.ta <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(long$dmu) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$variable, y = .data$dmu,
                                          fill = .data$value)) +
    ggplot2::geom_tile(ggplot2::aes(alpha = .data$.ta), ...) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_fill_viridis_c(name = if (scale) "z-score" else "value") +
    ggplot2::labs(x = NULL, y = NULL) +
    .deaviz_theme()

  if (!show_ticks)
    g <- g + ggplot2::theme(axis.text.y = ggplot2::element_blank())
  if (spec$mode == "one") {
    yi <- match(spec$which, rev(y_lab)); nx <- ncol(mat)
    g <- g +
      ggplot2::annotate("rect", xmin = 0.5, xmax = nx + 0.5,
                        ymin = yi - 0.5, ymax = yi + 0.5, fill = NA,
                        colour = .deaviz_ring(), linewidth = 0.7)
  }
  g <- g + .deaviz_x_angle(x_angle)
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
