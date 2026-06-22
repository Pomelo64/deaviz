#' Distributions of inputs and outputs
#'
#' Shows the distribution of every input and output, either as faceted
#' histograms (default) or as boxplots. By default the variables are
#' standardised so they share a common scale.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param type \code{"histogram"} (default) or \code{"box"}.
#' @param bins Number of histogram bins (used when \code{type = "histogram"}).
#' @param scale Logical; if \code{TRUE} (default) variables are standardised
#'   (z-scored) before plotting.
#' @param labels Which DMUs to mark: \code{"none"} (default), \code{"all"}
#'   (a rug of every DMU on histograms, jittered points on boxplots), or the
#'   name/id of a single DMU to mark it with a dashed vertical line
#'   (histogram) or a point (boxplot).
#' @param max.overlaps.value Accepted for API consistency with the other
#'   plots; unused here (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; if \code{FALSE} (default) returns a static
#'   \pkg{ggplot2} object, if \code{TRUE} an interactive \pkg{plotly} object.
#' @param ... Additional arguments passed to the underlying geom
#'   (\code{geom_histogram} or \code{geom_boxplot}).
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
#' @param subtitle Optional subtitle shown beneath the title.
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
#' plot_io_distributions(df)
#' plot_io_distributions(df, type = "box")
#'
#' @export
plot_io_distributions <- function(x, type = c("histogram", "box"),
                                  bins = 30, scale = TRUE, labels = "none",
                                  max.overlaps.value = 10,
                                  transparency = 0.7, x_angle = NULL, subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_alpha(transparency)
  type <- match.arg(type)
  if (!is.numeric(bins) || length(bins) != 1L || bins < 1)
    stop("`bins` must be a single positive integer.", call. = FALSE)
  .deaviz_check_flag(scale, "scale")

  d    <- as_dea_data(x)
  vars <- as.data.frame(cbind(d$X, d$Y))

  if (scale) {
    sds <- apply(vars, 2L, stats::sd)
    if (any(sds == 0))
      stop("Column(s) with zero variance cannot be standardised: ",
           toString(colnames(vars)[sds == 0]), ".", call. = FALSE)
    vars <- as.data.frame(scale(vars))
  }

  long <- utils::stack(vars)
  names(long) <- c("value", "variable")
  long$variable <- factor(long$variable, levels = colnames(vars))
  pal   <- .deaviz_palette(ncol(vars))
  y_lab <- if (scale) "Standardised value" else "Value"

  if (type == "histogram") {
    g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$value,
                                            fill = .data$variable)) +
      ggplot2::geom_histogram(bins = bins, alpha = transparency, ...) +
      ggplot2::scale_fill_manual(values = pal) +
      ggplot2::facet_grid(rows = ggplot2::vars(.data$variable)) +
      ggplot2::labs(x = y_lab, y = "Count") +
      .deaviz_theme() +
      ggplot2::theme(legend.position = "none")
  } else {
    g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$variable,
                                            y = .data$value,
                                            fill = .data$variable)) +
      ggplot2::geom_boxplot(alpha = transparency, ...) +
      ggplot2::scale_fill_manual(values = pal) +
      ggplot2::labs(x = NULL, y = y_lab) +
      .deaviz_theme() +
      ggplot2::theme(legend.position = "none")
  }

  spec <- .deaviz_label_spec(labels, d$labels, max.overlaps.value)
  if (spec$mode == "one") {
    idx   <- match(spec$which, d$labels)
    marks <- data.frame(
      variable = factor(colnames(vars), levels = colnames(vars)),
      value    = as.numeric(vars[idx, ]),
      stringsAsFactors = FALSE)
    if (type == "histogram")
      g <- g + ggplot2::geom_vline(
        data = marks, ggplot2::aes(xintercept = .data$value),
        linetype = "dashed", colour = .deaviz_ring(), linewidth = 0.6)
    else
      g <- g + ggplot2::geom_point(
        data = marks, ggplot2::aes(x = .data$variable, y = .data$value),
        colour = .deaviz_ring(), size = 2.8)
    g <- g + ggplot2::labs(subtitle = paste0("DMU: ", spec$which))
  } else if (spec$mode %in% c("all", "max")) {
    if (type == "histogram")
      g <- g + ggplot2::geom_rug(
        data = long, ggplot2::aes(x = .data$value),
        alpha = 0.3, colour = .deaviz_accent())
    else
      g <- g + ggplot2::geom_jitter(
        data = long, ggplot2::aes(x = .data$variable, y = .data$value),
        width = 0.15, height = 0, alpha = 0.3, size = 0.7,
        colour = .deaviz_accent())
  }

  g <- g + .deaviz_x_angle(x_angle)
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
