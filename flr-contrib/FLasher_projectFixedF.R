# Candidate contribution: fixed-F projection helpers for FLasher
#
# PR target: https://github.com/flr/FLasher
# Suggested placement: R/fwd-utils.R (or similar) documenting a thin, validated
# wrapper around fwdWindow + fwdControl + fwd.
#
# Project pattern (bimResilience):
#   projectFixedF(stk, sr, ftar, recDev, endYr)     — single stock
#   runFcstCtrl(ctrl, stks, eqs)                    — multi-stock control table
# Both reduce to: window stock → fwdControl(quant="f") → constant/tabled
# recruitment deviances → FLasher::fwd().
#
# Do not source this file from bimResilience; working copies live in
# R/macProjections.R and R/fcstCtrl.R.

#' Project an FLStock under constant Fbar and constant recruitment deviance
#'
#' Thin validated wrapper around \code{\link[FLasher]{fwdWindow}},
#' \code{\link[FLasher]{fwdControl}}, and \code{\link[FLasher]{fwd}}.
#'
#' @param object An \code{FLStock} through the last historical / advice year.
#' @param sr An \code{FLSR} (or other object accepted by \code{fwd(..., sr=)}).
#' @param ftar Scalar target Fbar applied in every projection year.
#' @param recDev Scalar recruitment deviance (passed to \code{deviances=}).
#' @param endYr Last projection year (inclusive).
#' @param ... Not used.
#'
#' @return Projected \code{FLStock}.
#'
#' @seealso \code{\link[FLasher]{fwd}}, \code{\link{fwdFromCtrl}}
#'
#' @examples
#' \dontrun{
#' fwdFixedF(stk, sr = sr, ftar = 0.2, recDev = 1, endYr = 2040)
#' }
#'
#' @export
setGeneric("fwdFixedF", function(object, sr, ftar, recDev, endYr, ...)
  standardGeneric("fwdFixedF"))

#' @rdname fwdFixedF
#' @export
setMethod("fwdFixedF",
  signature(object = "FLStock"),
  function(object, sr, ftar, recDev, endYr = 2050L, ...) {

    if (missing(sr) || is.null(sr))
      stop("sr is required (stock-recruit object for FLasher::fwd).",
           call. = FALSE)

    if (missing(ftar) || length(ftar) != 1L || !is.finite(ftar))
      stop("ftar must be a single finite numeric (target Fbar).", call. = FALSE)

    if (missing(recDev) || length(recDev) != 1L || !is.finite(recDev))
      stop("recDev must be a single finite numeric (recruitment deviance).",
           call. = FALSE)

    my <- dims(object)$maxyear
    if (!is.finite(my))
      stop("object has non-finite maxyear.", call. = FALSE)

    endYr <- as.integer(endYr)
    if (length(endYr) != 1L || !is.finite(endYr))
      stop("endYr must be a single finite year.", call. = FALSE)
    if (endYr <= my)
      stop("endYr (", endYr, ") must be greater than maxyear(object) (", my, ").",
           call. = FALSE)

    yrs <- seq.int(my + 1L, endYr)
    control <- fwdControl(
      year  = yrs,
      quant = "f",
      value = rep(ftar, length(yrs)))
    devs <- FLQuant(recDev, dimnames = list(year = ac(yrs)))

    FLasher::fwd(
      fwdWindow(object, end = max(yrs)),
      control   = control,
      sr        = sr,
      deviances = devs)
  }
)

#' Run fixed-F projections from a multi-stock control table
#'
#' Documents the bimResilience \code{runFcstCtrl} pattern as a reusable
#' FLasher utility. Each row supplies \code{sid}, \code{ftar}, \code{recDev},
#' and \code{endYr}; stocks and SR objects are looked up by \code{sid}.
#'
#' Expected \code{ctrl} columns: \code{scenario}, \code{sid}, \code{ftar},
#' \code{recDev}, \code{endYr}.
#'
#' @param ctrl Data frame of projection rows (one stock × scenario per row).
#' @param stks Named list or \code{FLStocks} of \code{FLStock} objects.
#' @param sr Named list of stock-recruit objects keyed like \code{stks}
#'   (in bimResilience these are \code{attributes(eqs[[sid]])$sr}).
#'
#' @return Named list of \code{FLStocks}, one element per unique \code{scenario}.
#'
#' @seealso \code{\link{fwdFixedF}}
#'
#' @export
fwdFromCtrl <- function(ctrl, stks, sr) {

  need <- c("scenario", "sid", "ftar", "recDev", "endYr")
  missingCols <- setdiff(need, names(ctrl))
  if (length(missingCols))
    stop("ctrl missing columns: ", paste(missingCols, collapse = ", "),
         call. = FALSE)

  if (missing(stks) || is.null(stks) || !length(stks))
    stop("stks must be a non-empty named list / FLStocks.", call. = FALSE)
  if (missing(sr) || is.null(sr) || !length(sr))
    stop("sr must be a non-empty named list of stock-recruit objects.",
         call. = FALSE)

  scenarios <- unique(as.character(ctrl$scenario))
  out <- setNames(vector("list", length(scenarios)), scenarios)

  for (sc in scenarios) {
    rows <- ctrl[ctrl$scenario == sc, , drop = FALSE]
    stocks <- vector("list", nrow(rows))
    names(stocks) <- as.character(rows$sid)

    for (i in seq_len(nrow(rows))) {
      row <- rows[i, ]
      id  <- as.character(row$sid)

      if (!id %in% names(stks))
        stop("No stock in stks for sid = ", id, ".", call. = FALSE)
      if (!id %in% names(sr) || is.null(sr[[id]]))
        stop("Missing sr for sid = ", id, ".", call. = FALSE)

      ftar   <- row$ftar
      recDev <- row$recDev
      endYr  <- row$endYr

      if (length(ftar) != 1L || !is.finite(ftar))
        stop("Non-finite or missing ftar for sid = ", id,
             ", scenario = ", sc, ".", call. = FALSE)
      if (length(recDev) != 1L || !is.finite(recDev))
        stop("Non-finite or missing recDev for sid = ", id,
             ", scenario = ", sc, ".", call. = FALSE)
      if (length(endYr) != 1L || !is.finite(endYr))
        stop("Non-finite or missing endYr for sid = ", id,
             ", scenario = ", sc, ".", call. = FALSE)

      stocks[[id]] <- fwdFixedF(
        object = stks[[id]],
        sr     = sr[[id]],
        ftar   = ftar,
        recDev = recDev,
        endYr  = as.integer(endYr))
    }
    out[[sc]] <- FLStocks(stocks)
  }
  out
}
