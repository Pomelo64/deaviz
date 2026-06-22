#' Efficiency scores of the DMUs
#'
#' Summarises the DEA efficiency scores of the decision-making units as a
#' histogram (default), a boxplot, or a per-DMU bar chart. More than one
#' returns-to-scale model can be requested at once: histograms are then stacked
#' vertically (one panel per model) and boxplots are drawn side by side, each
#' model in its own colour.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param rts Returns-to-scale model(s) passed to
#'   \code{\link{compute_efficiency}}; a character vector with any of
#'   \code{"crs"} (default), \code{"vrs"}, \code{"drs"}, \code{"irs"},
#'   \code{"fdh"}, \code{"add"}. Supplying more than one compares models.
#' @param orientation Measurement orientation passed to
#'   \code{\link{compute_efficiency}}.
#' @param type \code{"histogram"} (default), \code{"box"}, or \code{"bar"}
#'   (one bar per DMU).
#' @param bins Number of histogram bins (used when \code{type = "histogram"}).
#' @param labels Which DMUs to mark: \code{"none"} (default), \code{"all"}
#'   (rug on histograms, jittered points on boxplots), or the name/id of a
#'   single DMU to mark with a dashed line (histogram), a point (boxplot),
#'   or a highlighted axis label (bar).
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... Additional arguments passed to the underlying geom.
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
#' @param subtitle Optional subtitle shown beneath the title.
#' @return A \pkg{ggplot2} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @seealso \code{\link{compute_efficiency}}, \code{\link{plot_io_efficients}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_efficiency_distributions(df, rts = "crs")
#' plot_efficiency_distributions(df, rts = c("crs", "vrs"), type = "box")
#'
#' @export
plot_efficiency_distributions <- function(x, rts = "crs", orientation = "in",
                                          type = c("histogram", "box", "bar"),
                                          bins = 30, labels = "none",
                                          max.overlaps.value = 10,
                                          transparency = 0.7, subtitle = NULL, title = NULL, interactive = FALSE,
                                          ...) {
  .deaviz_check_alpha(transparency)
  keywords <- c("crs", "vrs", "drs", "irs", "fdh", "add")
  if (!is.character(rts) || !length(rts))
    stop("`rts` must be a non-empty character vector.", call. = FALSE)
  bad <- setdiff(rts, keywords)
  if (length(bad))
    stop("Unknown rts model(s): ", toString(bad), ". Available: ",
         toString(keywords), ".", call. = FALSE)
  type <- match.arg(type)
  if (!is.numeric(bins) || length(bins) != 1L || bins < 1)
    stop("`bins` must be a single positive integer.", call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)

  d   <- as_dea_data(x)
  lab <- d$labels
  if (is.null(lab)) lab <- paste0("DMU", seq_len(nrow(d$X)))
  n   <- length(lab)

  effs <- lapply(rts, function(k)
    as.numeric(compute_efficiency(d, rts = k, orientation = orientation,
                                  dual = FALSE)$eff))
  df <- data.frame(
    dmu        = rep(lab, times = length(rts)),
    model      = factor(rep(toupper(rts), each = n), levels = toupper(rts)),
    efficiency = unlist(effs, use.names = FALSE),
    stringsAsFactors = FALSE
  )
  multi <- length(rts) > 1L
  # Qualitative palette distinct from plot_io_distributions (which uses Okabe-Ito)
  pal <- grDevices::hcl.colors(max(length(rts), 2L), "Dark 2")

  if (type == "histogram") {
    if (multi) {
      g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$efficiency,
                                            fill = .data$model)) +
        ggplot2::geom_histogram(bins = bins, alpha = transparency, ...) +
        ggplot2::scale_fill_manual(values = pal, name = "Model") +
        ggplot2::facet_wrap(ggplot2::vars(.data$model), ncol = 1,
                            strip.position = "right") +
        ggplot2::labs(x = "Efficiency", y = "Count") +
        .deaviz_theme() + ggplot2::theme(legend.position = "none")
    } else {
      g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$efficiency)) +
        ggplot2::geom_histogram(bins = bins, fill = pal[1], alpha = transparency, ...) +
        ggplot2::labs(x = paste0(toupper(rts), " efficiency"), y = "Count") +
        .deaviz_theme()
    }
  } else if (type == "box") {
    if (multi) {
      g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$model, y = .data$efficiency,
                                            fill = .data$model)) +
        ggplot2::geom_boxplot(alpha = transparency, ...) +
        ggplot2::scale_fill_manual(values = pal, name = "Model") +
        ggplot2::labs(x = NULL, y = "Efficiency") +
        .deaviz_theme() + ggplot2::theme(legend.position = "none")
    } else {
      g <- ggplot2::ggplot(df, ggplot2::aes(y = .data$efficiency)) +
        ggplot2::geom_boxplot(fill = pal[1], alpha = transparency, ...) +
        ggplot2::labs(x = NULL, y = paste0(toupper(rts), " efficiency")) +
        .deaviz_theme() +
        ggplot2::theme(axis.text.x = ggplot2::element_blank())
    }
  } else {                                   # bar: one bar per DMU
    if (multi) {
      ord <- names(sort(tapply(df$efficiency, df$dmu, mean)))
      df$dmu <- factor(df$dmu, levels = ord)
      g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$efficiency, y = .data$dmu,
                                            fill = .data$model)) +
        ggplot2::geom_col(position = "dodge", alpha = transparency, ...) +
        ggplot2::scale_fill_manual(values = pal, name = "Model") +
        ggplot2::labs(x = "Efficiency", y = NULL) + .deaviz_theme()
    } else {
      df$dmu <- factor(df$dmu, levels = df$dmu[order(df$efficiency)])
      g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$efficiency,
                                            y = .data$dmu)) +
        ggplot2::geom_col(fill = pal[1], alpha = transparency, ...) +
        ggplot2::labs(x = paste0(toupper(rts), " efficiency"), y = NULL) +
        .deaviz_theme()
    }
  }

  spec <- .deaviz_label_spec(labels, unique(df$dmu), max.overlaps.value)
  if (spec$mode == "one") {
    marks <- df[as.character(df$dmu) == spec$which, , drop = FALSE]
    if (type == "histogram") {
      g <- g + ggplot2::geom_vline(
        data = marks, ggplot2::aes(xintercept = .data$efficiency),
        linetype = "dashed", colour = .deaviz_ring(), linewidth = 0.6)
    } else if (type == "box") {
      if (multi)
        g <- g + ggplot2::geom_point(
          data = marks, ggplot2::aes(x = .data$model, y = .data$efficiency),
          colour = .deaviz_ring(), size = 2.8)
      else
        g <- g + ggplot2::geom_point(
          data = marks, ggplot2::aes(x = 0, y = .data$efficiency),
          colour = .deaviz_ring(), size = 2.8)
    } else {                                   # bar: recolour matched axis label
      cols <- ifelse(levels(df$dmu) == spec$which, .deaviz_ring(), "grey30")
      g <- g + ggplot2::theme(
        axis.text.y = ggplot2::element_text(colour = cols))
    }
    g <- g + ggplot2::labs(subtitle = paste0("DMU: ", spec$which))
  } else if (spec$mode %in% c("all", "max")) {
    if (type == "histogram")
      g <- g + ggplot2::geom_rug(
        data = df, ggplot2::aes(x = .data$efficiency),
        alpha = 0.3, colour = .deaviz_accent())
    else if (type == "box") {
      if (multi)
        g <- g + ggplot2::geom_jitter(
          data = df, ggplot2::aes(x = .data$model, y = .data$efficiency),
          width = 0.12, height = 0, alpha = 0.3, size = 0.7,
          colour = .deaviz_accent())
      else
        g <- g + ggplot2::geom_jitter(
          data = df, ggplot2::aes(x = 0, y = .data$efficiency),
          width = 0.12, height = 0, alpha = 0.3, size = 0.7,
          colour = .deaviz_accent())
    }
  }

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
