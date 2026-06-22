#' Cross-efficiency and benevolent weights
#'
#' Functions for the cross-efficiency analysis of a DEA problem: the
#' cross-efficiency matrix itself (\code{compute_cross_efficiency}), the
#' benevolent multiplier weights used to build it
#' (\code{compute_cross_efficiency_weights}), and a helper to put those weights on a
#' common scale (\code{standardize_weights}).
#'
#' @section Secondary-goal model:
#' Multiplier (weight) solutions in DEA are not unique, so cross-efficiency
#' requires a secondary goal to choose among a unit's optimal weights. For unit
#' \eqn{o} the model fixes the unit's own efficiency at its CRS score
#' \eqn{\theta_o} and then, among all weight vectors that keep it there,
#' optimises the total weighted output of the \emph{other} units --
#' maximising it for the \code{"benevolent"} approach, minimising it for the
#' \code{"aggressive"} one. The unit's own efficiencies \eqn{\theta_o} and the
#' fall-back weights come from a single \code{\link[Benchmarking]{dea}} solve.
#'
#' @name cross-efficiency
#' @seealso \code{\link{compute_efficiency}}, \code{\link{dea_data}}
NULL

#' @describeIn cross-efficiency Compute the cross-efficiency matrix.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param approach Secondary goal: \code{"benevolent"} (maximise others'
#'   weighted output) or \code{"aggressive"} (minimise it).
#' @param epsilon Lower bound applied to every multiplier weight. The default
#'   \code{0} reproduces the plain model (weights may be zero); set a small
#'   positive value (e.g. \code{1e-6}) to enforce strictly positive,
#'   non-Archimedean weights.
#'
#' @return \code{compute_cross_efficiency} returns an \eqn{n \times n} numeric
#'   matrix whose entry \code{[k, j]} is the efficiency of DMU \code{j} evaluated
#'   with the weights of DMU \code{k} (rows are rating units, columns are rated
#'   units). Row and column names are the DMU labels.
#'
#' @references
#' Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
#' Derivations, meanings and uses. \emph{Journal of the Operational Research
#' Society}, 45(5), 567--578. \doi{10.1057/jors.1994.84}
#'
#' @examplesIf requireNamespace("Benchmarking", quietly = TRUE) && requireNamespace("lpSolve", quietly = TRUE)
#' df <- data.frame(
#'   dmu   = c("A", "B", "C", "D"),
#'   i_x1  = c(4, 7, 8, 4),
#'   i_x2  = c(3, 3, 1, 2),
#'   o_y   = c(1, 1, 1, 1)
#' )
#' ce <- compute_cross_efficiency(df, approach = "benevolent")
#' round(ce, 3)
#' colMeans(ce)   # each unit's average cross-efficiency
#'
#' @export
compute_cross_efficiency <- function(x,
                                     approach = c("benevolent", "aggressive"),
                                     epsilon = 0) {
  approach  <- match.arg(approach)
  direction <- if (approach == "benevolent") "max" else "min"
  .check_epsilon(epsilon)
  .need(c("Benchmarking", "lpSolve"))

  d <- as_dea_data(x)
  X <- d$X
  Y <- d$Y
  n_out <- ncol(Y)

  W <- .secondary_goal_weights(X, Y, direction, epsilon)
  w_out <- W[, seq_len(n_out), drop = FALSE]
  w_in  <- W[, n_out + seq_len(ncol(X)), drop = FALSE]

  cem <- (w_out %*% t(Y)) / (w_in %*% t(X))
  dimnames(cem) <- list(d$labels, d$labels)
  cem
}

#' @describeIn cross-efficiency Secondary-goal multiplier weights for every DMU.
#'
#' @param normalize Logical; if \code{TRUE} (default) inputs and outputs are
#'   max-normalised column-wise before solving, so the returned weights are on a
#'   comparable scale (useful for plotting).
#'
#' @return \code{compute_cross_efficiency_weights} returns a list with matrices
#'   \code{input_weights} and \code{output_weights} (one row per DMU, labelled).
#'
#' @references
#' Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
#' Derivations, meanings and uses. \emph{Journal of the Operational Research
#' Society}, 45(5), 567--578. \doi{10.1057/jors.1994.84}
#'
#' @export
compute_cross_efficiency_weights <- function(x,
                                           approach = c("benevolent",
                                                        "aggressive"),
                                           epsilon = 0, normalize = TRUE) {
  approach  <- match.arg(approach)
  direction <- if (approach == "benevolent") "max" else "min"
  .check_epsilon(epsilon)
  if (!is.logical(normalize) || length(normalize) != 1L || is.na(normalize))
    stop("`normalize` must be a single TRUE or FALSE.", call. = FALSE)
  .need(c("Benchmarking", "lpSolve"))

  d <- as_dea_data(x)
  X <- d$X
  Y <- d$Y
  if (normalize) {
    X <- .max_normalize(X)
    Y <- .max_normalize(Y)
  }

  n_out <- ncol(Y)
  W <- .secondary_goal_weights(X, Y, direction, epsilon)
  out_w <- W[, seq_len(n_out), drop = FALSE]
  in_w  <- W[, n_out + seq_len(ncol(X)), drop = FALSE]
  dimnames(out_w) <- list(d$labels, colnames(Y))
  dimnames(in_w)  <- list(d$labels, colnames(X))

  list(input_weights = in_w, output_weights = out_w)
}

