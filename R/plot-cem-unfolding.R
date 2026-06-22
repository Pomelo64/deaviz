#' Unfolding map of a cross-efficiency matrix
#'
#' Applies multidimensional unfolding (Ashkiani and Mar-Molinero, 2017) to a
#' cross-efficiency matrix, placing each DMU twice -- once as a "rating" unit
#' (the weights it applies) and once as a "rated" unit -- so that a rating unit
#' sits close to the units it scores highly. Dissimilarities are taken as
#' \code{1 - CEM}.
#'
#' @param x A cross-efficiency matrix from
#'   \code{\link{compute_cross_efficiency}}, or a \code{dea_data} object / data
#'   frame from which one is computed.
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
#' @param ... When \code{x} is data rather than a matrix, further arguments
#'   (e.g. \code{approach}, \code{epsilon}) passed to
#'   \code{\link{compute_cross_efficiency}}.
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
#' @references
#' Ashkiani, S., & Mar-Molinero, C. (2017). Visualization of cross-efficiency
#' matrices using multidimensional unfolding. In \emph{Recent Applications of
#' Data Envelopment Analysis}.
#' @seealso \code{\link{compute_cross_efficiency}},
#'   \code{\link[smacof]{unfolding}}
#'
#' @importFrom rlang .data
#' @examplesIf all(vapply(c("Benchmarking", "lpSolve", "smacof"), requireNamespace, logical(1), quietly = TRUE))
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' ce <- compute_cross_efficiency(df)
#' plot_cem_unfolding(ce)
#'
#' @export
plot_cem_unfolding <- function(x, labels = "none", max.overlaps.value = 10,
                               transparency = 0.7, fade = TRUE, subtitle = NULL, title = NULL,
                               interactive = FALSE, ...) {
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  .deaviz_check_alpha(transparency)
  cem <- if (is.matrix(x)) x else compute_cross_efficiency(x, ...)
  if (!is.numeric(cem) || nrow(cem) != ncol(cem))
    stop("`x` must be a square cross-efficiency matrix (e.g. from ",
         "compute_cross_efficiency()) or data from which to compute one.",
         call. = FALSE)

  if (!requireNamespace("smacof", quietly = TRUE))
    stop("Package 'smacof' is required for this plot.", call. = FALSE)

  lab <- rownames(cem)
  if (is.null(lab)) lab <- paste0("DMU", seq_len(nrow(cem)))

  unf <- smacof::unfolding(delta = round(1 - cem, 2), ndim = 2)

  df <- rbind(
    data.frame(D1 = unf$conf.row[, 1], D2 = unf$conf.row[, 2],
               DMU = lab, Type = "Rating", stringsAsFactors = FALSE),
    data.frame(D1 = unf$conf.col[, 1], D2 = unf$conf.col[, 2],
               DMU = lab, Type = "Rated", stringsAsFactors = FALSE)
  )
  df$Type <- factor(df$Type, levels = c("Rating", "Rated"))
  lim     <- range(c(df$D1, df$D2))
  repel   <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  spec <- .deaviz_label_spec(labels, lab, max.overlaps.value)
  df$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(df$DMU) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(df, .deaviz_aes(ggplot2::aes(x = .data$D1, y = .data$D2,
                                        colour = .data$Type,
                                        shape = .data$Type,
                                        text = .data$DMU), interactive)) +
    ggplot2::geom_point(ggplot2::aes(alpha = .data$.fa), size = 2.5) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_manual(values = .deaviz_okabe_ito()[1:2],
                                 name = NULL) +
    ggplot2::scale_shape_manual(values = c(16, 17), name = NULL)

  g <- .deaviz_text_labels(g, df, spec, repel, max.overlaps.value,
                           "D1", "D2", "DMU", ring = TRUE, ring_size = 3.7,
                           shape_col = "Type",
                           ring_shapes = c(Rating = 1, Rated = 2))

  g <- g +
    ggplot2::coord_fixed(xlim = lim, ylim = lim) +
    ggplot2::labs(x = "D1", y = "D2") +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
