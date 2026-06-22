#' Parallel coordinates plot of a DEA problem
#'
#' Draws a parallel-coordinates plot with one axis per input and output, each
#' axis min-max scaled to \code{[0, 1]} so they are comparable. Each DMU is one
#' line; lines are coloured by efficient/inefficient status.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param efficiency Efficiency model used to colour the lines by
#'   efficient/inefficient status: \code{"crs"} (default), \code{"vrs"} or
#'   \code{"none"}.
#' @param orientation Measurement orientation for the efficiency scores,
#'   passed to \code{\link{compute_efficiency}} (default \code{"in"}).
#' @param labels Which DMUs to label at the right-hand axis: \code{"none"}
#'   (default), \code{"all"}, \code{"max.overlaps"}, or the name/id of a
#'   single DMU (also highlights that DMU's line).
#' @param max.overlaps.value Passed to \pkg{ggrepel} when
#'   \code{labels = "max.overlaps"} (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... Additional arguments passed to \code{geom_line}.
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
#' @param x_angle Angle in degrees for the x-axis tick labels, useful when
#'   the input/output (or DMU) names on the x-axis are long and overlap.
#'   \code{NULL} (default) keeps the plot's standard orientation; for
#'   example \code{x_angle = 45} tilts the labels to make them readable.
#' @return A \pkg{ggplot2} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @seealso \code{\link{compute_efficiency}}, \code{\link{plot_io_radar}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_parcoo(df, efficiency = "crs")
#'
#' @export
plot_io_parcoo <- function(x, efficiency = c("crs", "vrs", "none"),
                           orientation = "in", labels = "none",
                           max.overlaps.value = 10, transparency = 0.7, fade = TRUE, x_angle = NULL, subtitle = NULL, title = NULL,
                           interactive = FALSE, ...) {
  .deaviz_check_alpha(transparency)
  efficiency <- match.arg(efficiency)

  d    <- as_dea_data(x)
  cols <- as.data.frame(cbind(d$X, d$Y))
  lab  <- d$labels
  if (is.null(lab)) lab <- paste0("DMU", seq_len(nrow(cols)))

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

  # min-max scale each axis to [0, 1]; constant columns map to 0.5
  scaled <- as.data.frame(lapply(cols, function(v) {
    rg <- range(v)
    if (diff(rg) == 0) rep(0.5, length(v)) else (v - rg[1]) / diff(rg)
  }))
  colnames(scaled) <- colnames(cols)

  long <- data.frame(
    dmu      = rep(lab, times = ncol(scaled)),
    variable = factor(rep(colnames(scaled), each = nrow(scaled)),
                      levels = colnames(scaled)),
    value    = unlist(scaled, use.names = FALSE),
    status   = if (is.null(status)) NA else rep(status, times = ncol(scaled)),
    stringsAsFactors = FALSE
  )

  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  spec <- .deaviz_label_spec(labels, unique(long$dmu), max.overlaps.value)
  long$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(long$dmu) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$variable, y = .data$value,
                                          group = .data$dmu))
  if (is.null(status)) {
    g <- g + ggplot2::geom_line(
      .deaviz_aes(ggplot2::aes(text = .data$dmu, alpha = .data$.fa),
                  interactive),
      colour = .deaviz_primary(), ...) +
      ggplot2::scale_alpha_identity()
  } else {
    g <- g +
      ggplot2::geom_line(
        .deaviz_aes(ggplot2::aes(colour = .data$status, text = .data$dmu,
                                 alpha = .data$.fa), interactive), ...) +
      ggplot2::scale_alpha_identity() +
      ggplot2::scale_colour_manual(
        name = paste0("DMU (", toupper(efficiency), ")"),
        values = .deaviz_status_colours())
  }

  # DMU labels at the right-hand axis, per the label spec
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)
  if (spec$mode != "none") {
    last_var <- levels(long$variable)[nlevels(long$variable)]
    ends <- long[long$variable == last_var, , drop = FALSE]
    if (spec$mode == "id")
      ends$dmu <- match(as.character(ends$dmu), spec$known)
    if (spec$mode == "one") {
      ends <- ends[as.character(ends$dmu) == spec$which, , drop = FALSE]
      one  <- long[as.character(long$dmu) == spec$which, , drop = FALSE]
      g <- g + ggplot2::geom_line(data = one,
        ggplot2::aes(x = .data$variable, y = .data$value, group = .data$dmu),
        colour = .deaviz_ring(), linewidth = 1, inherit.aes = FALSE)
    }
    mo  <- if (spec$mode == "max") max.overlaps.value else Inf
    one_mode <- spec$mode == "one"
    if (repel)
      g <- g + ggrepel::geom_text_repel(
        data = ends, ggplot2::aes(label = .data$dmu),
        size = if (one_mode) 2.6 else 3,
        fontface = if (one_mode) "bold" else "plain",
        direction = "y", hjust = 0, nudge_x = 0.25, segment.size = 0.2,
        max.overlaps = mo, seed = 1, show.legend = FALSE)
    else
      g <- g + ggplot2::geom_text(
        data = ends, ggplot2::aes(label = .data$dmu),
        size = if (one_mode) 2.6 else 3,
        fontface = if (one_mode) "bold" else "plain",
        hjust = 0, nudge_x = 0.05, show.legend = FALSE)
  }

  g <- g +
    ggplot2::scale_x_discrete(
      expand = ggplot2::expansion(mult = c(0.04, 0.22))) +
    ggplot2::labs(x = NULL, y = "Min-max scaled value") +
    .deaviz_theme()

  g <- g + .deaviz_x_angle(x_angle)
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