#' @describeIn cross-efficiency Row-standardise a set of weights so that, within
#'   each DMU, the input weights sum to one and the output weights sum to one.
#'
#' @param weights A list with \code{input_weights} and \code{output_weights}
#'   matrices, such as the result of \code{compute_cross_efficiency_weights}.
#'
#' @return \code{standardize_weights} returns a list of the same shape as
#'   \code{weights}, row-standardised and rounded to 5 digits.
#'
#' @references
#' Doyle, J., & Green, R. (1994). Efficiency and cross-efficiency in DEA:
#' Derivations, meanings and uses. \emph{Journal of the Operational Research
#' Society}, 45(5), 567--578. \doi{10.1057/jors.1994.84}
#'
#' @export
standardize_weights <- function(weights) {
  if (!is.list(weights) ||
      !all(c("input_weights", "output_weights") %in% names(weights)))
    stop("`weights` must be a list with `input_weights` and `output_weights` ",
         "(e.g. the result of compute_cross_efficiency_weights()).", call. = FALSE)

  norm_rows <- function(m) {
    m  <- as.matrix(m)
    rs <- rowSums(m)
    if (any(rs == 0)) {
      warning("Row(s) with zero total weight left unstandardised (kept as 0).",
              call. = FALSE)
      rs[rs == 0] <- 1
    }
    round(m / rs, 5)
  }

  list(input_weights  = norm_rows(weights$input_weights),
       output_weights = norm_rows(weights$output_weights))
}


# ---- internal helpers -------------------------------------------------------

#' Secondary-goal weight matrix for all DMUs
#' @param X,Y Numeric input/output matrices (one row per DMU).
#' @param direction \code{"max"} (benevolent) or \code{"min"} (aggressive).
#' @param epsilon Lower bound on the weights.
#' @return An \eqn{n \times (n\_out + n\_in)} matrix of weights, outputs first.
#' @keywords internal
#' @noRd
.secondary_goal_weights <- function(X, Y, direction, epsilon) {
  n     <- nrow(X)
  n_var <- ncol(Y) + ncol(X)

  bench    <- Benchmarking::dea(X = X, Y = Y, RTS = "crs", DUAL = TRUE)
  theta    <- bench$eff
  fallback <- cbind(bench$vy, bench$ux)        # [outputs (u), inputs (v)]

  W <- matrix(NA_real_, nrow = n, ncol = n_var)
  for (o in seq_len(n))
    W[o, ] <- .cross_eff_unit(o, X, Y, theta[o], fallback[o, ],
                              direction, epsilon)
  W
}

#' Secondary-goal LP for a single DMU
#' @return A numeric weight vector (outputs first, then inputs).
#' @keywords internal
#' @noRd
.cross_eff_unit <- function(o, X, Y, theta_o, fallback, direction, epsilon) {
  n      <- nrow(X)
  n_in   <- ncol(X)
  n_out  <- ncol(Y)
  n_var  <- n_out + n_in
  others <- seq_len(n)[-o]

  # objective: optimise the other units' total weighted output
  obj <- c(colSums(Y[others, , drop = FALSE]), rep(0, n_in))

  con_norm   <- c(rep(0, n_out), X[o, ])                              # v'x_o = 1
  con_others <- cbind(Y[others, , drop = FALSE],
                      -X[others, , drop = FALSE])                     # u'y_j <= v'x_j
  con_bounds <- diag(n_var)                                           # weights >= epsilon
  con_target <- c(Y[o, ], -theta_o * X[o, ])                          # u'y_o = theta_o

  A   <- rbind(con_norm, con_others, con_bounds, con_target)
  dir <- c("=", rep("<=", length(others)), rep(">=", n_var), "=")
  rhs <- c(1, rep(0, length(others)), rep(epsilon, n_var), 0)

  res <- lpSolve::lp(direction = direction, objective.in = obj,
                     const.mat = A, const.dir = dir, const.rhs = rhs)

  if (res$status != 0L || sum(res$solution) == 0) {
    if (res$status != 0L)
      warning("Secondary-goal LP for DMU ", o, " did not solve to optimality ",
              "(lpSolve status ", res$status, "); using the primal weights.",
              call. = FALSE)
    return(fallback)
  }
  res$solution
}

#' Column-wise max normalisation
#' @keywords internal
#' @noRd
.max_normalize <- function(m) {
  mx <- apply(m, 2, max)
  if (any(mx == 0))
    stop("Cannot max-normalise a column whose maximum is zero.", call. = FALSE)
  sweep(m, 2, mx, "/")
}

#' Validate an epsilon argument
#' @keywords internal
#' @noRd
.check_epsilon <- function(epsilon) {
  if (!is.numeric(epsilon) || length(epsilon) != 1L || !is.finite(epsilon) ||
      epsilon < 0)
    stop("`epsilon` must be a single non-negative number.", call. = FALSE)
  invisible(TRUE)
}

#' Require one or more packages or stop
#' @keywords internal
#' @noRd
.need <- function(pkgs) {
  missing <- pkgs[!vapply(pkgs, requireNamespace, logical(1L), quietly = TRUE)]
  if (length(missing))
    stop("Package(s) required but not installed: ", toString(missing), ".",
         call. = FALSE)
  invisible(TRUE)
}
