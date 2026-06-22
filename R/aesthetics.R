# Internal aesthetic helpers (not exported). Centralising colours and the
# ggplot2 theme here keeps every plot on one consistent, publication-ready,
# colourblind-safe scheme: the Okabe-Ito palette for categorical encodings and
# the viridis palette for sequential / continuous encodings.

# Okabe-Ito colourblind-safe qualitative palette.
.deaviz_okabe_ito <- function() {
  c("#E69F00", "#56B4E9", "#009E73", "#F0E442",
    "#0072B2", "#D55E00", "#CC79A7", "#999999")
}

# n categorical colours (Okabe-Ito, extended via hcl.colors when n > 8).
.deaviz_palette <- function(n) {
  pal <- .deaviz_okabe_ito()
  if (n <= length(pal)) return(pal[seq_len(n)])
  grDevices::hcl.colors(n, "Dark 3")
}

# Fixed efficient / inefficient colours used across the status plots.
.deaviz_status_colours <- function() {
  c(Efficient = "#E69F00", Inefficient = "#56B4E9")
}

# A single neutral accent (reference lines, network edges).
.deaviz_accent <- function() "#555555"

# Distinct colour for biplot loading vectors and their labels (dark red).
.deaviz_arrow <- function() "#222222"

# Colour for every highlight "ring" / emphasis marker: the hollow ring around a
# highlighted point, the heatmap row/column wrap, the single-DMU outlines on the
# parcoo / radar / distribution plots, etc. Kept separate from the biplot arrow
# colour so the two can be tuned independently.
.deaviz_ring <- function() "#BF3EFF"

# A polar coordinate system whose connecting lines are straight rather than
# curved, giving a proper radar/spider chart (ggplot2's coord_polar bends the
# segment between adjacent axes).
coord_radar <- function(theta = "x", start = 0, direction = 1) {
  theta <- match.arg(theta, c("x", "y"))
  r <- if (theta == "x") "y" else "x"
  ggplot2::ggproto("CoordRadar", ggplot2::CoordPolar, theta = theta, r = r,
                   start = start, direction = sign(direction),
                   is_linear = function(coord) TRUE, clip = "off")
}

# Primary single-series fill / marker colour (Okabe-Ito blue).
.deaviz_primary <- function() "#0072B2"

# Sequential viridis colours.
.deaviz_sequential <- function(n = 256L, alpha = NULL) {
  grDevices::hcl.colors(n, "viridis", alpha = alpha)
}

# A plotly colorscale (list of [fraction, colour] stops) matching the viridis
# sequential palette used by the static plots.
.deaviz_viridis_colorscale <- function(n = 32L) {
  cols <- .deaviz_sequential(n)
  frac <- seq(0, 1, length.out = n)
  Map(function(a, b) list(a, b), frac, cols)
}

# Build a native plotly heatmap with the viridis colorscale. Used by the
# heatmap plots in interactive mode: ggplotly rebuilds geom_tile as its own
# heatmap trace and ignores the ggplot fill scale, so we bypass it here to keep
# the cell colours and the colourbar consistent. `z` is a matrix whose rows map
# to `y` (drawn top-to-bottom) and columns to `x`.
.deaviz_plotly_heatmap <- function(z, x, y, title = NULL, colorbar_title = "",
                                   zmin = NULL, zmax = NULL,
                                   xtitle = NULL, ytitle = NULL,
                                   hoverfmt = ".3f",
                                   show_x_labels = TRUE, show_y_labels = TRUE) {
  if (!requireNamespace("plotly", quietly = TRUE))
    stop("Package 'plotly' is required for interactive = TRUE.", call. = FALSE)
  p <- plotly::plot_ly(
    x = x, y = y, z = z, type = "heatmap",
    colorscale = .deaviz_viridis_colorscale(), zmin = zmin, zmax = zmax,
    colorbar = list(title = colorbar_title),
    hovertemplate = paste0("%{y} / %{x}: %{z:", hoverfmt, "}<extra></extra>"))
  plotly::layout(p,
    title = title,
    xaxis = list(title = xtitle, tickangle = -90,
                 showticklabels = show_x_labels),
    yaxis = list(title = ytitle, autorange = "reversed",
                 showticklabels = show_y_labels))
}

# Validate and resolve the unified `labels` argument shared by the plotting
# functions. `known` is the vector of DMU identifiers. Returns a list with
# `mode` in c("none", "all", "max", "one") and `which` (the DMU when "one").
.deaviz_label_spec <- function(labels, known, max_overlaps = 10) {
  if (!is.character(labels) || length(labels) != 1L)
    stop('`labels` must be a single string: "none", "all", "max.overlaps", ',
         '"id", or a DMU name.', call. = FALSE)
  if (!is.numeric(max_overlaps) || length(max_overlaps) != 1L ||
      max_overlaps <= 0)
    stop("`max.overlaps.value` must be a single positive number.", call. = FALSE)
  known <- as.character(known)
  if (labels == "none")
    return(list(mode = "none", which = NA_character_, known = known))
  if (labels == "all")
    return(list(mode = "all",  which = NA_character_, known = known))
  if (labels == "max.overlaps")
    return(list(mode = "max",  which = NA_character_, known = known))
  if (labels == "id")
    return(list(mode = "id",   which = NA_character_, known = known))
  if (labels %in% known)
    return(list(mode = "one", which = labels, known = known))
  stop('`labels` must be "none", "all", "max.overlaps", "id", or a known DMU ',
       "name. Unknown DMU: ", labels, ". Available: ", toString(known), ".",
       call. = FALSE)
}

