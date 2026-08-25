#' Build Nephrops Operating Models for Projection Scenarios
#'
#' Stage-1 helper: produces the deterministic TAC scenario operating models used
#' by `03_nephrops.Rmd`. The stage-2 MSE-with-feedback helpers live in
#' `report/wip/nephMseFeedback.R` and are not sourced here.
#'
#' @param bds Named list of JABBA outputs containing a `biodyn` object per stock.
#' @param advice Optional named list of advice catch FLQuants per stock.
#' @param sqYears Numeric vector of historical years used for status quo harvest.
#' @param projectionYears Numeric vector of projection years.
#' @param yrs Years to bridge with advice catches before projecting.
#' @param endYear Numeric final year to window stock and catch slots to.
#' @param processErrorSd Numeric SD for process error generation.
#' @param processErrorB Numeric autocorrelation parameter for process error.
#'
#' @return Named list of `biodyns` objects with `FStatus Quo`, `FStatus Quo 75%`,
#'   `FStatus Quo 50%`, `Fmsy`, and `PE` scenarios.
#' @export
buildNephOps <- function(bds,
                         advice          = NULL,
                         sqYears         = 2022:2024,
                         projectionYears = 2027:2040,
                         yrs             =ac(max(sqYears):min(projectionYears-1)),
                         endYear         = max(projectionYears)+1,
                         processErrorSd  = 0.15,
                         processErrorB   = 0.3) {
  if (!length(bds))
    stop("buildNephOps: 'bds' is empty.", call. = FALSE)
  if (!requireNamespace("mpb", quietly = TRUE))
    stop("buildNephOps: package 'mpb' is required.", call. = FALSE)

  stockIds = names(bds)
  if (is.null(stockIds) || any(!nzchar(stockIds)))
    stop("buildNephOps: 'bds' must be a named list of biodyn objects.",
         call. = FALSE)

  rtn = list()
  for (id in stockIds) {
    if (is.null(bds[[id]]))
      stop("buildNephOps: missing biodyn object for stock: ", id, call. = FALSE)

    bd = bds[[id]]
    bd@stock = window(stock(bd), end = endYear)
    bd@catch = window(catch(bd), end = endYear)
    range(bd) = unlist(dims(stock(bd))[c("minyear", "maxyear")])

    if (!is.null(advice) && !is.null(advice[[id]])) {
      bd = tryCatch(
        mpb::fwd(bd, catch = advice[[id]][, yrs]),
        error = function(e)
          stop("buildNephOps: advice bridge failed for '", id, "': ",
               conditionMessage(e), call. = FALSE)
      )
    }

    hSq = mean(c(harvest(bd)[, ac(sqYears)]))
    if (!is.finite(hSq))
      stop("buildNephOps: non-finite status-quo harvest for '", id,
           "' in years ", paste(sqYears, collapse = ", "), ".", call. = FALSE)
    fmsy = tryCatch(
      refpts(bd)["fmsy", drop = TRUE],
      error = function(e)
        stop("buildNephOps: refpts fmsy missing for '", id, "': ",
             conditionMessage(e), call. = FALSE)
    )
    if (!is.finite(fmsy))
      stop("buildNephOps: non-finite fmsy for '", id, "'.", call. = FALSE)

    hSqQ = as.FLQuant(hSq, dimnames = list(year = projectionYears))
    pe1 = FLQuant(1, dimnames = dimnames(bd@stock))
    pe75 = FLQuant(0.75, dimnames = dimnames(bd@stock))
    pe50 = FLQuant(0.50, dimnames = dimnames(bd@stock))

    runFwd = function(label, harvest, pe = NULL) {
      tryCatch(
        if (is.null(pe)) mpb::fwd(bd, harvest = harvest)
        else mpb::fwd(bd, harvest = harvest, pe = pe),
        error = function(e)
          stop("buildNephOps: mpb::fwd failed for '", id, "' / ", label,
               ": ", conditionMessage(e), call. = FALSE)
      )
    }

    bdSQ = runFwd("FStatus Quo", hSqQ, pe1)
    bdSQ75 = runFwd("FStatus Quo 75%", hSqQ, pe75)
    bdSQ50 = runFwd("FStatus Quo 50%", hSqQ, pe50)
    bdFmsy = runFwd(
      "Fmsy",
      FLQuant(fmsy, dimnames = list(year = projectionYears))
    )

    processError = rlnoise(
      1,
      harvest(bdFmsy)[, ac(projectionYears)],
      processErrorSd,
      b = processErrorB
    )

    bdPe = runFwd(
      "PE",
      FLQuant(fmsy, dimnames = list(year = projectionYears)),
      processError
    )

    rtn[[id]] = list(
      "FStatus Quo" = bdSQ,
      "FStatus Quo 75%" = bdSQ75,
      "FStatus Quo 50%" = bdSQ50,
      "Fmsy" = bdFmsy,
      "PE" = bdPe
    )
  }

  names(rtn) = stockIds
  rtn
}
