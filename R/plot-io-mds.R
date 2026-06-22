#' MDS co-plot of a DEA problem
#'
#' Places the DMUs in two dimensions by multidimensional scaling (Adler and
#' Raveh, 2008) and colours them by a chosen quantity: a DEA efficiency score,
#' or one of the input/output variables (or their output-to-input ratios).
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param transform What to compute distances on: \code{"none"} (the original
#'   inputs and outputs) or \code{"ratio"} (all output/input ratios).
#' @param dist_method Distance measure, passed to \code{\link[stats]{dist}}.
#' @param mds_type Scaling level, passed to \code{\link[smacof]{smacofSym}}.
#' @param encode What to colour by: an efficiency model
#'   (\code{"crs"}, \code{"vrs"}, \code{"drs"}, \code{"irs"}, \code{"fdh"},
#'   \code{"add"}) or the name of one of the distance-space columns.
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
#' @param title Optional plot title. If \code{NULL} (default) one is generated.
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
#' Adler, N., & Raveh, A. (2008). Presenting DEA graphically. \emph{Omega},
#' 36(5), 715--729.
#'
#' de Leeuw, J., & Mair, P. (2009). Multidimensional scaling using majorization:
#' SMACOF in R. \emph{Journal of Statistical Software}, 31(3), 1--30.
#' \doi{10.18637/jss.v031.i03}
#' @seealso \code{\link{compute_efficiency}}, \code{\link[smacof]{smacofSym}}
#'
#' @importFrom rlang .data
#' @examplesIf all(vapply(c("Benchmarking", "smacof"), requireNamespace, logical(1), quietly = TRUE))
#' df <- data.frame(
#'   dmu  = paste0("D", 1:8),
#'   i_x1 = c(4, 7, 8, 4, 2, 5, 6, 3),
#'   i_x2 = c(3, 3, 1, 2, 4, 2, 5, 1),
#'   o_y  = c(5, 8, 6, 7, 3, 9, 4, 6)
#' )
#' plot_io_mds(df, encode = "crs")
#'
#' @export
plot_io_mds <- function(x, transform = c("none", "ratio"),
                        dist_method = c("euclidean", "manhattan", "maximum",
                                        "canberra", "minkowski"),
                        mds_type = c("ratio", "interval", "ordinal", "mspline"),
                        encode = "crs", point_size = 2,
                        transparency = 0.7, fade = TRUE, labels = "none",
                        max.overlaps.value = 10,
                        subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)
  transform   <- match.arg(transform)
  dist_method <- match.arg(dist_method)
  mds_type    <- match.arg(mds_type)
  if (!is.numeric(point_size) || length(point_size) != 1L || point_size <= 0)
    stop("`point_size` must be a single positive number.", call. = FALSE)
  if (!is.numeric(transparency) || length(transparency) != 1L ||
      transparency < 0 || transparency > 1)
    stop("`transparency` must be a single number in [0, 1].",
         call. = FALSE)

  if (!requireNamespace("smacof", quietly = TRUE))
    stop("Package 'smacof' is required for this plot.", call. = FALSE)

  d <- as_dea_data(x)
  mds_data <- if (transform == "ratio") .io_ratios(d$X, d$Y)
              else as.data.frame(cbind(d$X, d$Y))

  rts_keywords <- c("crs", "vrs", "drs", "irs", "fdh", "add")
  if (length(encode) != 1L || !is.character(encode))
    stop("`encode` must be a single string.", call. = FALSE)
  if (encode %in% rts_keywords) {
    if (!requireNamespace("Benchmarking", quietly = TRUE))
      stop("Package 'Benchmarking' is required to compute efficiency.",
           call. = FALSE)
    value <- as.numeric(compute_efficiency(d, rts = encode, dual = FALSE)$eff)
    encode_label <- paste0(toupper(encode), " efficiency")
  } else if (encode %in% colnames(mds_data)) {
    value <- mds_data[[encode]]
    encode_label <- encode
  } else {
    stop("`encode` must be an efficiency (", toString(rts_keywords),
         ") or a distance-space column (", toString(colnames(mds_data)), ").",
         call. = FALSE)
  }

  mds_dist  <- stats::dist(mds_data, method = dist_method)
  mds_model <- smacof::smacofSym(delta = mds_dist, ndim = 2, type = mds_type)
  coords    <- mds_model$conf

  df <- data.frame(
    dmu   = d$labels,
    D1    = coords[, 1],
    D2    = coords[, 2],
    value = value,
    stringsAsFactors = FALSE
  )
  lim <- range(c(df$D1, df$D2))
  if (is.null(title))
    title <- paste0("MDS co-plot coloured by ", encode_label)
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  spec <- .deaviz_label_spec(labels, df$dmu, max.overlaps.value)
  df$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(df$dmu == spec$which, transparency, flev) else transparency

  g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$D1, y = .data$D2)) +
    ggplot2::geom_point(
      .deaviz_aes(ggplot2::aes(colour = .data$value, alpha = .data$.fa,
                   text = paste0(.data$dmu, "<br>", encode_label, ": ",
                                 round(.data$value, 3))), interactive),
      size = point_size, ...
    ) +
    ggplot2::scale_alpha_identity() +
    ggplot2::scale_colour_gradientn(colours = .deaviz_sequential(),
                                    name = encode_label)

  g <- .deaviz_text_labels(g, df, spec, repel, max.overlaps.value,
                           "D1", "D2", "dmu", ring = TRUE,
                           ring_size = point_size + 1.2)

  g <- g +
    ggplot2::coord_fixed(xlim = lim, ylim = lim) +
    ggplot2::labs(x = "D1", y = "D2") +
    .deaviz_theme()

  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}

#' Output-to-input ratios of a DEA problem
#'
#' @param X,Y Numeric input/output matrices (one row per DMU).
#' @return A data frame of all output/input ratios, columns named
#'   \code{"output/input"}.
#' @keywords internal
#' @noRd
.io_ratios <- function(X, Y) {
  cols  <- vector("list", ncol(Y) * ncol(X))
  names <- character(ncol(Y) * ncol(X))
  k <- 0L
  for (o in seq_len(ncol(Y))) {
    for (i in seq_len(ncol(X))) {
      k <- k + 1L
      cols[[k]] <- Y[, o] / X[, i]
      names[k]  <- paste0(colnames(Y)[o], "/", colnames(X)[i])
    }
  }
  df <- as.data.frame(cols)
  colnames(df) <- names
  df
}