# Add DMU text labels to a single-panel point plot according to a label spec.
# `data` must contain the coordinate and label columns named by xcol/ycol/labcol.
# When `ring = TRUE` and a single DMU is highlighted, a hollow marker is drawn
# around that DMU's point(s) to make it pop. The ring shape matches the point:
# pass `shape_col` plus `ring_shapes` (a named vector mapping the shape column's
# values to hollow shape codes, e.g. c(Rating = 1, Rated = 2)); otherwise a
# hollow circle (shape 1) is used.
.deaviz_text_labels <- function(g, data, spec, repel, max_overlaps,
                                xcol, ycol, labcol, size = 3, one_size = 2.4,
                                ring = FALSE, ring_size = 3.6, ring_stroke = 1,
                                shape_col = NULL, ring_shapes = NULL,
                                id_size = 2, id_colour = "black") {
  if (spec$mode == "none") return(g)
  m <- ggplot2::aes(x = .data[[xcol]], y = .data[[ycol]],
                    label = .data[[labcol]])

  # "id" mode: write each DMU's row number centred inside its own marker
  if (spec$mode == "id") {
    d <- data
    d$.idlab <- match(as.character(d[[labcol]]), spec$known)
    return(g + ggplot2::geom_text(
      data = d,
      ggplot2::aes(x = .data[[xcol]], y = .data[[ycol]], label = .data$.idlab),
      size = id_size, colour = id_colour, fontface = "bold",
      inherit.aes = FALSE))
  }

  if (spec$mode == "one") {
    d  <- data[as.character(data[[labcol]]) == spec$which, , drop = FALSE]
    pm <- ggplot2::aes(x = .data[[xcol]], y = .data[[ycol]])
    if (ring && nrow(d) > 0) {
      if (is.null(shape_col) || is.null(ring_shapes)) {
        g <- g + ggplot2::geom_point(
          data = d, mapping = pm, shape = 1, colour = .deaviz_ring(),
          size = ring_size, stroke = ring_stroke, inherit.aes = FALSE)
      } else {
        for (lv in names(ring_shapes)) {
          dd <- d[as.character(d[[shape_col]]) == lv, , drop = FALSE]
          if (nrow(dd) > 0)
            g <- g + ggplot2::geom_point(
              data = dd, mapping = pm, shape = ring_shapes[[lv]],
              colour = .deaviz_ring(), size = ring_size, stroke = ring_stroke,
              inherit.aes = FALSE)
        }
      }
    }
    if (repel) {
      # Hand ggrepel ALL the points so it repels the label away from the whole
      # crowd, but only put text on the target DMU. min.segment.length = 0 forces
      # a leader stem (in the ring colour) from the label back to its marker.
      rd <- data
      rd$.lab <- ifelse(as.character(rd[[labcol]]) == spec$which,
                        as.character(rd[[labcol]]), "")
      return(g + ggrepel::geom_text_repel(
        data = rd,
        ggplot2::aes(x = .data[[xcol]], y = .data[[ycol]], label = .data$.lab),
        size = one_size, fontface = "bold", colour = "black", seed = 1,
        max.overlaps = Inf, min.segment.length = 0, box.padding = 1,
        point.padding = 0.5, force = 4, force_pull = 0.2,
        segment.color = .deaviz_ring(), segment.size = 0.5,
        segment.alpha = 0.9, inherit.aes = FALSE))
    }
    return(g + ggplot2::geom_text(data = d, mapping = m, size = one_size,
      fontface = "bold", vjust = -1.1, inherit.aes = FALSE))
  }
  mo <- if (spec$mode == "all") Inf else max_overlaps
  g + if (repel)
    ggrepel::geom_text_repel(data = data, mapping = m, size = size, seed = 1,
      max.overlaps = mo, inherit.aes = FALSE)
    else ggplot2::geom_text(data = data, mapping = m, size = size,
      vjust = -0.6, check_overlap = TRUE, inherit.aes = FALSE)
}

# Shared minimal ggplot2 theme.
.deaviz_theme <- function() {
  ggplot2::theme_minimal(base_size = 12) +
    ggplot2::theme(
      panel.grid.minor = ggplot2::element_blank(),
      plot.title       = ggplot2::element_text(face = "bold"),
      legend.position  = "right"
    )
}

