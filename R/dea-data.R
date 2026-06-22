#' Create a DEA data object
#'
#' Builds a validated \code{dea_data} object from a data frame, classifying
#' columns into inputs and outputs. By default columns are recognised by an
#' \code{i_} prefix (inputs) and an \code{o_} prefix (outputs); the prefixes are
#' stripped from the stored names for display. Columns can also be selected
#' explicitly via \code{inputs}/\code{outputs}, which overrides the prefixes.
#' Any remaining column is treated as metadata; a non-numeric one (or an
#' explicit \code{id}) supplies the DMU labels.
#'
#' @param data A data frame (or object coercible to one) with named columns:
#'   at least one input column and one output column.
#' @param inputs,outputs Optional column selectors (character names or integer
#'   positions). When supplied they take precedence over the \code{i_}/\code{o_}
#'   prefixes. A column may not be assigned to both.
#' @param id Optional single column (name or position) holding DMU labels. If
#'   \code{NULL}, the first unclassified \emph{non-numeric} column is used,
#'   falling back to the row names. Numeric id columns (e.g. integer DMU codes)
#'   are \emph{not} auto-detected, because they cannot be told apart from an
#'   input or output that lacks an \code{i_}/\code{o_} prefix; name such a
#'   column here explicitly.
#'
#' @return An object of class \code{dea_data}: a list with components
#'   \describe{
#'     \item{\code{X}}{numeric matrix of inputs (one row per DMU).}
#'     \item{\code{Y}}{numeric matrix of outputs (one row per DMU).}
#'     \item{\code{labels}}{character vector of DMU labels.}
#'   }
#'
#' @examples
#' df <- data.frame(
#'   city  = c("A", "B", "C"),
#'   i_lab = c(10, 12, 9),
#'   i_cap = c(5, 6, 4),
#'   o_gdp = c(100, 130, 90)
#' )
#' dea_data(df)
#'
#' # explicit selection, no prefixes needed:
#' df2 <- setNames(df, c("city", "lab", "cap", "gdp"))
#' dea_data(df2, inputs = c("lab", "cap"), outputs = "gdp", id = "city")
#'
#' # numeric DMU id codes must be named explicitly:
#' df3 <- data.frame(dmu = 1001:1003, i_x = c(2, 3, 4), o_y = c(1, 2, 2))
#' dea_data(df3, id = "dmu")
#'
#' @seealso \code{\link{compute_efficiency}}, \code{\link{as_dea_data}}
#' @export
dea_data <- function(data, inputs = NULL, outputs = NULL, id = NULL) {

  data <- as.data.frame(data, stringsAsFactors = FALSE)
  nms  <- names(data)

  if (ncol(data) < 2L)
    stop("`data` must have at least two columns (one input, one output).",
         call. = FALSE)
  if (nrow(data) < 1L)
    stop("`data` has no rows.", call. = FALSE)
  if (is.null(nms) || any(nms == "") || anyDuplicated(nms))
    stop("`data` must have unique, non-empty column names.", call. = FALSE)

  in_cols  <- .resolve_cols(inputs,  "^i_", nms, data, "inputs")
  out_cols <- .resolve_cols(outputs, "^o_", nms, data, "outputs")

  if (!length(in_cols))
    stop("No input columns found. Prefix inputs with 'i_' or pass `inputs=`.",
         call. = FALSE)
  if (!length(out_cols))
    stop("No output columns found. Prefix outputs with 'o_' or pass `outputs=`.",
         call. = FALSE)

  dup <- intersect(in_cols, out_cols)
  if (length(dup))
    stop("Column(s) assigned to both inputs and outputs: ", toString(dup), ".",
         call. = FALSE)

  io_cols <- c(in_cols, out_cols)
  is_num  <- vapply(data[io_cols], is.numeric, logical(1L))
  if (!all(is_num))
    stop("Input/output columns must be numeric; these are not: ",
         toString(io_cols[!is_num]), ".", call. = FALSE)

  X <- as.matrix(data[, in_cols,  drop = FALSE])
  Y <- as.matrix(data[, out_cols, drop = FALSE])

  if (!all(is.finite(X)) || !all(is.finite(Y)))
    stop("Inputs/outputs must not contain NA, NaN or infinite values.",
         call. = FALSE)
  if (any(X < 0) || any(Y < 0))
    warning("Negative values detected; standard DEA models assume ",
            "non-negative data.", call. = FALSE)

  colnames(X) <- sub("^i_", "", colnames(X), ignore.case = TRUE)
  colnames(Y) <- sub("^o_", "", colnames(Y), ignore.case = TRUE)

  # classify leftover (unprefixed) columns and resolve DMU labels
  leftover <- setdiff(nms, io_cols)
  num_left <- leftover[vapply(data[leftover], is.numeric, logical(1L))]

  lab <- .resolve_labels(id, leftover, data, nms)

  # numeric, unprefixed, and not used as the id: ambiguous -> tell the user
  # both possible fixes rather than silently dropping the column.
  num_unused <- setdiff(num_left, lab$used)
  if (length(num_unused))
    warning("Unprefixed numeric column(s) ignored: ", toString(num_unused),
            ". If they are inputs/outputs, add an 'i_'/'o_' prefix; ",
            "if one holds DMU ids, pass it via `id=`.", call. = FALSE)

  structure(list(X = X, Y = Y, labels = lab$labels), class = "dea_data")
}

