#' Parallel coordinates plot of a DEA panel over time
#'
#' Draws a parallel-coordinates view of panel (multi-period) DEA data: the
#' periods form the parallel axes, and each DMU is one line tracing the chosen
#' quantity across time. The quantity on the vertical axis is either a single
#' input/output variable (raw values) or the per-period DEA efficiency score.
#'
#' When \code{y} is \code{"crs"} or \code{"vrs"}, efficiency is computed
#' separately for each period's cross-section (each period is its own DEA
#' problem), matching \code{\link{plot_panel_io_biplot}}. When \code{y} names an
#' input or output column, its raw values are plotted, so the axes share the
#' variable's natural scale.
#'
#' @param panel_data A data frame in long format: one row per DMU-period.
#' @param y What to trace over time: \code{"crs"} or \code{"vrs"} for the
#'   per-period efficiency score, or the name or integer position of a single
#'   input/output column in \code{panel_data}. (If a data column is literally
#'   named \code{"crs"} or \code{"vrs"}, pass its position instead.)
#' @param inputs,outputs Optional column selectors (names or integer positions)
#'   identifying the inputs and outputs, used when \code{y} is an efficiency
#'   model and column names are not \code{i_}/\code{o_} prefixed.
#' @param id,period Columns (name or position) identifying the DMU and the
#'   period. Defaults \code{"Label"} and \code{"Period"}.
#' @param orientation Measurement orientation for the efficiency scores,
#'   passed to \code{\link{compute_efficiency}} (default \code{"in"}).
#' @param color_by_trend Colour each DMU's line by its overall change over the
#'   panel (last observed value minus first). \code{FALSE} (default) uses a
#'   single colour; \code{TRUE} maps the change onto the package's sequential
#'   (viridis) palette; \code{"diverging"} uses a scale anchored at zero built
#'   from the package's status colours (orange for increases, grey for no
#'   change, sky blue for decreases).

