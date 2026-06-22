#' Plot the component planes of a DEA self-organizing map
#'
#' Draws one SOM property map per input/output variable -- the "component
#' planes" -- each node coloured by that variable's codebook weight. This shows
#' how each input and output varies across the trained map. Uses base graphics,
#' so the panels are produced as a side effect on the active device.
#'
#' @param som A \code{dea_som} object from \code{\link{compute_som}}, or a
#'   \code{dea_data} object / data frame, in which case the map is fitted first.
#' @param variables Optional character vector selecting which variables to draw
#'   (default: all). Names are matched against the input/output column names.
#' @param ncol Number of panels per row (positive integer; default \code{3}).
#' @param labels Logical; if \code{TRUE} (default) each panel is titled with its variable name.
#' @param title Optional overall title drawn above the panel grid.
#' @param ... When \code{som} is data rather than a \code{dea_som}, further
#'   arguments passed to \code{\link{compute_som}}.
#'
#' @param transparency Opacity of the markers/areas, a single number in
#'   \code{[0, 1]} (default \code{0.7}).
#' @param subtitle Optional subtitle shown beneath the title.
#' @return The \code{dea_som} object, invisibly.
#'
#' @seealso \code{\link{compute_som}}, \code{\link{plot_io_som}}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("kohonen", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:12),
#'   i_x1 = runif(12, 2, 9), i_x2 = runif(12, 1, 5),
#'   o_y1 = runif(12, 3, 9), o_y2 = runif(12, 1, 4)
#' )
#' som <- compute_som(df, xdim = 4, ydim = 4, seed = 1)
#' plot_io_som_components(som)
#'
#' @export
plot_io_som_components <- function(som, variables = NULL, ncol = 3,
                                   labels = TRUE, transparency = 0.7, subtitle = NULL, title = NULL, ...) {
  .deaviz_check_alpha(transparency)
  if (!is.logical(labels) || length(labels) != 1L || is.na(labels))
    stop("`labels` must be a single TRUE or FALSE.", call. = FALSE)
  if (!inherits(som, "dea_som"))
    som <- compute_som(som, ...)

  if (!is.numeric(ncol) || length(ncol) != 1L || !is.finite(ncol) ||
      ncol < 1 || ncol %% 1 != 0)
    stop("`ncol` must be a single positive integer.", call. = FALSE)
  if (!is.null(title) && (!is.character(title) || length(title) != 1L))
    stop("`title` must be a single string or NULL.", call. = FALSE)
  if (!requireNamespace("kohonen", quietly = TRUE))
    stop("Package 'kohonen' is required for this plot.", call. = FALSE)

  codes     <- som$som$codes[[1]]          # nodes x variables
  var_names <- colnames(codes)

  if (is.null(variables)) {
    variables <- var_names
  } else {
    if (!is.character(variables))
      stop("`variables` must be a character vector of variable names.",
           call. = FALSE)
    unknown <- setdiff(variables, var_names)
    if (length(unknown))
      stop("Unknown variable(s): ", toString(unknown),
           ". Available: ", toString(var_names), ".", call. = FALSE)
  }

  cool_to_hot <- function(n, alpha = transparency)
    .deaviz_sequential(n, alpha = alpha)

  np   <- length(variables)
  ncol <- min(ncol, np)
  nrow <- ceiling(np / ncol)

  oma_top <- 0
  if (!is.null(title))    oma_top <- oma_top + 2
  if (!is.null(subtitle)) oma_top <- oma_top + 1
  oma <- c(0, 0, oma_top, 0)
  old_par <- graphics::par(mfrow = c(nrow, ncol), oma = oma)
  on.exit(graphics::par(old_par), add = TRUE)

  for (v in variables)
    graphics::plot(som$som, type = "property", property = codes[, v],
                   palette.name = cool_to_hot, main = if (labels) v else "")

  if (!is.null(title))
    graphics::mtext(title, outer = TRUE, cex = 1.2, font = 2,
                    line = if (!is.null(subtitle)) 1 else 0.3)
  if (!is.null(subtitle))
    graphics::mtext(subtitle, outer = TRUE, cex = 0.9, line = -0.3)

  invisible(som)
}
