#' Three-dimensional DEA frontier surface for two inputs and one output
#'
#' Draws the production surface for a chosen pair of inputs and a single
#' output: the decision-making units in three-dimensional space, and the
#' efficient frontier as a semi-transparent piecewise-linear surface. This is
#' the three-dimensional counterpart of \code{\link{plot_io_frontier}}, and it
#' follows the same principle: the frontier, the colour scale and the peer
#' arrows are all derived from a self-consistent DEA sub-model fitted to the
#' three chosen variables.
#'
#' Under \code{rts = "vrs"} the frontier is the upper envelope of the convex
#' hull of the observed points: a set of triangular facets meeting at the
#' efficient units. Under \code{rts = "crs"} it is the cone spanned by the most
#' productive units, so that scaling any point of the surface by a positive
#' factor gives another point of the surface. The surface is not a single
#' plane except in degenerate cases.
#'
#' Two features of the VRS surface are often mistaken for artefacts. It
#' descends to the output level of the smallest efficient units, so the
#' low-input region of the surface can fall steeply, in the same way that a
#' two-dimensional VRS frontier drops to a small corner unit. Its footprint is
#' also bounded by the convex hull of the observed input combinations rather
#' than by a rectangle, so the low-input corner may appear cut: no combination
#' of units attains the minimum of both inputs at once, and the technology is
#' not defined there.
#'
#' The plot is interactive by construction and requires \pkg{plotly}; a static
#' projection of a surface would hide facets and mislead. Computing the hull
#' requires \pkg{geometry}.
#'
#' @param x A \code{dea_data} object, or data coercible by
#'   \code{\link{as_dea_data}}.
#' @param inputs The two inputs to plot, given as column names or as integer
#'   positions among the inputs.
#' @param output The single output to plot, given as a column name or as an
#'   integer position among the outputs.
#' @param rts Returns to scale for the frontier and the efficiency scores:
#'   \code{"crs"} (default) or \code{"vrs"}.
#' @param orientation \code{"in"} (default) or \code{"out"}; affects the
#'   efficiency scores and the direction of the projection arrows.
#' @param peers_network Logical; if \code{TRUE}, draw arrows from inefficient
#'   units to their efficient reference set. Default \code{FALSE}. With a
#'   single DMU named in \code{labels}, only that unit's arrows are drawn.
#' @param arrow_target \code{"peer"} (default) draws an arrow to each efficient
#'   peer DMU, with opacity proportional to its envelopment weight
#'   (\eqn{\lambda}); \code{"projection"} draws one arrow per inefficient unit
#'   to its projected point on the surface, at uniform opacity.
#' @param surface_opacity Opacity of the frontier surface, a number in
#'   \code{[0, 1]}. Default \code{0.4}.
#' @param point_size Marker size. Default \code{4}.
#' @param transparency Base marker opacity, a number in \code{[0, 1]}.
#'   Default \code{0.8}.
#' @param label_frontier Logical; label the efficient (frontier) units.
#'   Default \code{TRUE}.
#' @param labels Labelling mode: \code{"none"} (default), \code{"all"},
#'   \code{"id"}, or the name of a single DMU to highlight.
#' @param subtitle Plot subtitle. \code{NULL} (default) names the sub-model;
#'   pass a string to override, or \code{NA} to suppress.
#' @param title Plot title.
#' @param ... Currently ignored.
#'
#' @return A \pkg{plotly} object.
#'
#' @seealso \code{\link{plot_io_frontier}}, \code{\link{plot_io_3dscatter}},
#'   \code{\link{compute_efficiency}}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("plotly", quietly = TRUE) && requireNamespace("geometry", quietly = TRUE)
#' d <- dea_data(
#'   chinese_cities,
#'   inputs  = c("industrial_labour_force", "working_funds", "investments"),
#'   outputs = c("gross_industrial_output", "profit_and_tax", "retail_sales"),
#'   id      = "DMU"
#' )
#' plot_io_3dfrontier(d, inputs = c("working_funds", "investments"),
#'                    output = "retail_sales", rts = "vrs")
#'
#' @export
plot_io_3dfrontier <- function(x, inputs, output,
                               rts = c("crs", "vrs"),
                               orientation = c("in", "out"),
                               peers_network = FALSE,
                               arrow_target = c("peer", "projection"),
                               surface_opacity = 0.4,
                               point_size = 4, transparency = 0.8,
                               label_frontier = TRUE,
                               labels = "none",
                               subtitle = NULL, title = NULL, ...) {
  rts <- match.arg(rts)
  orientation <- match.arg(orientation)
  arrow_target <- tryCatch(
    match.arg(arrow_target),
    error = function(e)
      stop("`arrow_target` must be \"peer\" or \"projection\".", call. = FALSE))
  if (!missing(peers_network) && !isTRUE(peers_network) &&
      !identical(arrow_target, "peer"))
    warning("`arrow_target` is ignored unless `peers_network = TRUE`.",
            call. = FALSE)
  .deaviz_check_flag(peers_network, "peers_network")
  .deaviz_check_flag(label_frontier, "label_frontier")
  .deaviz_check_alpha(transparency)
  .deaviz_check_alpha(surface_opacity, "surface_opacity")
  
  if (!requireNamespace("plotly", quietly = TRUE))
    stop("Package 'plotly' is required: plot_io_3dfrontier() is interactive.",
         call. = FALSE)
  if (!requireNamespace("geometry", quietly = TRUE))
    stop("Package 'geometry' is required to compute the frontier surface.",
         call. = FALSE)
  if (!requireNamespace("Benchmarking", quietly = TRUE))
    stop("Package 'Benchmarking' is required to compute efficiency.",
         call. = FALSE)
  
  d <- as_dea_data(x)
  
  pick <- function(sel, choices, role, n) {
    if (is.numeric(sel)) {
      if (length(sel) != n || any(sel < 1) || any(sel > length(choices)) ||
          any(sel != as.integer(sel)))
        stop("`", role, "` must be ", n, " name(s) or position(s) in 1:",
             length(choices), ".", call. = FALSE)
      return(choices[sel])
    }
    if (is.character(sel) && length(sel) == n) {
      s <- sub("^[io]_", "", sel, ignore.case = TRUE)
      bad <- setdiff(s, choices)
      if (length(bad))
        stop("`", role, "` not found: ", toString(bad), ". Available: ",
             toString(choices), ".", call. = FALSE)
      return(s)
    }
    stop("`", role, "` must be ", n, " ", role, " name(s) or position(s).",
         call. = FALSE)
  }
  ivars <- pick(inputs, colnames(d$X), "inputs", 2L)
  ovar  <- pick(output, colnames(d$Y), "output", 1L)
  if (ivars[1] == ivars[2])
    stop("`inputs` must name two different inputs.", call. = FALSE)
  
  # ---- self-consistent sub-model on the three chosen variables --------------
  sub   <- d
  sub$X <- d$X[, ivars, drop = FALSE]
  sub$Y <- d$Y[, ovar,  drop = FALSE]
  model <- compute_efficiency(sub, rts = rts, orientation = orientation,
                              dual = FALSE)
  eff_raw <- as.numeric(model$eff)
  lambda  <- model$lambda
  is_eff  <- abs(eff_raw - 1) < 1e-9
  eff     <- if (orientation == "out") 1 / eff_raw else eff_raw
  
  x1 <- as.numeric(d$X[, ivars[1]])
  x2 <- as.numeric(d$X[, ivars[2]])
  yv <- as.numeric(d$Y[, ovar])
  lab <- d$labels
  
  surf <- .deaviz_frontier_surface(x1, x2, yv, is_eff, rts)
  
  sub_default <- paste0(ivars[1], ", ", ivars[2], " and ", ovar,
                        " sub-model ", toupper(rts), " efficient frontier")
  subtitle <- if (is.null(subtitle)) sub_default
  else if (length(subtitle) == 1L && is.na(subtitle)) NULL
  else subtitle
  
  spec <- .deaviz_label_spec(labels, lab, 10L)
  opac <- if (spec$mode == "one")
    ifelse(lab == spec$which, transparency, transparency * 0.25) else
      rep(transparency, length(lab))
  
  p <- plotly::plot_ly()
  
  # ---- frontier surface ----------------------------------------------------
  if (!is.null(surf) && nrow(surf$tri) > 0L)
    p <- plotly::add_trace(
      p, type = "mesh3d",
      x = surf$v[, 1], y = surf$v[, 2], z = surf$v[, 3],
      i = surf$tri[, 1] - 1L, j = surf$tri[, 2] - 1L, k = surf$tri[, 3] - 1L,
      opacity = surface_opacity, facecolor = rep("#E69F00", nrow(surf$tri)),
      flatshading = TRUE, hoverinfo = "skip", showlegend = FALSE,
      name = "Frontier")
  
  # ---- peer / projection arrows -------------------------------------------
  if (peers_network) {
    idx <- which(lambda > 1e-6, arr.ind = TRUE)
    idx <- idx[idx[, 1] != idx[, 2] & !is_eff[idx[, 1]] & is_eff[idx[, 2]], ,
               drop = FALSE]
    if (spec$mode == "one")
      idx <- idx[idx[, 1] == match(spec$which, lab), , drop = FALSE]
    if (nrow(idx) > 0L) {
      if (arrow_target == "peer") {
        r <- idx[, 1]; cc <- idx[, 2]; lam <- lambda[idx]
        seg <- data.frame(x0 = x1[r], y0 = x2[r], z0 = yv[r],
                          xe = x1[cc], ye = x2[cc], ze = yv[cc],
                          a = pmax(0.15, lam / max(lam)))
      } else {
        r <- unique(idx[, 1])
        if (orientation == "in") {
          px <- eff_raw[r] * x1[r]; py <- eff_raw[r] * x2[r]; pz <- yv[r]
        } else {
          px <- x1[r]; py <- x2[r]; pz <- yv[r] * eff_raw[r]
        }
        seg <- data.frame(x0 = x1[r], y0 = x2[r], z0 = yv[r],
                          xe = px, ye = py, ze = pz, a = 1)
      }
      # shafts
      for (k in seq_len(nrow(seg)))
        p <- plotly::add_trace(
          p, type = "scatter3d", mode = "lines",
          x = c(seg$x0[k], seg$xe[k]), y = c(seg$y0[k], seg$ye[k]),
          z = c(seg$z0[k], seg$ze[k]),
          line = list(color = .deaviz_accent(), width = 3),
          opacity = seg$a[k], hoverinfo = "skip", showlegend = FALSE)
      
      # Direction markers. plotly's scatter3d lines carry no arrowhead in
      # three dimensions, and cone traces are sized in data coordinates, so
      # they distort the axes badly when the three variables differ in
      # magnitude. A marker at the tip of each segment is sized in pixels
      # instead, so it is independent of the data scale.
      p <- plotly::add_trace(
        p, type = "scatter3d", mode = "markers",
        x = seg$xe, y = seg$ye, z = seg$ze,
        marker = list(size = 4, symbol = "diamond",
                      color = .deaviz_accent()),
        hoverinfo = "skip", showlegend = FALSE)
    }
  }
  
  # ---- units ---------------------------------------------------------------
  txt <- if (label_frontier || spec$mode %in% c("all", "id", "one"))
    ifelse(is_eff | spec$mode %in% c("all", "id") |
             (spec$mode == "one" & lab == spec$which), lab, "") else
               rep("", length(lab))
  
  p <- plotly::add_trace(
    p, type = "scatter3d", mode = if (any(nzchar(txt))) "markers+text" else "markers",
    x = x1, y = x2, z = yv, text = txt, textposition = "top center",
    marker = list(size = point_size, color = eff,
                  colorscale = .deaviz_viridis_colorscale(),
                  cmin = min(eff), cmax = max(eff),
                  opacity = transparency,
                  colorbar = list(title = "Sub-model\nefficiency")),
    opacity = transparency,
    hovertext = paste0(lab, "<br>Efficiency: ", round(eff, 3)),
    hoverinfo = "text", showlegend = FALSE, name = "DMUs")
  
  p <- plotly::layout(
    p,
    title = list(text = if (is.null(subtitle)) title else
      paste0(if (is.null(title)) "" else paste0(title, "<br>"),
             "<sub>", subtitle, "</sub>")),
    margin = list(l = 0, r = 0, b = 0, t = 40),
    scene = list(xaxis = list(title = ivars[1]),
                 yaxis = list(title = ivars[2]),
                 zaxis = list(title = ovar),
                 aspectmode = "cube",
                 camera = list(eye = list(x = 1.6, y = -1.6, z = 0.9))))
  p
}