#' @param labels Which DMUs to label at the right-hand axis: \code{"none"}
#'   (default), \code{"all"}, \code{"id"}, \code{"max.overlaps"}, or the name of
#'   a single DMU (also highlights that DMU's line).
#' @param max.overlaps.value Passed to \pkg{ggrepel} when
#'   \code{labels = "max.overlaps"} (default \code{10}).
#' @param transparency Opacity of the lines, a single number in \code{[0, 1]}
#'   (default \code{0.7}).
#' @param fade Controls the single-DMU focus view. When one DMU is given to
#'   \code{labels}, the other lines are faded so the chosen DMU stands out.
#'   \code{TRUE} (default) uses a sensible fade level; \code{FALSE} disables
#'   it; a single number in \code{[0, 1]} sets the alpha of the faded lines
#'   directly, where larger values fade them less.
#' @param x_angle Angle in degrees for the x-axis tick labels, useful when the
#'   period labels are long. \code{NULL} (default) keeps them horizontal.
#' @param subtitle Optional subtitle shown beneath the title. \code{NULL}
#'   (default) shows a note naming what is traced; pass a string to override,
#'   or \code{NA} to suppress.
#' @param title Optional plot title.
#' @param interactive Logical; static \pkg{ggplot2} (default) or interactive
#'   \pkg{plotly}.
#' @param ... Additional arguments passed to \code{geom_line}.
#'
#' @return A \pkg{ggplot2} object, or a \pkg{plotly} object when
#'   \code{interactive = TRUE}.
#'
#' @seealso \code{\link{plot_panel_io_biplot}}, \code{\link{plot_io_parcoo}},
#'   \code{\link{compute_efficiency}}
#'
#' @importFrom rlang .data
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE)
#' # per-period VRS efficiency of every bank over 2009-2011
#' plot_panel_io_parcoo(
#'   taiwanese_banks, y = "vrs", id = "DMU", period = "Year",
#'   inputs = 3:5, outputs = 6:8
#' )
#' # colour lines by each bank's overall change in efficiency
#' plot_panel_io_parcoo(
#'   taiwanese_banks, y = "vrs", id = "DMU", period = "Year",
#'   inputs = 3:5, outputs = 6:8, color_by_trend = TRUE
#' )
#' # the same, on a diverging scale anchored at zero
#' plot_panel_io_parcoo(
#'   taiwanese_banks, y = "vrs", id = "DMU", period = "Year",
#'   inputs = 3:5, outputs = 6:8, color_by_trend = "diverging"
#' )
#' # one raw variable over time, focusing a single bank
#' plot_panel_io_parcoo(
#'   taiwanese_banks, y = "demand_deposits", id = "DMU", period = "Year",
#'   labels = "Cathay"
#' )
#'
#' @export
plot_panel_io_parcoo <- function(panel_data, y, inputs = NULL, outputs = NULL,
                                 id = "Label", period = "Period",
                                 orientation = "in", color_by_trend = FALSE,
                                 labels = "none", max.overlaps.value = 10,
                                 transparency = 0.7, fade = TRUE,
                                 x_angle = NULL, subtitle = NULL, title = NULL,
                                 interactive = FALSE, ...) {
  .deaviz_check_alpha(transparency)
  .deaviz_check_fade(fade)
  if (!(isTRUE(color_by_trend) || isFALSE(color_by_trend) ||
        (is.character(color_by_trend) && length(color_by_trend) == 1L &&
         color_by_trend == "diverging")))
    stop("`color_by_trend` must be TRUE, FALSE, or \"diverging\".",
         call. = FALSE)
  flev <- .deaviz_fade_level(fade, transparency)
  
  if (!is.data.frame(panel_data))
    stop("`panel_data` must be a data frame in long format.", call. = FALSE)
  if (missing(y))
    stop("`y` must be given: \"crs\", \"vrs\", or an input/output column ",
         "name or position.", call. = FALSE)
  
  # resolve id / period by name or position
  id     <- .deaviz_col_names(id, panel_data, "id")
  period <- .deaviz_col_names(period, panel_data, "period")
  if (length(id) != 1L || length(period) != 1L)
    stop("`id` and `period` must each refer to a single column.", call. = FALSE)
  
  lab <- as.character(panel_data[[id]])
  per <- panel_data[[period]]
  if (anyNA(lab) || anyNA(per))
    stop("`id` and `period` columns must not contain missing values.",
         call. = FALSE)
  if (anyDuplicated(paste(lab, per, sep = "\r")))
    stop("Each DMU must appear at most once per period.", call. = FALSE)
  
  # what to trace: per-period efficiency, or one raw variable
  y_is_eff <- is.character(y) && length(y) == 1L && y %in% c("crs", "vrs")
  if (y_is_eff) {
    if (!requireNamespace("Benchmarking", quietly = TRUE))
      stop("Package 'Benchmarking' is required to compute efficiency.",
           call. = FALSE)
    inputs  <- .deaviz_col_names(inputs, panel_data, "inputs")
    outputs <- .deaviz_col_names(outputs, panel_data, "outputs")
    var_cols <- if (!is.null(inputs) || !is.null(outputs)) c(inputs, outputs)
    else setdiff(names(panel_data), c(id, period))
    val <- numeric(nrow(panel_data))
    for (p in unique(per)) {
      idx <- which(per == p)
      dd  <- as_dea_data(as.data.frame(panel_data[idx, var_cols, drop = FALSE]),
                         inputs = inputs, outputs = outputs)
      val[idx] <- as.numeric(
        compute_efficiency(dd, rts = y, orientation = orientation,
                           dual = FALSE)$eff)
    }
    y_lab       <- paste0(toupper(y), " efficiency")
    sub_default <- paste0("Per-period ", toupper(y),
                          " efficiency (each period solved separately)")
  } else {
    ycol <- .deaviz_col_names(y, panel_data, "y")
    if (length(ycol) != 1L)
      stop("`y` must select a single column.", call. = FALSE)
    if (ycol %in% c(id, period))
      stop("`y` cannot be the `id` or `period` column.", call. = FALSE)
    val <- panel_data[[ycol]]
    if (!is.numeric(val))
      stop("`y` column '", ycol, "' must be numeric.", call. = FALSE)
    y_lab       <- ycol
    sub_default <- paste0(ycol, " over ", period)
  }
  
  subtitle <- if (is.null(subtitle)) sub_default
  else if (length(subtitle) == 1L && is.na(subtitle)) NULL
  else subtitle
  
  long <- data.frame(
    dmu    = lab,
    period = factor(per, levels = sort(unique(per))),
    value  = val,
    stringsAsFactors = FALSE
  )
  long <- long[order(long$dmu, long$period), ]
  
  if (!isFALSE(color_by_trend)) {
    chg <- vapply(split(long$value, long$dmu),
                  function(v) v[length(v)] - v[1L], numeric(1))
    long$change <- unname(chg[long$dmu])
  }
  
  spec <- .deaviz_label_spec(labels, unique(long$dmu), max.overlaps.value)
  long$.fa <- if (spec$mode == "one" && !is.null(flev))
    .deaviz_fade_alpha(long$dmu == spec$which, transparency, flev) else
      transparency
  
  g <- ggplot2::ggplot(long,
                       ggplot2::aes(x = .data$period, y = .data$value, group = .data$dmu))
  if (!isFALSE(color_by_trend)) {
    g <- g + ggplot2::geom_line(
      .deaviz_aes(ggplot2::aes(colour = .data$change, alpha = .data$.fa,
                               text = paste0(.data$dmu, "<br>", .data$period, ": ",
                                             round(.data$value, 3), "<br>Change: ",
                                             round(.data$change, 3))), interactive),
      ...) +
      (if (identical(color_by_trend, "diverging"))
        ggplot2::scale_colour_gradient2(
          low = .deaviz_diverging()[["low"]],
          mid = .deaviz_diverging()[["mid"]],
          high = .deaviz_diverging()[["high"]], midpoint = 0,
          name = "Change\n(last - first)")
       else
         ggplot2::scale_colour_gradientn(
           colours = .deaviz_sequential(),
           name = "Change\n(last - first)"))
  } else {
    g <- g + ggplot2::geom_line(
      .deaviz_aes(ggplot2::aes(alpha = .data$.fa,
                               text = paste0(.data$dmu, "<br>", .data$period, ": ",
                                             round(.data$value, 3))), interactive),
      colour = .deaviz_primary(), ...)
  }
  g <- g + ggplot2::scale_alpha_identity()
  
  # DMU labels at the right-hand (latest) axis, per the label spec
  repel <- !interactive && requireNamespace("ggrepel", quietly = TRUE)
  if (spec$mode != "none") {
    last_per <- levels(long$period)[nlevels(long$period)]
    ends <- long[long$period == last_per, , drop = FALSE]
    if (spec$mode == "id")
      ends$dmu <- match(ends$dmu, spec$known)
    if (spec$mode == "one") {
      ends <- ends[ends$dmu == spec$which, , drop = FALSE]
      one  <- long[long$dmu == spec$which, , drop = FALSE]
      g <- g + ggplot2::geom_line(data = one,
                                  ggplot2::aes(x = .data$period, y = .data$value, group = .data$dmu),
                                  colour = .deaviz_ring(), linewidth = 1, inherit.aes = FALSE)
    }
    mo <- if (spec$mode == "max") max.overlaps.value else Inf
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
    ggplot2::labs(x = NULL, y = y_lab) +
    .deaviz_theme()
  
  g <- g + .deaviz_x_angle(x_angle)
  .deaviz_finalize(g, title, interactive, subtitle = subtitle)
}