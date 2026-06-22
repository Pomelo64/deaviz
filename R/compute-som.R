#' Fit a self-organizing map to a DEA problem
#'
#' Trains a hexagonal self-organizing map (SOM) on the standardised input/output
#' data and records, for every node, the mean DEA efficiency of the DMUs mapped
#' to it. The result feeds \code{\link{plot_io_som}} (and other SOM views), so the
#' map is trained once and reused.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param rts Returns to scale, passed to \code{\link{compute_efficiency}}:
#'   \code{"crs"} or \code{"vrs"}.
#' @param xdim,ydim Grid dimensions (positive integers; default \code{8} each).
#' @param rlen Number of training iterations (default \code{1000}).
#' @param seed Optional single number; if supplied, SOM training is made
#'   reproducible without permanently changing the session's random state.
#' @param ... Further arguments passed to \code{\link[kohonen]{som}}.
#'
#' @return An object of class \code{dea_som}: a list with the fitted
#'   \code{som} (a \code{kohonen} object), the DMU \code{labels}, per-DMU
#'   \code{efficiency}, per-node mean \code{node_efficiency} (\code{NA} for empty
#'   nodes), and the grid dimensions.
#'
#' @seealso \code{\link{plot_io_som}}, \code{\link[kohonen]{som}}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("kohonen", quietly = TRUE)
#' df <- data.frame(
#'   dmu  = paste0("D", 1:12),
#'   i_x1 = runif(12, 2, 9), i_x2 = runif(12, 1, 5),
#'   o_y1 = runif(12, 3, 9), o_y2 = runif(12, 1, 4)
#' )
#' som <- compute_som(df, xdim = 4, ydim = 4, seed = 1)
#' som
#'
#' @export
compute_som <- function(x, rts = c("crs", "vrs"), xdim = 8, ydim = 8,
                        rlen = 1000, seed = NULL, ...) {
  rts <- match.arg(rts)
  for (nm in c("xdim", "ydim", "rlen")) {
    v <- get(nm)
    if (!is.numeric(v) || length(v) != 1L || !is.finite(v) || v < 1 ||
        v %% 1 != 0)
      stop("`", nm, "` must be a single positive integer.", call. = FALSE)
  }
  if (!is.null(seed) && (!is.numeric(seed) || length(seed) != 1L))
    stop("`seed` must be a single number or NULL.", call. = FALSE)
  if (!requireNamespace("kohonen", quietly = TRUE))
    stop("Package 'kohonen' is required to fit a SOM.", call. = FALSE)

  d <- as_dea_data(x)
  data_mat <- cbind(d$X, d$Y)

  sds <- apply(data_mat, 2, stats::sd)
  if (any(sds == 0))
    stop("SOM cannot use constant (zero-variance) column(s): ",
         toString(colnames(data_mat)[sds == 0]), ".", call. = FALSE)

  eff <- as.numeric(compute_efficiency(d, rts = rts, dual = FALSE)$eff)

  # set the seed locally, restoring the caller's RNG state on exit
  if (!is.null(seed)) {
    if (exists(".Random.seed", envir = .GlobalEnv, inherits = FALSE)) {
      old_seed <- get(".Random.seed", envir = .GlobalEnv, inherits = FALSE)
      on.exit(assign(".Random.seed", old_seed, envir = .GlobalEnv), add = TRUE)
    } else {
      on.exit(suppressWarnings(rm(".Random.seed", envir = .GlobalEnv)),
              add = TRUE)
    }
    set.seed(seed)
  }

  sdata <- scale(data_mat)
  total <- xdim * ydim
  grid  <- kohonen::somgrid(xdim = xdim, ydim = ydim, topo = "hexagonal")
  # Sample the initial node prototypes WITH replacement so the grid may have
  # more nodes than there are DMUs. kohonen's default samples without
  # replacement and errors when xdim * ydim exceeds the number of units.
  init <- sdata[sample.int(nrow(sdata), total, replace = TRUE), , drop = FALSE]
  fit  <- kohonen::som(sdata, grid = grid, rlen = rlen, init = init,
                       keep.data = TRUE, ...)
  node_efficiency <- vapply(seq_len(total), function(k) {
    m <- mean(eff[fit$unit.classif == k])
    if (is.nan(m)) NA_real_ else m
  }, numeric(1))

  structure(
    list(som = fit, labels = d$labels, efficiency = eff,
         node_efficiency = node_efficiency, rts = rts,
         xdim = xdim, ydim = ydim),
    class = "dea_som"
  )
}

#' Print a fitted DEA self-organizing map
#'
#' @param x A \code{dea_som} object, as returned by \code{\link{compute_som}}.
#' @param ... Ignored.
#'
#' @return \code{x}, invisibly.
#'
#' @export
print.dea_som <- function(x, ...) {
  cat("<dea_som>\n")
  cat(sprintf("  grid           : %d x %d hexagonal (%d nodes)\n",
              x$xdim, x$ydim, x$xdim * x$ydim))
  cat(sprintf("  DMUs           : %d\n", length(x$labels)))
  cat(sprintf("  RTS            : %s\n", toupper(x$rts)))
  cat(sprintf("  occupied nodes : %d\n", sum(!is.na(x$node_efficiency))))
  invisible(x)
}
