#' Pairwise scatter plots of inputs, outputs and efficiency scores
#'
#' Builds the pairwise scatter plots of a chosen set of columns: any subset of
#' the inputs and outputs, plus optionally one or more efficiency scores. For
#' \code{k} selected columns it draws all \code{choose(k, 2)} pairwise panels.
#' For example, selecting one input, one output and the CRS score gives three
#' panels.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param vars Character vector of input/output column names to include.
#'   Defaults to all inputs and outputs.
#' @param efficiency Optional character vector of efficiency models to compute
#'   and include as columns, any of \code{"crs"}, \code{"vrs"}, \code{"drs"},
#'   \code{"irs"}, \code{"fdh"}, \code{"add"}.
#' @param color Efficiency model used to colour points by efficient/inefficient
#'   status: one of \code{"crs"} (default), \code{"vrs"}, \code{"drs"},
#'   \code{"irs"}, \code{"fdh"}, \code{"add"}, or \code{"none"}.
#' @param correlation Logical; if \code{TRUE} (default) the Pearson correlation
#'   is printed in the top-left corner of each panel.
#' @param orientation Measurement orientation used when computing efficiency
#'   scores.
#' @param labels Which DMUs to label: \code{"none"} (default), \code{"all"},
#'   \code{"max.overlaps"}, or the name/id of a single DMU to highlight it.
#'   (Uses \code{geom_text} with overlap-thinning rather than \pkg{ggrepel},
#'   since repel is unsafe inside facets.)
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param transparency Point alpha in \code{[0, 1]} (default \code{0.7}).
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
#' @seealso \code{\link{dea_data}}, \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_scatter(df, vars = c("x1", "y"), efficiency = "crs")
#'
#' @export
plot_io_scatter <- function(x, vars = NULL, efficiency = NULL,
                            color = c("crs", "vrs", "drs", "irs", "fdh",
                                      "add", "none"),
                            correlation = TRUE, orientation = "in",
                            labels = "none", max.overlaps.value = 10,
                            transparency = 0.7, fade = TRUE,
                            subtitle = NULL, title = NULL,
                            interactive = FALSE, ...) {
  color <- match.arg(color)
  .deaviz_check_flag(correlation, "correlation")
  if (!is.numeric(transparency) || length(transparency) != 1L ||
      transparency < 0 || transparency > 1)
    stop("`transparency` must be a single number in [0, 1].", call. = FALSE)

  d        <- as_dea_data(x)
  io       <- as.data.frame(cbind(d$X, d$Y))
  io_names <- colnames(io)

  if (is.null(vars)) {
    vars <- io_names
  } else {
    if (!is.character(vars))
      stop("`vars` must be a character vector of input/output names.",
           call. = FALSE)
    bad <- setdiff(vars, io_names)
    if (length(bad))
      stop("Unknown variable(s): ", toString(bad),
           ". Available: ", toString(io_names), ".", call. = FALSE)
  }

  cols <- io[vars]

  if (!is.null(efficiency)) {
    keywords <- c("crs", "vrs", "drs", "irs", "fdh", "add")
    bad <- setdiff(efficiency, keywords)
    if (length(bad))
      stop("Unknown efficiency model(s): ", toString(bad),
           ". Available: ", toString(keywords), ".", call. = FALSE)
    if (!requireNamespace("Benchmarking", quietly = TRUE))
      stop("Package 'Benchmarking' is required to compute efficiency.",
           call. = FALSE)
    for (k in efficiency)
      cols[[toupper(k)]] <- as.numeric(
        compute_efficiency(d, rts = k, orientation = orientation,
                           dual = FALSE)$eff)
  }

  cn <- colnames(cols)
  if (length(cn) < 2L)
    stop("At least two columns are needed to form a scatter pair.",
         call. = FALSE)

  lab   <- d$labels
  if (is.null(lab)) lab <- paste0("DMU", seq_len(nrow(cols)))

  status <- NULL
  if (color != "none") {
    if (!requireNamespace("Benchmarking", quietly = TRUE))
      stop("Package 'Benchmarking' is required to colour by efficiency.",
           call. = FALSE)
    ce <- as.numeric(compute_efficiency(d, rts = color,
                                        orientation = orientation,
                                        dual = FALSE)$eff)
    status <- factor(ifelse(abs(ce - 1) < 1e-9, "Efficient", "Inefficient"),
                     levels = c("Efficient", "Inefficient"))
  }
  combos <- utils::combn(cn, 2L)

  pieces <- lapply(seq_len(ncol(combos)), function(k) {
    a <- combos[1L, k]; b <- combos[2L, k]
    data.frame(pair = paste(a, "vs", b),
               xv = cols[[a]], yv = cols[[b]], lab = lab,
               status = if (is.null(status)) NA else status,
               stringsAsFactors = FALSE)
  })
  long <- do.call(rbind, pieces)
  long$pair <- factor(long$pair, levels = unique(long$pair))
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  spec <- .deaviz_label_spec(labels, lab, max.overlaps.value)
  long$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(as.character(long$lab) == spec$which, transparency, flev) else
    transparency

  g <- ggplot2::ggplot(long, ggplot2::aes(x = .data$xv, y = .data$yv)) +
    ggplot2::facet_wrap(ggplot2::vars(.data$pair), scales = "free") +
    ggplot2::labs(x = NULL, y = NULL) +
    .deaviz_theme()
  if (color != "none") {
    g <- g + ggplot2::geom_point(
      ggplot2::aes(colour = .data$status, alpha = .data$.fa), ...) +
      ggplot2::scale_colour_manual(
        name = paste0("DMU (", toupper(color), ")"),
        values = .deaviz_status_colours())
  } else {
    g <- g + ggplot2::geom_point(ggplot2::aes(alpha = .data$.fa),
                                 colour = .deaviz_primary(), ...)
  }

  g <- g + ggplot2::scale_alpha_identity()

  # ggrepel emits a NULL grob inside facets under newer ggplot2 (trips grid's
  # depth()), so labelling here always uses geom_text (repel = FALSE).
  g <- .deaviz_text_labels(g, long, spec, FALSE, max.overlaps.value,
                           "xv", "yv", "lab", size = 2.7, ring = TRUE,
                           ring_size = 2.8)

  if (correlation) {
    ann <- lapply(seq_len(ncol(combos)), function(k) {
      a <- combos[1L, k]; b <- combos[2L, k]
      r <- suppressWarnings(stats::cor(cols[[a]], cols[[b]],
                                       method = "pearson"))
      data.frame(pair = paste(a, "vs", b),
                 xv = min(cols[[a]], na.rm = TRUE),
                 yv = max(cols[[b]], na.rm = TRUE),
                 lab = sprintf("r = %.2f", r),
                 stringsAsFactors = FALSE)
    })
    ann <- do.call(rbind, ann)
    ann$pair <- factor(ann$pair, levels = levels(long$pair))
    g <- g + ggplot2::geom_text(
      data = ann,
      ggplot2::aes(x = .data$xv, y = .data$yv, label = .data$lab),
      hjust = 0, vjust = 1, size = 3.2, colour = .deaviz_accent(),
      inherit.aes = FALSE)
  }

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
