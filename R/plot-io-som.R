#' Plot a self-organizing map of DEA efficiency
#'
#' Draws the hexagonal SOM as a property map, colouring each node by the mean
#' efficiency of the DMUs assigned to it, and (optionally) labels the nodes with
#' the DMU names. Uses base graphics, so the plot is produced as a side effect
#' on the active device.
#'
#' @param som A \code{dea_som} object from \code{\link{compute_som}}, or a
#'   \code{dea_data} object / data frame, in which case the map is fitted first.
#' @param labels Which DMUs to write on the map: \code{"all"} (default),
#'   \code{"none"}, or the name/id of a single DMU to label only that one.
#' @param max.overlaps.value Accepted for API consistency; unused here
#'   (default \code{10}).
#' @param jitter_sd Standard deviation of the random jitter applied to label
#'   positions so co-located labels do not overlap (default \code{0.1}).
#' @param seed Optional single number making the label jitter reproducible
#'   without changing the session's random state.
#' @param title Plot title.
#' @param ... When \code{som} is data rather than a \code{dea_som}, further
#'   arguments passed to \code{\link{compute_som}}.
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
#' @param subtitle Optional subtitle shown beneath the title.
#' @return The \code{dea_som} object, invisibly.
#'
#' @seealso \code{\link{compute_som}}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("kohonen", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:12),
#'   i_x1 = runif(12, 2, 9), i_x2 = runif(12, 1, 5),
#'   o_y1 = runif(12, 3, 9), o_y2 = runif(12, 1, 4)
#' )
#' som <- compute_som(df, xdim = 4, ydim = 4, seed = 1)
#' plot_io_som(som)
#'
#' @export
plot_io_som <- function(som, labels = "all", max.overlaps.value = 10,
                        jitter_sd = 0.1, seed = NULL, transparency = 0.7,
                        subtitle = NULL,
                        title = "SOM: mean efficiency per node", ...) {
  .deaviz_check_alpha(transparency)
  if (!inherits(som, "dea_som"))
    som <- compute_som(som, ...)

  spec <- .deaviz_label_spec(labels, som$labels, max.overlaps.value)
  if (!is.numeric(jitter_sd) || length(jitter_sd) != 1L || jitter_sd < 0)
    stop("`jitter_sd` must be a single non-negative number.", call. = FALSE)
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L))
    stop("`seed` must be a single number or NULL.", call. = FALSE)
  if (!requireNamespace("kohonen", quietly = TRUE))
    stop("Package 'kohonen' is required for this plot.", call. = FALSE)

  # blue (low) -> red (high) palette
  cool_to_hot <- function(n, alpha = transparency)
    .deaviz_sequential(n, alpha = alpha)

  graphics::plot(som$som, type = "property", property = som$node_efficiency,
                 palette.name = cool_to_hot, main = title)
  if (!is.null(subtitle))
    graphics::mtext(subtitle, side = 3, line = 0.2, cex = 0.85)

  if (spec$mode != "none") {
    pts <- som$som$grid$pts[som$som$unit.classif, , drop = FALSE]
    if (!is.null(seed)) {
      if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
        old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
        on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv),
                add = TRUE)
      } else {
        on.exit(suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)),
                add = TRUE)
      }
      set.seed(seed)
    }
    j <- matrix(stats::rnorm(nrow(pts) * 2, mean = 0, sd = jitter_sd), ncol = 2)
    if (spec$mode == "one") {
      keep <- as.character(som$labels) == spec$which
      graphics::text(x = pts[keep, 1] + j[keep, 1],
                     y = pts[keep, 2] + j[keep, 2],
                     labels = som$labels[keep], col = "white",
                     cex = 1.1, font = 2)
    } else {
      txt <- if (spec$mode == "id")
               as.character(match(as.character(som$labels), spec$known))
             else som$labels
      graphics::text(x = pts[, 1] + j[, 1], y = pts[, 2] + j[, 2],
                     labels = txt, col = "white", cex = 0.7)
    }
  }

  invisible(som)
}
