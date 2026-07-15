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
  stockIds = names(bds)

  rtn=list()
  for (id in stockIds) {
    if (is.null(bds[[id]])) {
      stop(paste("Missing biodyn object for stock:", id))
    }

    bd       = bds[[id]]
    bd@stock = window(stock(bd), end = endYear)
    bd@catch = window(catch(bd), end = endYear)
    range(bd)= unlist(dims(stock(bd))[c("minyear", "maxyear")])
    
    if (!is.null(advice))
      if (!is.null(advice[[id]]))
         bd  =mpb::fwd(bd,catch=advice[[id]][,yrs])
      
    bdSQ = mpb::fwd(
      bd,
      harvest = as.FLQuant(
        mean(harvest(bd)[, ac(sqYears)]),
        dimnames = list(year = projectionYears)),
    
      pe=FLQuant(1,dimnames=dimnames(bd@stock)))

    
    bdSQ75 = mpb::fwd(
      bd,
      harvest = as.FLQuant(
        mean(harvest(bd)[, ac(sqYears)]),
        dimnames = list(year = projectionYears)),
      
      pe=FLQuant(0.75,dimnames=dimnames(bd@stock)))
    
    bdSQ50 = mpb::fwd(
      bd,
      harvest = as.FLQuant(
        mean(harvest(bd)[, ac(sqYears)]),
        dimnames = list(year = projectionYears)),
      
      pe=FLQuant(0.50,dimnames=dimnames(bd@stock)))
    
    bdFmsy = mpb::fwd(
      bd,
      harvest = FLQuant(
        refpts(bd)["fmsy", drop = TRUE],
        dimnames = list(year = projectionYears)
      )
    )

    processError = rlnoise(
      1,
      harvest(bdFmsy)[, ac(projectionYears)],
      processErrorSd,
      b = processErrorB
    )

    bdPe = mpb::fwd(
      bd,
      harvest = FLQuant(
        refpts(bd)["fmsy", drop = TRUE],
        dimnames = list(year = projectionYears)
      ),
      pe = processError
    )

    rtn[[id]]=list("FStatus Quo"     = bdSQ,
                   "FStatus Quo 75%" = bdSQ75,
                   "FStatus Quo 50%" = bdSQ50, 
                   "Fmsy" = bdFmsy, 
                   "PE"   = bdPe)
    }

  names(rtn)=stockIds
  rtn}