# Build the efficient frontier surface for two inputs and one output.
#
# Returns a list with `v` (vertex matrix) and `tri` (1-based triangle index
# matrix), or NULL when a surface cannot be formed.
#
# VRS: the frontier is the upper envelope of the convex hull of the observed
# points in (x1, x2, y) space. Free disposability means a hull facet belongs to
# the frontier only if increasing either input, or decreasing the output, moves
# into the production set; equivalently, for the outward normal (n1, n2, n3) of
# a facet of the upper envelope, n3 > 0 (the facet faces upward in output) and
# n1, n2 <= 0 are the input-side conditions. Facets are kept when the outward
# normal has a positive output component.
#
# CRS: the technology is a cone, so the surface is spanned by rays through the
# most productive units. It is built as the upper envelope of the hull of the
# observed points together with the origin, scaled outwards.
.deaviz_frontier_surface <- function(x1, x2, yv, is_eff, rts) {
  pts <- cbind(x1, x2, yv)
  n <- nrow(pts)
  if (n < 4L) return(NULL)
  
  if (rts == "crs") {
    # A CRS technology is a cone, so the frontier is the cone over the unit
    # isoquant. Working in input-per-unit-output space turns this into a
    # two-dimensional hull problem, which stays well conditioned even when
    # only one or two units are efficient.
    e <- which(is_eff)
    if (!length(e) || any(yv[e] <= 0)) return(NULL)
    a <- x1[e] / yv[e]
    b <- x2[e] / yv[e]
    
    # keep only the units not dominated in both inputs
    nd <- vapply(seq_along(a), function(i)
      !any((a <= a[i] + 1e-12 & b <= b[i] + 1e-12) &
             (a <  a[i] - 1e-12 | b <  b[i] - 1e-12)), logical(1))
    a <- a[nd]; b <- b[nd]
    o <- order(a, b); a <- a[o]; b <- b[o]
    
    # lower-left convex hull of the unit isoquant
    if (length(a) > 2L) {
      keep <- rep(TRUE, length(a))
      repeat {
        idx <- which(keep); changed <- FALSE
        if (length(idx) < 3L) break
        for (k in seq_len(length(idx) - 2L)) {
          i1 <- idx[k]; i2 <- idx[k + 1L]; i3 <- idx[k + 2L]
          cross <- (a[i2] - a[i1]) * (b[i3] - b[i1]) -
            (b[i2] - b[i1]) * (a[i3] - a[i1])
          if (cross <= 1e-12) { keep[i2] <- FALSE; changed <- TRUE; break }
        }
        if (!changed) break
      }
      a <- a[keep]; b <- b[keep]
    }
    
    # free disposability: extend the isoquant along both axes
    amax <- max(x1 / pmax(yv, 1e-12)) * 1.10
    bmax <- max(x2 / pmax(yv, 1e-12)) * 1.10
    a <- c(a[1], a, max(amax, a[length(a)] * 1.10))
    b <- c(max(bmax, b[1] * 1.10), b, b[length(b)])
    
    # extrude the isoquant from the origin: the cone surface. Each ray is
    # scaled separately so that the fan stays within the data range; because
    # the technology is a cone, scaling a ray keeps its points on the surface.
    xlim <- max(x1) * 1.05
    ylim <- max(x2) * 1.05
    tmax <- max(yv)  * 1.05
    tray <- pmin(tmax,
                 ifelse(a > 1e-12, xlim / a, Inf),
                 ifelse(b > 1e-12, ylim / b, Inf))
    v   <- rbind(c(0, 0, 0), cbind(a * tray, b * tray, tray))
    m   <- nrow(v)
    if (m < 3L) return(NULL)
    tri <- cbind(1L, seq.int(2L, m - 1L), seq.int(3L, m))
    return(.deaviz_prune_mesh(v, tri))
  }
  
  # VRS: the frontier is the monotone concave envelope of the observed points,
  # not merely the upper envelope of their convex hull. Free disposability
  # means that any unit can also be operated with MORE of either input at the
  # same output, so the point set is augmented with those disposal points
  # before the hull is taken. Without this the hull tilts facets through
  # dominated units and reports them as frontier vertices.
  big1 <- max(x1) * 1.08
  big2 <- max(x2) * 1.08
  disp <- rbind(
    cbind(rep(big1, n), x2,            yv),   # more of input 1
    cbind(x1,           rep(big2, n),  yv),   # more of input 2
    cbind(rep(big1, n), rep(big2, n),  yv)    # more of both
  )
  aug  <- rbind(pts, disp)
  # a floor below the data closes the hull so that an upper envelope exists
  floor_y <- min(yv) - (max(yv) - min(yv)) * 0.25 - 1
  n_real <- nrow(aug)                       # data + disposal points
  aug <- rbind(aug,
               cbind(c(min(x1), big1, min(x1), big1),
                     c(min(x2), min(x2), big2, big2),
                     rep(floor_y, 4)))
  
  hull <- try(geometry::convhulln(aug, options = "Qt Pp"), silent = TRUE)
  if (inherits(hull, "try-error")) return(NULL)
  tri <- if (is.list(hull)) hull$hull else hull
  
  ctr  <- colMeans(aug)
  keep <- vapply(seq_len(nrow(tri)), function(t) {
    v <- aug[tri[t, ], , drop = FALSE]
    nv <- .deaviz_tri_normal(v)
    if (sum(nv * (colMeans(v) - ctr)) < 0) nv <- -nv
    nv[3] > 1e-9
  }, logical(1))
  # the floor exists only to close the hull; facets touching it are side walls,
  # not part of the frontier
  keep <- keep & apply(tri <= n_real, 1, all)
  tri <- tri[keep, , drop = FALSE]
  if (!nrow(tri)) return(NULL)
  .deaviz_prune_mesh(aug, tri)
}

# Keep only the vertices referenced by the retained triangles and renumber the
# index matrix accordingly. Unused vertices (the disposal points and the floor
# used to close the hull) would otherwise be passed to plotly, which computes
# axis ranges from every supplied coordinate and would stretch the axes far
# beyond the data, including below zero.
.deaviz_prune_mesh <- function(v, tri) {
  used <- sort(unique(as.vector(tri)))
  remap <- integer(max(used))
  remap[used] <- seq_along(used)
  list(v = v[used, , drop = FALSE],
       tri = matrix(remap[tri], ncol = 3L))
}

# Unit normal of a triangle given as a 3x3 matrix of vertices.
.deaviz_tri_normal <- function(v) {
  a <- v[2, ] - v[1, ]
  b <- v[3, ] - v[1, ]
  n <- c(a[2] * b[3] - a[3] * b[2],
         a[3] * b[1] - a[1] * b[3],
         a[1] * b[2] - a[2] * b[1])
  len <- sqrt(sum(n^2))
  if (len < 1e-12) return(c(0, 0, 0))
  n / len
}