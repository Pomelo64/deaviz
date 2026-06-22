#' Costa bi-dimensional efficient frontier
#'
#' Draws the Costa et al. (2016) two-dimensional representation of a DEA
#' problem. Each DMU's multiplier weights are standardised and used to collapse
#' its inputs and outputs into a single weighted input \code{I} and weighted
#' output \code{O}; efficient units fall on the \code{O = I} diagonal (the
#' frontier) and inefficient units below it. Uses the constant-returns-to-scale
#' model; weights come from \code{\link{compute_efficiency}}.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param orientation Measurement orientation, \code{"in"} or \code{"out"}.
#' @param point_size Point size (default \code{2}).
#' @param transparency Point alpha in \code{[0, 1]} (default \code{0.7}).
#' @param labels Which DMUs to label: \code{"none"} (default), \code{"all"}
#'   (label every DMU; \pkg{ggrepel} with \code{max.overlaps = Inf}),
#'   \code{"max.overlaps"} (\pkg{ggrepel} using \code{max.overlaps.value}),
#'   or the name/id of a single DMU to highlight just that one.
#'   Use \code{"id"} to print each DMU's row number inside its own marker.
#' @param max.overlaps.value Passed to \pkg{ggrepel} when
#'   \code{labels = "max.overlaps"} (default \code{10}); larger values keep
#'   more crowded labels.
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
#' @references
#' Bana e Costa, C. A., Soares de Mello, J. C. C. B., & Angulo Meza, L. (2016).
#' A new approach to the bi-dimensional representation of the DEA efficient
#' frontier with multiple inputs and outputs. \emph{European Journal of
#' Operational Research}, 255(1), 175--186. \doi{10.1016/j.ejor.2016.05.012}
#' @seealso \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_costa_frontier(df, orientation = "in")
#'
#' @export
plot_io_costa_frontier <- function(x, orientation = c("in", "out"),
                                   point_size = 2, transparency = 0.7,
                                   fade = TRUE,
                                   labels = "none", max.overlaps.value = 10,
                                   subtitle = NULL, title = NULL,
                                   interactive = FALSE, ...) {
  orientation <- match.arg(orientation)
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  if (!is.numeric(point_size) || length(point_size) != 1L || point_size <= 0)
    stop("`point_size` must be a single positive number.", call. = FALSE)
  if (!is.numeric(transparency) || length(transparency) != 1L ||
      transparency < 0 || transparency > 1)
    stop("`transparency` must be a single number in [0, 1].",
         call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)

  d <- as_dea_data(x)
  X <- d$X
  Y <- d$Y

  model <- compute_efficiency(d, rts = "crs", orientation = orientation,
                              dual = TRUE)
  eff <- as.numeric(model$eff)
  ux  <- model$ux
  vy  <- model$vy

  S <- if (orientation == "in") rowSums(ux) else rowSums(vy)
  weighted_input  <- rowSums((ux / S) * X)
  weighted_output <- rowSums((vy / S) * Y)

  df <- data.frame(
    dmu        = d$labels,
    I          = weighted_input,
    O          = weighted_output,
    status     = ifelse(abs(eff - 1) < 1e-9, "Efficient", "Inefficient"),
    efficiency = round(eff, 3),
    stringsAsFactors = FALSE
  )
  lim   <- range(c(df$I, df$O, 0))
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  spec <- .deaviz_label_spec(labels, df$dmu, max.overlaps.value)
  df$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(df$dmu == spec$which, transparency, flev) else transparency

  g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$I, y = .data$O)) +
    ggplot2::geom_abline(intercept = 0, slope = 1, colour = .deaviz_accent(),
                         linetype = "dashed") +
    ggplot2::geom_point(
      .deaviz_aes(ggplot2::aes(colour = .data$status, alpha = .data$.fa,
                   text = paste0(.data$dmu, "<br>Efficiency: ",
                                 .data$efficiency)), interactive),
      size = point_size, ...
    ) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_manual(name = "DMU",
                                 values = .deaviz_status_colours())

  g <- .deaviz_text_labels(g, df, spec, repel, max.overlaps.value,
                           "I", "O", "dmu", ring = TRUE,
                           ring_size = point_size + 1.2)

  g <- g +
    ggplot2::coord_fixed(xlim = lim, ylim = lim) +
    ggplot2::labs(x = "Standardised input (I)",
                  y = "Standardised output (O)") +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
