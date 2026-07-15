#' Create Equilibrium Object for Stock
#'
#' Fits a Beverton-Holt stock-recruitment relationship with Blim as an R0 prior.
#'
#' @param stk FLStock object.
#' @param blim Blim reference point (prior for virgin biomass).
#' @return FLBRP object with fitted stock-recruitment relationship.
#' @export
calcEq = function(stk, blim) {
  pars = FLPar(
    c(
      "a" = exp(mean(log(c(rec(stk)[, ssb(stk) > blim])), na.rm = TRUE)) / blim,
      "b" = blim
    )
  )
  eql(stk, prior_r0 = pars["b"], model = "bevholtSV")
}