# Final step shared by every ggplot-based plot: apply an optional title and
# return either the static ggplot (default) or its interactive plotly
# conversion. `tooltip` is forwarded to ggplotly().
.deaviz_finalize <- function(g, title = NULL, interactive = FALSE,
                             tooltip = "text", subtitle = NULL) {
  if (!is.null(title)) {
    if (!is.character(title) || length(title) != 1L)
      stop("`title` must be a single string or NULL.", call. = FALSE)
    g <- g + ggplot2::labs(title = title)
  }
  if (!is.null(subtitle)) {
    if (!is.character(subtitle) || length(subtitle) != 1L)
      stop("`subtitle` must be a single string or NULL.", call. = FALSE)
    g <- g + ggplot2::labs(subtitle = subtitle)
  }
  if (!is.logical(interactive) || length(interactive) != 1L ||
      is.na(interactive))
    stop("`interactive` must be a single TRUE or FALSE.", call. = FALSE)
  if (interactive) {
    if (!requireNamespace("plotly", quietly = TRUE))
      stop("Package 'plotly' is required for interactive = TRUE.",
           call. = FALSE)
    return(plotly::ggplotly(g, tooltip = tooltip))
  }
  g
}

# Validate a transparency / alpha argument: a single number in [0, 1].
.deaviz_check_alpha <- function(x, name = "transparency") {
  if (!is.numeric(x) || length(x) != 1L || is.na(x) || x < 0 || x > 1)
    stop("`", name, "` must be a single number between 0 and 1.", call. = FALSE)
  invisible(x)
}

# Faded alpha for non-focused marks in a single-DMU "focus" view: focused marks
# keep `transparency`; everything else drops to a low alpha so the chosen DMU
# (and, for networks, its sub-network) stands out. Returns a per-row numeric
# alpha vector given a logical `focus`.
.deaviz_fade_alpha <- function(focus, base, faded) {
  ifelse(focus, base, faded)
}

# Resolve a column selector (character names or integer positions) against a
# data frame's columns, returning the column names. Used by plots that let the
# user point at columns by position instead of by name.
.deaviz_col_names <- function(sel, data, role) {
  if (is.null(sel)) return(NULL)
  if (is.numeric(sel)) {
    if (any(sel != as.integer(sel)) || any(sel < 1L) || any(sel > ncol(data)))
      stop("`", role, "` positions must be whole numbers within the ",
           "columns of the data (1 to ", ncol(data), ").", call. = FALSE)
    return(names(data)[sel])
  }
  if (is.character(sel)) {
    miss <- setdiff(sel, names(data))
    if (length(miss))
      stop("`", role, "` column(s) not found: ", toString(miss), ".",
           call. = FALSE)
    return(sel)
  }
  stop("`", role, "` must be column names or integer positions.", call. = FALSE)
}

# Theme fragment to rotate x-axis tick labels (for long variable/DMU names).
# Returns NULL when `angle` is NULL, which adds nothing to a ggplot.
.deaviz_x_angle <- function(angle) {
  if (is.null(angle)) return(NULL)
  if (!is.numeric(angle) || length(angle) != 1L || is.na(angle))
    stop("`x_angle` must be a single number (degrees) or NULL.", call. = FALSE)
  hj <- if (angle %% 360 == 0) 0.5 else 1
  vj <- if (angle %% 180 == 0 || angle %% 90 == 0) 0.5 else 1
  ggplot2::theme(axis.text.x = ggplot2::element_text(
    angle = angle, hjust = hj, vjust = vj))
}

# Resolve the user-facing `fade` argument to the alpha used for the *non*-
# selected marks in a single-DMU focus view. `FALSE` switches focus off
# (returns NULL); `TRUE` uses a sensible default tied to `transparency`; a
# number is taken as the literal alpha of the faded marks, so larger values
# fade them less (1 = not faded at all, near 0 = almost invisible).
.deaviz_fade_level <- function(fade, transparency) {
  if (isFALSE(fade)) return(NULL)
  base <- if (is.numeric(transparency)) transparency else 0.7
  if (isTRUE(fade))  return(max(0.08, base * 0.35))
  fade
}

# `fade` may be a single logical or a single number in [0, 1].
.deaviz_check_fade <- function(fade, name = "fade") {
  ok <- (is.logical(fade) || is.numeric(fade)) &&
        length(fade) == 1L && !is.na(fade)
  if (ok && is.numeric(fade)) ok <- fade >= 0 && fade <= 1
  if (!ok)
    stop("`", name, "` must be TRUE/FALSE or a single number in [0, 1].",
         call. = FALSE)
  invisible()
}

# The `text` aesthetic is only consumed by plotly (for hover tooltips via
# ggplotly). When rendering a static ggplot it is an unknown aesthetic and
# triggers a warning, so drop it unless we are building an interactive plot.
.deaviz_aes <- function(mapping, interactive) {
  if (!isTRUE(interactive)) mapping$text <- NULL
  mapping
}

# Validate a single logical flag.
.deaviz_check_flag <- function(value, name) {
  if (!is.logical(value) || length(value) != 1L || is.na(value))
    stop("`", name, "` must be a single TRUE or FALSE.", call. = FALSE)
  invisible(TRUE)
}
