#' Panel PCA biplot with DMU trajectories
#'
#' For panel (long-format) DEA data, computes a single principal-component
#' embedding of the pooled, standardised inputs and outputs (so the axes and
#' loading vectors are fixed), then draws each DMU's path through time as a
#' connected trajectory. Points are coloured by a DEA efficiency score and the
#' arrow on each trajectory points from the earliest to the latest period.
#'
#' @param panel_data A long-format data frame with one row per DMU-period,
#'   containing an identifier column and a period column (see \code{id} and
#'   \code{period}); the remaining columns are inputs/outputs.
#' @param inputs,outputs Optional input/output column selectors, given either as
#'   character names or as integer column positions (e.g. \code{inputs = 3:5}).
#'   If \code{NULL} (default), columns are recognised by the \code{i_} and
#'   \code{o_} prefixes, as in \code{\link{dea_data}}.
#' @param id,period The identifier and period columns, given as a name or an
#'   integer position (default \code{"Label"} and \code{"Period"}).
#' @param color Efficiency model for point colour, computed per period:
#'   \code{"crs"} (default) or \code{"vrs"}.
#' @param orientation Measurement orientation for the efficiency scores.
#' @param vector_size Positive multiplier scaling the loading vectors.
#' @param transparency Point opacity. Either a single number in \code{[0, 1]}
#'   (constant alpha, default \code{0.7}) or the string \code{"efficiency"}, in
#'   which case point alpha is mapped to the efficiency score (more efficient
#'   DMUs drawn more opaque).
#' @param labels Which DMU trajectories to label at their latest period. One of
#'   \code{"none"} (default, no labels), \code{"all"} (label every DMU, with
#'   \pkg{ggrepel} \code{max.overlaps = Inf}), \code{"max.overlaps"} (label with
#'   \pkg{ggrepel} using \code{max.overlaps.value}), or the name/id of a single
#'   DMU to highlight just that one.
#'   Use \code{"id"} to print each DMU's row number inside its own marker.
#' @param max.overlaps.value Passed to \pkg{ggrepel} when
#'   \code{labels = "max.overlaps"} (default \code{10}); larger values keep more
#'   crowded labels.
#' @param period_labels Logical; if \code{TRUE} each point is labelled with its
#'   period. Default \code{FALSE}.
#' @param size_by_efficiency Logical; if \code{TRUE} point size grows with the
#'   efficiency score. Default \code{FALSE}.
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
#' @seealso \code{\link{plot_io_pca_biplot}}, \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' # Real multi-period example: 22 Taiwanese banks over 2009-2011.
#' # Columns can be given by position (inputs are columns 3-5, outputs 6-8) ...
#' plot_panel_io_biplot(
#'   taiwanese_banks, id = "DMU", period = "Year",
#'   inputs = 3:5, outputs = 6:8, labels = "Cathay"
#' )
#'
#' # ... or by name, with the loading vectors and a single bank's trajectory.
#' plot_panel_io_biplot(
#'   taiwanese_banks, id = "DMU", period = "Year",
#'   inputs  = c("labour", "physical_capital", "purchased_funds"),
#'   outputs = c("demand_deposits", "short_term_loans", "long_term_loans"),
#'   transparency = "efficiency", labels = "all"
#' )
#'
#' # A toy long-format frame using the i_/o_ prefix convention also works.
#' panel <- data.frame(
#'   Label  = rep(paste0("D", 1:4), each = 3),
#'   Period = rep(2019:2021, times = 4),
#'   i_x1   = c(4,5,5, 7,6,6, 8,8,7, 4,3,4),
#'   i_x2   = c(3,3,2, 3,4,3, 1,2,2, 2,2,1),
#'   o_y    = c(5,6,7, 8,8,9, 6,6,7, 7,8,8)
#' )
#' plot_panel_io_biplot(panel, labels = "D2")   # highlight a single DMU
#'
#' @export
plot_panel_io_biplot <- function(panel_data, inputs = NULL, outputs = NULL,
                                 id = "Label", period = "Period",
                                 color = c("crs", "vrs"), orientation = "in",
                                 vector_size = 1, transparency = 0.7, fade = TRUE,
                                 labels = "none", max.overlaps.value = 10,
                                 period_labels = FALSE,
                                 size_by_efficiency = FALSE,
                                 subtitle = NULL, title = NULL, interactive = FALSE, ...) {
  color <- match.arg(color)
  .deaviz_check_flag(period_labels, "period_labels")
  .deaviz_check_flag(size_by_efficiency, "size_by_efficiency")
  .deaviz_check_fade(fade)
  flev <- .deaviz_fade_level(fade, transparency)

  # transparency: constant alpha, or alpha mapped to efficiency
  if (is.character(transparency) && length(transparency) == 1L &&
      transparency == "efficiency") {
    alpha_by_eff <- TRUE
  } else if (is.numeric(transparency) && length(transparency) == 1L &&
             transparency >= 0 && transparency <= 1) {
    alpha_by_eff <- FALSE
  } else {
    stop("`transparency` must be a single number in [0, 1] or \"efficiency\".",
         call. = FALSE)
  }

  if (!is.character(labels) || length(labels) != 1L)
    stop("`labels` must be a single string: \"none\", \"all\", ",
         "\"max.overlaps\", or a DMU name.", call. = FALSE)
  if (!is.numeric(max.overlaps.value) || length(max.overlaps.value) != 1L ||
      max.overlaps.value <= 0)
    stop("`max.overlaps.value` must be a single positive number.",
         call. = FALSE)

  if (!is.data.frame(panel_data))
    stop("`panel_data` must be a data frame in long format.", call. = FALSE)
  if (!is.numeric(vector_size) || length(vector_size) != 1L || vector_size <= 0)
    stop("`vector_size` must be a single positive number.", call. = FALSE)

  # resolve id / period / inputs / outputs by name OR by integer position
  id      <- .deaviz_col_names(id, panel_data, "id")
  period  <- .deaviz_col_names(period, panel_data, "period")
  inputs  <- .deaviz_col_names(inputs, panel_data, "inputs")
  outputs <- .deaviz_col_names(outputs, panel_data, "outputs")
  if (length(id) != 1L || length(period) != 1L)
    stop("`id` and `period` must each refer to a single column.", call. = FALSE)

  # biplot variables: the chosen inputs/outputs if given, otherwise every
  # non-id/period column (so `as_dea_data`'s i_/o_ prefix detection applies)
  if (!is.null(inputs) || !is.null(outputs)) {
    var_cols <- c(inputs, outputs)
  } else {
    var_cols <- setdiff(names(panel_data), c(id, period))
  }
  if (length(var_cols) < 2L)
    stop("Need at least two input/output columns for a biplot.", call. = FALSE)
  var_data <- as.matrix(panel_data[, var_cols, drop = FALSE])
  if (!is.numeric(var_data))
    stop("Input/output columns must all be numeric.", call. = FALSE)

  sds <- apply(var_data, 2L, stats::sd)
  if (any(sds == 0))
    stop("Column(s) with zero variance cannot be scaled for PCA: ",
         toString(var_cols[sds == 0]), ".", call. = FALSE)

  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)

  pca    <- stats::prcomp(var_data, center = TRUE, scale. = TRUE)
  scores <- pca$x[, 1:2, drop = FALSE]
  load   <- pca$rotation[, 1:2, drop = FALSE]
  ve     <- pca$sdev^2 / sum(pca$sdev^2)

  eff     <- numeric(nrow(panel_data))
  periods <- unique(panel_data[[period]])
  for (p in periods) {
    idx <- which(panel_data[[period]] == p)
    dd  <- as_dea_data(as.data.frame(panel_data[idx, var_cols, drop = FALSE]),
                       inputs = inputs, outputs = outputs)
    eff[idx] <- as.numeric(
      compute_efficiency(dd, rts = color, orientation = orientation,
                         dual = FALSE)$eff)
  }
  eff_label <- paste0(toupper(color), " efficiency")

  df <- data.frame(
    Label  = as.character(panel_data[[id]]),
    Period = panel_data[[period]],
    PC1    = scores[, 1],
    PC2    = scores[, 2],
    eff    = round(eff, 3),
    stringsAsFactors = FALSE
  )
  df <- df[order(df$Label, df$Period), ]

  # validate a single-DMU highlight against the known identifiers
  known <- unique(df$Label)
  if (!labels %in% c("none", "all", "max.overlaps", "id") &&
      !labels %in% known)
    stop("`labels` must be \"none\", \"all\", \"max.overlaps\", or a known ",
         "DMU name. Unknown DMU: ", labels, ". Available: ",
         toString(known), ".", call. = FALSE)

  # path data with the final segment pulled back so the arrowhead leaves a gap
  # before the latest-period point (drawn at its true position by geom_point)
  span     <- max(diff(range(df$PC1)), diff(range(df$PC2)))
  pull_abs <- 0.05 * span
  df_path <- do.call(rbind, lapply(split(df, df$Label), function(sub) {
    m <- nrow(sub)
    if (m >= 2) {
      dx <- sub$PC1[m] - sub$PC1[m - 1]; dy <- sub$PC2[m] - sub$PC2[m - 1]
      len <- sqrt(dx^2 + dy^2)
      if (len > 0) {
        pull <- min(pull_abs, 0.4 * len)
        sub$PC1[m] <- sub$PC1[m] - dx / len * pull
        sub$PC2[m] <- sub$PC2[m] - dy / len * pull
      }
    }
    sub
  }))

  arrow_scale <- vector_size * 0.8 * max(abs(scores)) / max(abs(load))
  vars <- data.frame(
    variable = rownames(load),
    PC1      = load[, 1] * arrow_scale,
    PC2      = load[, 2] * arrow_scale,
    stringsAsFactors = FALSE
  )
  vars$lx <- vars$PC1 * 1.16   # label sits beyond the arrowhead
  vars$ly <- vars$PC2 * 1.16
  ends <- df[!duplicated(df$Label, fromLast = TRUE), ]   # latest period per DMU
  pc_lab <- sprintf("PC%d (%.1f%%)", 1:2, 100 * ve[1:2])
  repel  <- !interactive && requireNamespace("ggrepel", quietly = TRUE)

  # build the point layer's aesthetic mapping and constant arguments
  foc <- !is.null(flev) && labels %in% known           # single-DMU focus view
  if (foc) {
    foc_base    <- if (is.numeric(transparency)) transparency else 0.85
    df$.fa      <- .deaviz_fade_alpha(df$Label == labels, foc_base, flev)
    df_path$.fa <- .deaviz_fade_alpha(df_path$Label == labels, 0.55, flev)
  }
  map <- ggplot2::aes(
    colour = .data$eff,
    text   = paste0(.data$Label, " (", .data$Period, ")<br>",
                    eff_label, ": ", .data$eff))
  reclass <- function(a) { class(a) <- "uneval"; a }
  if (foc) map <- reclass(utils::modifyList(map,
                                     ggplot2::aes(alpha = .data$.fa)))
  else if (alpha_by_eff) map <- reclass(utils::modifyList(map,
                                     ggplot2::aes(alpha = .data$eff)))
  if (size_by_efficiency) map <- reclass(utils::modifyList(map,
                                     ggplot2::aes(size = .data$eff)))
  pt_args <- list(mapping = .deaviz_aes(map, interactive))
  if (!alpha_by_eff && !foc) pt_args$alpha <- transparency
  if (!size_by_efficiency)   pt_args$size  <- 2.6

  path_args <- list(
    data  = df_path,
    arrow = ggplot2::arrow(length = ggplot2::unit(0.18, "cm"), type = "closed"),
    colour = .deaviz_accent())
  if (foc) path_args$mapping <- ggplot2::aes(group = .data$Label,
                                             alpha = .data$.fa)
  else { path_args$mapping <- ggplot2::aes(group = .data$Label)
         path_args$alpha   <- 0.5 }

  g <- ggplot2::ggplot(df, ggplot2::aes(x = .data$PC1, y = .data$PC2)) +
    do.call(ggplot2::geom_path, path_args) +
    ggplot2::geom_segment(
      data = vars,
      ggplot2::aes(x = 0, y = 0, xend = .data$PC1, yend = .data$PC2),
      colour = .deaviz_arrow(), alpha = 0.9,
      arrow = ggplot2::arrow(length = ggplot2::unit(0.15, "cm"))) +
    do.call(ggplot2::geom_point, c(pt_args, list(...))) +
    ggplot2::scale_colour_gradientn(colours = .deaviz_sequential(),
                                    name = eff_label)

  # loading-vector labels: repel them apart when ggrepel is available (static)
  vlab <- ggplot2::aes(x = .data$lx, y = .data$ly, label = .data$variable)
  if (repel)
    g <- g + ggrepel::geom_text_repel(
      data = vars, vlab, colour = .deaviz_arrow(), size = 3, seed = 42,
      max.overlaps = Inf, min.segment.length = 0,
      segment.colour = .deaviz_arrow(), segment.alpha = 0.5,
      box.padding = 0.5, point.padding = 0)
  else
    g <- g + ggplot2::geom_text(data = vars, vlab,
                                colour = .deaviz_arrow(), size = 3)

  if (foc)
    g <- g + ggplot2::scale_alpha_identity()
  else if (alpha_by_eff)
    g <- g + ggplot2::scale_alpha_continuous(range = c(0.3, 1), name = eff_label)
  if (size_by_efficiency)
    g <- g + ggplot2::scale_size_continuous(range = c(1.5, 5), name = eff_label)

  if (period_labels)
    g <- g + ggplot2::geom_text(ggplot2::aes(label = .data$Period),
                                size = 2.5, vjust = -0.7, show.legend = FALSE)

  if (labels == "id") {
    ids <- match(ends$Label, known)
    g <- g + ggplot2::geom_text(
      data = ends,
      ggplot2::aes(x = .data$PC1, y = .data$PC2, label = ids),
      size = 2, colour = "black", fontface = "bold", inherit.aes = FALSE)
  } else if (labels == "all" || labels == "max.overlaps") {
    mo <- if (labels == "all") Inf else max.overlaps.value
    if (repel)
      g <- g + ggrepel::geom_text_repel(
        data = ends, ggplot2::aes(label = .data$Label),
        size = 3, seed = 1, max.overlaps = mo)
    else
      g <- g + ggplot2::geom_text(
        data = ends, ggplot2::aes(label = .data$Label),
        size = 3, vjust = -0.6, check_overlap = TRUE)
  } else if (labels != "none") {
    one <- ends[ends$Label == labels, , drop = FALSE]
    psz <- if (size_by_efficiency) {
      rng <- range(df$eff)
      sz  <- if (diff(rng) == 0) 3
             else 1.5 + (one$eff[1] - rng[1]) / diff(rng) * 3.5
      sz + 1.2
    } else 3.8
    g <- g + ggplot2::geom_point(
      data = one, ggplot2::aes(x = .data$PC1, y = .data$PC2),
      shape = 1, colour = .deaviz_ring(), size = psz, stroke = 1,
      inherit.aes = FALSE)
    if (repel) {
      rd <- ends
      rd$.lab <- ifelse(rd$Label == labels, as.character(rd$Label), "")
      g <- g + ggrepel::geom_text_repel(
        data = rd,
        ggplot2::aes(x = .data$PC1, y = .data$PC2, label = .data$.lab),
        size = 2.4, fontface = "bold", colour = "black", seed = 1,
        max.overlaps = Inf, min.segment.length = 0, box.padding = 1,
        point.padding = 0.5, force = 4, force_pull = 0.2,
        segment.color = .deaviz_ring(), segment.size = 0.5,
        segment.alpha = 0.9, inherit.aes = FALSE)
    } else
      g <- g + ggplot2::geom_text(
        data = one, ggplot2::aes(label = .data$Label),
        size = 2.4, fontface = "bold", vjust = -1.1)
  }

  g <- g + ggplot2::labs(x = pc_lab[1], y = pc_lab[2]) + .deaviz_theme()
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}
