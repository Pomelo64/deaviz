#' Construct a validated DEA panel-data object
#'
#' \code{dea_panel_data()} is the panel (multi-period) counterpart of
#' \code{\link{dea_data}}: it records, once, which columns of a long-format
#' data frame identify the DMU and the period and which are the inputs and
#' outputs, validates the panel structure, and returns an object that the
#' \code{plot_panel_*} functions accept directly -- so the column mapping does
#' not have to be repeated in every call.
#'
#' Validation: \code{id} and \code{period} must each name a single column with
#' no missing values, each DMU may appear at most once per period, and all
#' input/output columns must be numeric. As in \code{\link{dea_data}}, when
#' \code{inputs}/\code{outputs} are not given, columns prefixed \code{i_} /
#' \code{o_} are detected automatically.
#'
#' @param data A data frame in long format: one row per DMU-period.
#' @param inputs,outputs Column selectors (names or integer positions) for the
#'   inputs and outputs. If \code{NULL} (default), columns prefixed
#'   \code{i_} / \code{o_} are used.
#' @param id,period Columns (name or position) identifying the DMU and the
#'   period. Defaults \code{"Label"} and \code{"Period"}.
#'
#' @return An object of class \code{dea_panel_data}: a list with the validated
#'   \code{data} plus the resolved \code{inputs}, \code{outputs}, \code{id} and
#'   \code{period} column names, the DMU \code{labels}, the sorted
#'   \code{periods}, and a \code{balanced} flag.
#'
#' @seealso \code{\link{dea_data}}, \code{\link{plot_panel_io_biplot}},
#'   \code{\link{plot_panel_io_parcoo}}
#'
#' @examples
#' pd <- dea_panel_data(taiwanese_banks, inputs = 3:5, outputs = 6:8,
#'                      id = "DMU", period = "Year")
#' pd
#'
#' @export
dea_panel_data <- function(data, inputs = NULL, outputs = NULL,
                           id = "Label", period = "Period") {
  data <- as.data.frame(data, stringsAsFactors = FALSE)
  nms  <- names(data)

  if (nrow(data) < 1L)
    stop("`data` has no rows.", call. = FALSE)
  if (is.null(nms) || any(nms == "") || anyDuplicated(nms))
    stop("`data` must have unique, non-empty column names.", call. = FALSE)

  id     <- .deaviz_col_names(id, data, "id")
  period <- .deaviz_col_names(period, data, "period")
  if (length(id) != 1L || length(period) != 1L)
    stop("`id` and `period` must each refer to a single column.", call. = FALSE)
  if (id == period)
    stop("`id` and `period` must be different columns.", call. = FALSE)

  lab <- data[[id]]
  per <- data[[period]]
  if (anyNA(lab) || anyNA(per))
    stop("`id` and `period` columns must not contain missing values.",
         call. = FALSE)
  if (anyDuplicated(paste(as.character(lab), as.character(per), sep = "\r")))
    stop("Each DMU must appear at most once per period.", call. = FALSE)

  io_pool <- setdiff(nms, c(id, period))
  in_cols  <- if (is.null(inputs))  grep("^i_", io_pool, value = TRUE)
              else .deaviz_col_names(inputs, data, "inputs")
  out_cols <- if (is.null(outputs)) grep("^o_", io_pool, value = TRUE)
              else .deaviz_col_names(outputs, data, "outputs")

  if (!length(in_cols))
    stop("No input columns found. Prefix inputs with 'i_' or pass `inputs=`.",
         call. = FALSE)
  if (!length(out_cols))
    stop("No output columns found. Prefix outputs with 'o_' or pass ",
         "`outputs=`.", call. = FALSE)
  dup <- intersect(in_cols, out_cols)
  if (length(dup))
    stop("Column(s) assigned to both inputs and outputs: ", toString(dup),
         ".", call. = FALSE)
  bad <- intersect(c(in_cols, out_cols), c(id, period))
  if (length(bad))
    stop("Column(s) used as both id/period and input/output: ",
         toString(bad), ".", call. = FALSE)
  not_num <- c(in_cols, out_cols)[!vapply(data[c(in_cols, out_cols)],
                                          is.numeric, logical(1L))]
  if (length(not_num))
    stop("Input/output column(s) must be numeric: ", toString(not_num), ".",
         call. = FALSE)

  labels   <- unique(as.character(lab))
  periods  <- sort(unique(per))
  balanced <- all(table(as.character(lab), as.character(per)) == 1L)

  structure(
    list(data = data, inputs = in_cols, outputs = out_cols,
         id = id, period = period,
         labels = labels, periods = periods, balanced = balanced),
    class = "dea_panel_data"
  )
}

#' Coerce to a DEA panel-data object
#'
#' Returns \code{x} unchanged if it already is a \code{dea_panel_data} object;
#' otherwise passes it (and \code{...}) to \code{\link{dea_panel_data}}.
#'
#' @param x A \code{dea_panel_data} object or a long-format data frame.
#' @param ... Passed to \code{\link{dea_panel_data}} when coercion is needed.
#'
#' @return A \code{dea_panel_data} object.
#'
#' @examples
#' pd <- as_dea_panel_data(taiwanese_banks, inputs = 3:5, outputs = 6:8,
#'                         id = "DMU", period = "Year")
#'
#' @export
as_dea_panel_data <- function(x, ...) {
  if (inherits(x, "dea_panel_data")) return(x)
  if (is.data.frame(x)) return(dea_panel_data(x, ...))
  stop("Cannot coerce an object of class '", paste(class(x), collapse = "/"),
       "' to dea_panel_data.", call. = FALSE)
}

#' @export
print.dea_panel_data <- function(x, ...) {
  cat("A DEA panel:", length(x$labels), "DMUs x", length(x$periods),
      "periods", if (x$balanced) "(balanced)" else "(unbalanced)", "\n")
  cat("  periods:", paste(x$periods, collapse = ", "), "\n")
  cat("  inputs: ", paste(x$inputs, collapse = ", "), "\n")
  cat("  outputs:", paste(x$outputs, collapse = ", "), "\n")
  invisible(x)
}
