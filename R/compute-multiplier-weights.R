#' Compute DEA multiplier (weight) solutions
#'
#' Solves the input-oriented, constant-returns-to-scale (CCR) \emph{multiplier}
#' DEA model for every decision-making unit and returns the optimal efficiency
#' scores together with the input and output weights. A non-Archimedean lower
#' bound \code{epsilon} keeps all weights strictly positive.
#'
#' For unit \eqn{o} the model maximises the weighted output \eqn{u^\top y_o}
#' subject to the normalisation \eqn{v^\top x_o = 1} and
#' \eqn{u^\top y_j - v^\top x_j \le 0} for every unit \eqn{j}, with
#' \eqn{u, v \ge \epsilon}. The optimal value is the unit's efficiency score.
#'
#' @details
#' DEA multiplier solutions are generally \strong{not unique}: efficient units
#' and degenerate vertices admit alternative optimal weight vectors. This
#' function returns \emph{one} optimal solution (the vertex the solver settles
#' on), not a canonical one. Treat the returned weights accordingly when they
#' feed downstream calculations such as cross-efficiency.
#'
#' @param x A \code{dea_data} object, or a data frame coerced by
#'   \code{\link{as_dea_data}}.
#' @param epsilon Non-Archimedean lower bound on every multiplier weight; must
#'   be a single non-negative number. Defaults to \code{1e-6}.
#'
#' @return A list with components
#'   \describe{
#'     \item{\code{eff}}{named numeric vector of efficiency scores.}
#'     \item{\code{input_weights}}{matrix of input multipliers
#'       (one row per DMU, one column per input).}
#'     \item{\code{output_weights}}{matrix of output multipliers
#'       (one row per DMU, one column per output).}
#'   }
#'   All rows are labelled with the DMU labels carried by \code{x}.
#'
#' @seealso \code{\link{compute_efficiency}} for scores via
#'   \code{\link[Benchmarking]{dea}}; \code{\link{dea_data}} for the data
#'   contract.
#'
#' @examplesIf requireNamespace("lpSolveAPI", quietly = TRUE)
#' df <- data.frame(i_x = c(2, 3, 4), o_y = c(1, 2, 2))
#' w <- compute_multiplier_weights(df)
#' w$eff
#' w$input_weights
#'
#' @export
compute_multiplier_weights <- function(x, epsilon = 1e-6) {

  if (!is.numeric(epsilon) || length(epsilon) != 1L || !is.finite(epsilon) ||
      epsilon < 0)
    stop("`epsilon` must be a single non-negative number.", call. = FALSE)
  if (!requireNamespace("lpSolveAPI", quietly = TRUE))
    stop("Package 'lpSolveAPI' is required to compute multiplier weights.",
         call. = FALSE)

  d <- as_dea_data(x)
  X <- d$X
  Y <- d$Y
  n <- nrow(X)
  n_in  <- ncol(X)
  n_out <- ncol(Y)

  eff <- numeric(n)
  W   <- matrix(NA_real_, nrow = n, ncol = n_out + n_in)

  for (o in seq_len(n)) {
    sol <- .solve_multiplier_lp(o, X, Y, epsilon)
    eff[o]  <- sol$objective
    W[o, ]  <- sol$weights
  }

  out_w <- W[, seq_len(n_out), drop = FALSE]
  in_w  <- W[, n_out + seq_len(n_in), drop = FALSE]
  dimnames(out_w) <- list(d$labels, colnames(Y))
  dimnames(in_w)  <- list(d$labels, colnames(X))
  names(eff) <- d$labels

  list(eff = eff, input_weights = in_w, output_weights = out_w)
}

#' Solve the CCR multiplier LP for a single DMU
#'
#' @param o Integer index of the unit under evaluation.
#' @param X,Y Numeric input and output matrices (one row per DMU).
#' @param epsilon Lower bound on the weights.
#' @return A list with \code{objective} (the score) and \code{weights}
#'   (ordered outputs then inputs).
#' @keywords internal
#' @noRd
.solve_multiplier_lp <- function(o, X, Y, epsilon) {
  n     <- nrow(X)
  n_in  <- ncol(X)
  n_out <- ncol(Y)
  n_var <- n_out + n_in                       # variables: [u (outputs), v (inputs)]

  lp <- lpSolveAPI::make.lp(nrow = 0L, ncol = n_var)
  lpSolveAPI::lp.control(lp, sense = "max")

  # objective: maximise u'y_o (zero on the input weights)
  lpSolveAPI::set.objfn(lp, c(Y[o, ], rep(0, n_in)))

  # normalisation: v'x_o = 1
  lpSolveAPI::add.constraint(lp, c(rep(0, n_out), X[o, ]), "=", 1)

  # u'y_j - v'x_j <= 0 for every unit j (the j = o row gives u'y_o <= 1)
  for (j in seq_len(n))
    lpSolveAPI::add.constraint(lp, c(Y[j, ], -X[j, ]), "<=", 0)

  # strictly positive weights
  lpSolveAPI::set.bounds(lp, lower = rep(epsilon, n_var))

  status <- solve(lp)
  if (status != 0L)
    warning("LP for DMU ", o, " did not solve to optimality ",
            "(lpSolveAPI status ", status, ").", call. = FALSE)

  list(objective = lpSolveAPI::get.objective(lp),
       weights   = lpSolveAPI::get.variables(lp))
}
