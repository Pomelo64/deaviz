#' PCA biplot of a DEA problem
#'
#' Runs a principal component analysis on the standardised input/output data and
#' draws a biplot: DMUs as points coloured by efficiency status, and the
#' variables as labelled vectors. Efficiency comes from
#' \code{\link{compute_efficiency}}.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param rts Returns to scale, passed to \code{\link{compute_efficiency}}:
#'   \code{"crs"} or \code{"vrs"}.
#' @param vector_size Positive multiplier scaling the length of the variable
#'   vectors relative to the point cloud (default \code{1}).
#' @param text_size Size of the variable labels (default \code{3}).
#' @param labels Which DMUs to label: \code{"none"} (default), \code{"all"}
#'   (label every DMU; \pkg{ggrepel} with \code{max.overlaps = Inf}),
#'   \code{"max.overlaps"} (\pkg{ggrepel} using \code{max.overlaps.value}),
#'   or the name/id of a single DMU to highlight just that one.
#'   Use \code{"id"} to print each DMU's row number inside its own marker.
#' @param max.overlaps.value Passed to \pkg{ggrepel} when
#'   \code{labels = "max.overlaps"} (default \code{10}); larger values keep
#'   more crowded labels.
#' @param transparency Point alpha in \code{[0, 1]} (default \code{0.7}).
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param seed Optional seed for \code{\link[ggrepel]{geom_text_repel}} label
#'   placement (static mode only). Default \code{NA}.
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
#' @seealso \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y1 = c(5, 8, 6, 7, 3, 9),
#'   o_y2 = c(2, 3, 1, 2, 1, 4)
#' )
#' plot_io_pca_biplot(df, rts = "crs")
#'
#' @export
plot_io_pca_biplot <- function(x, rts = c("crs", "vrs"),
                               vector_size = 1, text_size = 3,
                               labels = "none", max.overlaps.value = 10,
                               transparency = 0.7, fade = TRUE,
                               subtitle = NULL, title = NULL,
                               interactive = FALSE, seed = NA, ...) {
  rts <- match.arg(rts)
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  if (!is.numeric(vector_size) || length(vector_size) != 1L || vector_size <= 0)
    stop("`vector_size` must be a single positive number.", call. = FALSE)
  if (!is.numeric(text_size) || length(text_size) != 1L || text_size <= 0)
    stop("`text_size` must be a single positive number.", call. = FALSE)
  if (!is.numeric(transparency) || length(transparency) != 1L ||
      transparency < 0 || transparency > 1)
    stop("`transparency` must be a single number in [0, 1].", call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)

  d        <- as_dea_data(x)
  data_mat <- cbind(d$X, d$Y)

  sds <- apply(data_mat, 2, stats::sd)
  if (any(sds == 0))
    stop("PCA cannot use constant (zero-variance) column(s): ",
         toString(colnames(data_mat)[sds == 0]), ".", call. = FALSE)

  pca <- stats::prcomp(data_mat, center = TRUE, scale. = TRUE)
  if (ncol(pca$x) < 2L)
    stop("PCA biplot needs at least two principal components ",
         "(more DMUs and/or variables).", call. = FALSE)

  scores   <- pca$x[, 1:2, drop = FALSE]
  loadings <- pca$rotation[, 1:2, drop = FALSE]
  pct      <- 100 * summary(pca)$importance[2, 1:2]

  eff <- as.numeric(compute_efficiency(d, rts = rts, dual = FALSE)$eff)

  nodes <- data.frame(
    dmu    = d$labels,
    PC1    = scores[, 1],
    PC2    = scores[, 2],
    status = ifelse(abs(eff - 1) < 1e-9, "Efficient", "Inefficient"),
    efficiency = round(eff, 3),
    stringsAsFactors = FALSE
  )
  arrow_scale <- vector_size * 0.45 * max(abs(scores)) / max(abs(loadings))
  vars <- data.frame(
    variable = rownames(loadings),
    PC1      = loadings[, 1] * arrow_scale,
    PC2      = loadings[, 2] * arrow_scale,
    stringsAsFactors = FALSE
  )
  xr <- range(c(nodes$PC1, vars$PC1, 0))
  yr <- range(c(nodes$PC2, vars$PC2, 0))
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  spec <- .deaviz_label_spec(labels, nodes$dmu, max.overlaps.value)
  nodes$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(nodes$dmu == spec$which, transparency, flev) else transparency

  g <- ggplot2::ggplot() +
    ggplot2::geom_point(
      data = nodes,
      .deaviz_aes(ggplot2::aes(x = .data$PC1, y = .data$PC2, colour = .data$status,
                   alpha = .data$.fa,
                   text = paste0(.data$dmu, "<br>Efficiency: ",
                                 .data$efficiency)), interactive),
      size = 2, ...
    ) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_manual(
      name   = paste0("DMU (", toupper(rts), ")"),
      values = .deaviz_status_colours()
    ) +
    ggplot2::geom_segment(
      data = vars,
      ggplot2::aes(x = 0, y = 0, xend = .data$PC1, yend = .data$PC2),
      colour = .deaviz_arrow(), alpha = 0.9,
      arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm"))
    )

  # variable labels (always shown): ggrepel when static & available
  if (repel) {
    g <- g + ggrepel::geom_text_repel(
      data = vars,
      ggplot2::aes(x = .data$PC1, y = .data$PC2, label = .data$variable),
      colour = .deaviz_arrow(), size = text_size, seed = seed, max.overlaps = Inf)
  } else {
    g <- g + ggplot2::geom_text(
      data = vars,
      ggplot2::aes(x = .data$PC1, y = .data$PC2, label = .data$variable),
      colour = .deaviz_arrow(), size = text_size)
  }

  # optional DMU labels
  
  g <- .deaviz_text_labels(g, nodes, spec, repel, max.overlaps.value,
                           "PC1", "PC2", "dmu", size = text_size,
                           ring = TRUE, ring_size = 3.2)

  g <- g +
    ggplot2::coord_cartesian(xlim = xr, ylim = yr) +
    ggplot2::labs(x = sprintf("PC1 (%.1f%%)", pct[1]),
                  y = sprintf("PC2 (%.1f%%)", pct[2])) +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
