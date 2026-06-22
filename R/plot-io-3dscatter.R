#' Interactive 3-D scatter plot of a DEA problem
#'
#' Plots the DMUs in three dimensions, with each axis and the point colour set
#' to any input/output variable or any DEA efficiency model (so a returns-to-
#' scale efficiency such as \code{"crs"} or \code{"vrs"} can be used as a
#' dimension). Efficiencies are computed only when referenced, each at most
#' once. This plot is always interactive (\pkg{plotly}); it has no static form.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param dim_x,dim_y,dim_z Names of the quantities to map to the three axes.
#'   Each is either an input/output variable name or an efficiency model
#'   (\code{"crs"}, \code{"vrs"}, \code{"drs"}, \code{"irs"}, \code{"fdh"},
#'   \code{"add"}; a trailing \code{"_efficiency"} is also accepted).
#' @param color Quantity mapping to point colour (same options as the axes;
#'   default \code{"crs"}).
#' @param orientation Measurement orientation for efficiency scores, passed to
#'   \code{\link{compute_efficiency}} (default \code{"in"}).
#' @param labels Which DMUs to label: \code{"none"} (default), \code{"all"}
#'   / \code{"max.overlaps"} (label every point), or the name/id of a single
#'   DMU to label only that one.
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param title Optional plot title.
#' @param ... Additional arguments passed to \code{plotly::plot_ly}.
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
#' @param subtitle Optional subtitle shown beneath the title.
#' @return A \pkg{plotly} object.
#'
#' @seealso \code{\link{compute_efficiency}}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("plotly", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:6),
#'   i_x1 = c(4, 7, 8, 4, 2, 5),
#'   i_x2 = c(3, 3, 1, 2, 4, 2),
#'   o_y  = c(5, 8, 6, 7, 3, 9)
#' )
#' plot_io_3dscatter(df, dim_x = "x1", dim_y = "x2", dim_z = "y", color = "crs")
#'
#' @export
plot_io_3dscatter <- function(x, dim_x, dim_y, dim_z, color = "crs",
                              orientation = "in", labels = "none",
                              max.overlaps.value = 10,
                              transparency = 0.7, subtitle = NULL, title = NULL, ...) {
  .deaviz_check_alpha(transparency)
  if (missing(dim_x) || missing(dim_y) || missing(dim_z))
    stop("`dim_x`, `dim_y` and `dim_z` must all be supplied.", call. = FALSE)
  if (!requireNamespace("plotly", quietly = TRUE))
    stop("Package 'plotly' is required for plotting.", call. = FALSE)

  d    <- as_dea_data(x)
  vars <- as.data.frame(cbind(d$X, d$Y))
  var_names    <- colnames(vars)
  rts_keywords <- c("crs", "vrs", "drs", "irs", "fdh", "add")

  cache <- list()
  resolve <- function(name, role) {
    if (length(name) != 1L || !is.character(name))
      stop("`", role, "` must be a single string.", call. = FALSE)
    if (name %in% var_names) return(vars[[name]])
    key <- sub("_efficiency$", "", name)
    if (key %in% rts_keywords) {
      if (!requireNamespace("Benchmarking", quietly = TRUE))
        stop("Package 'Benchmarking' is required to compute efficiency.",
             call. = FALSE)
      if (is.null(cache[[key]]))
        cache[[key]] <<- as.numeric(
          compute_efficiency(d, rts = key, orientation = orientation,
                             dual = FALSE)$eff)
      return(cache[[key]])
    }
    stop("`", role, "` = '", name, "' is not a variable (",
         toString(var_names), ") or an efficiency (",
         toString(rts_keywords), ").", call. = FALSE)
  }

  xv <- resolve(dim_x, "dim_x")
  yv <- resolve(dim_y, "dim_y")
  zv <- resolve(dim_z, "dim_z")
  cv <- resolve(color, "color")
  spec <- .deaviz_label_spec(labels, d$labels, max.overlaps.value)
  txt  <- d$labels
  if (spec$mode == "none") {
    mode <- "markers"
  } else if (spec$mode == "one") {
    mode <- "markers+text"
    txt  <- ifelse(as.character(d$labels) == spec$which, d$labels, "")
  } else if (spec$mode == "id") {
    mode <- "markers+text"
    txt  <- as.character(match(as.character(d$labels), spec$known))
  } else {
    mode <- "markers+text"
  }

  p <- plotly::plot_ly(x = xv, y = yv, z = zv, color = cv,
                       opacity = transparency,
                       colors = .deaviz_sequential(),
                       text = txt, type = "scatter3d", mode = mode, ...)
  ttl <- if (!is.null(subtitle))
           paste0(if (is.null(title)) "" else title,
                  "<br><sup>", subtitle, "</sup>")
         else title
  plotly::layout(
    p,
    title = ttl,
    scene = list(xaxis = list(title = dim_x),
                 yaxis = list(title = dim_y),
                 zaxis = list(title = dim_z))
  )
}