#' Resolve input/output column selectors
#'
#' @param sel A selector: \code{NULL} (use the prefix), a character vector of
#'   column names, or integer positions.
#' @param prefix Regular expression matching the role prefix.
#' @param nms Column names of \code{data}.
#' @param data The data frame.
#' @param role Either \code{"inputs"} or \code{"outputs"} (used in messages).
#' @return A character vector of column names.
#' @keywords internal
#' @noRd
.resolve_cols <- function(sel, prefix, nms, data, role) {
  if (is.null(sel))
    return(grep(prefix, nms, value = TRUE, ignore.case = TRUE))
  if (is.character(sel)) {
    miss <- setdiff(sel, nms)
    if (length(miss))
      stop("`", role, "` column(s) not found: ", toString(miss), ".",
           call. = FALSE)
    return(sel)
  }
  if (is.numeric(sel)) {
    if (any(sel %% 1 != 0) || any(sel < 1L) || any(sel > ncol(data)))
      stop("`", role, "` indices must be whole numbers in 1:", ncol(data), ".",
           call. = FALSE)
    return(nms[sel])
  }
  stop("`", role, "` must be NULL, column names, or integer positions.",
       call. = FALSE)
}

#' Resolve DMU labels
#'
#' Determines the DMU labels and reports which column (if any) was consumed,
#' so the caller can warn about other unclassified columns.
#'
#' @param id Explicit id selector, or \code{NULL} to auto-detect.
#' @param leftover Character vector of unprefixed (metadata) column names.
#' @param data The data frame.
#' @param nms Column names of \code{data}.
#' @return A list with \code{labels} (character vector) and \code{used} (the
#'   name of the column used as labels, or \code{NA_character_} if the row
#'   names were used).
#' @keywords internal
#' @noRd
.resolve_labels <- function(id, leftover, data, nms) {
  # explicit id always wins (this is how a numeric id-code column is used)
  if (!is.null(id)) {
    if (length(id) != 1L)
      stop("`id` must identify a single column.", call. = FALSE)
    if (is.numeric(id)) {
      if (id %% 1 != 0 || id < 1L || id > ncol(data))
        stop("`id` index out of range.", call. = FALSE)
      id <- nms[id]
    }
    if (!id %in% nms)
      stop("`id` column not found: ", id, ".", call. = FALSE)
    return(list(labels = as.character(data[[id]]), used = id))
  }

  # auto-detect only from unambiguous (non-numeric) leftover columns
  is_num <- vapply(data[leftover], is.numeric, logical(1L))
  chr    <- leftover[!is_num]
  if (length(chr)) {
    if (length(chr) > 1L)
      message("Multiple label columns found; using '", chr[[1L]],
              "'. Pass `id=` to pick another.")
    return(list(labels = as.character(data[[chr[[1L]]]]), used = chr[[1L]]))
  }

  # nothing safe to use as a label -> fall back to row names
  list(labels = rownames(data), used = NA_character_)
}

#' Print a DEA data object
#'
#' @param x A \code{dea_data} object, as returned by \code{\link{dea_data}}.
#' @param ... Ignored.
#'
#' @return \code{x}, invisibly.
#'
#' @export
print.dea_data <- function(x, ...) {
  cat("<dea_data>\n")
  cat(sprintf("  DMUs    : %d\n", nrow(x$X)))
  cat(sprintf("  Inputs  : %d (%s)\n", ncol(x$X), toString(colnames(x$X))))
  cat(sprintf("  Outputs : %d (%s)\n", ncol(x$Y), toString(colnames(x$Y))))
  invisible(x)
}

#' Coerce to a dea_data object
#'
#' @param x A \code{dea_data} object, or a data frame passed on to
#'   \code{\link{dea_data}}.
#' @param ... Passed to \code{\link{dea_data}} when \code{x} is not already a
#'   \code{dea_data} object.
#' @return A \code{dea_data} object.
#' @examples
#' df <- data.frame(city = c("A", "B"), i_x = c(4, 7), o_y = c(5, 8))
#' d <- as_dea_data(df)   # coerces a data frame to dea_data
#' as_dea_data(d)         # already a dea_data: returned unchanged
#' @export
as_dea_data <- function(x, ...) {
  if (inherits(x, "dea_data")) x else dea_data(x, ...)
}
