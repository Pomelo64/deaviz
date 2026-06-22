#' Heatmap of secondary-goal multiplier weights
#'
#' Draws a heatmap of each DMU's secondary-goal (benevolent or aggressive)
#' multiplier weights, one row per DMU and one column per input/output. By
#' default the weights are row-standardised (input weights sum to one, output
#' weights sum to one within each DMU) so the relative emphasis is comparable
#' across units.
#'
#' @param x A weights list from \code{\link{compute_cross_efficiency_weights}},
#'   or a \code{dea_data} object / data frame from which the weights are
#'   computed.
#' @param approach Secondary goal used when the weights are computed from data:
#'   \code{"benevolent"} (default) or \code{"aggressive"}. Ignored when \code{x}
#'   is an already-computed weights list.
#' @param standardize Logical; if \code{TRUE} (default) the weights are
#'   row-standardised with \code{\link{standardize_weights}} before plotting.
#' @param labels DMU tick labels: \code{"all"} (default) shows them,
#'   \code{"none"} hides them, and the name/id of a single DMU highlights
#'   that DMU's label(s) in colour.
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... When \code{x} is data, further arguments passed to
#'   \code{\link{compute_cross_efficiency_weights}}.
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
#' @seealso \code{\link{compute_cross_efficiency_weights}},
#'   \code{\link{standardize_weights}}
#'
#' @references
#' Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
#' Derivations, meanings and uses. \emph{Journal of the Operational Research
#' Society}, 45(5), 567--578. \doi{10.1057/jors.1994.84}
#'
#' @importFrom rlang .data
#' @examplesIf all(vapply(c("Benchmarking", "lpSolve"), requireNamespace, logical(1), quietly = TRUE))
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_cem_weights_heatmap(df, approach = "benevolent")
#'
#' @export
plot_cem_weights_heatmap <- function(x, approach = c("benevolent", "aggressive"),
                                     standardize = TRUE, labels = "all",
                                     max.overlaps.value = 10,
                                     transparency = 1, fade = TRUE, x_angle = NULL, subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  .deaviz_check_alpha(transparency)
  approach <- match.arg(approach)
  .deaviz_check_flag(standardize, "standardize")

  is_weights <- is.list(x) && !is.data.frame(x) &&
    all(c("input_weights", "output_weights") %in% names(x))
  w <- if (is_weights) x
       else compute_cross_efficiency_weights(x, approach = approach, ...)

  if (standardize) w <- standardize_weights(w)

  in_w  <- as.matrix(w$input_weights)
  out_w <- as.matrix(w$output_weights)
  colnames(in_w)  <- paste0("I_", colnames(in_w))
  colnames(out_w) <- paste0("O_", colnames(out_w))

  z <- cbind(in_w, out_w)            # DMUs (rows) x variables (columns)
  y_lab <- rownames(z)
  if (is.null(y_lab)) y_lab <- paste0("DMU", seq_len(nrow(z)))
  spec       <- .deaviz_label_spec(labels, y_lab, max.overlaps.value)
  show_ticks <- spec$mode != "none"

  if (interactive)
    return(.deaviz_plotly_heatmap(
      z = z, x = colnames(z), y = y_lab, title = title,
      colorbar_title = "weight", show_y_labels = show_ticks))

  long <- data.frame(
    dmu      = factor(rep(y_lab, times = ncol(z)), levels = rev(y_lab)),
    variable = factor(rep(colnames(z), each = nrow(z)), levels = colnames(z)),
    value    = as.vector(z),
    stringsAsFactors = FALSE
  )

  long$.ta <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(long$dmu) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$variable, y = .data$dmu,
                                          fill = .data$value)) +
    ggplot2::geom_tile(ggplot2::aes(alpha = .data$.ta)) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_fill_viridis_c(name = "weight") +
    ggplot2::labs(x = NULL, y = NULL) +
    .deaviz_theme()

  if (!show_ticks)
    g <- g + ggplot2::theme(axis.text.y = ggplot2::element_blank())
  if (spec$mode == "one") {
    yi <- match(spec$which, rev(y_lab)); nx <- ncol(z)
    g <- g +
      ggplot2::annotate("rect", xmin = 0.5, xmax = nx + 0.5,
                        ymin = yi - 0.5, ymax = yi + 0.5, fill = NA,
                        colour = .deaviz_ring(), linewidth = 0.7)
  }
  g <- g + .deaviz_x_angle(x_angle)
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
