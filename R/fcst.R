#' Create Equilibrium Object for Stock
#'
#' Fits a Beverton-Holt stock-recruitment relationship with Blim as an R0 prior.
#'
#' @param stk FLStock object.
#' @param blim Blim reference point (prior for virgin biomass).
#' @return FLBRP object with fitted stock-recruitment relationship.
#' @export
calcEq = function(stk, blim) {
  if (!inherits(stk, "FLStock"))
    stop("calcEq: 'stk' must be an FLStock.", call. = FALSE)
  if (length(blim) != 1L || !is.finite(blim) || blim <= 0)
    stop("calcEq: 'blim' must be a single positive finite number (got ",
         paste(blim, collapse = ", "), ").", call. = FALSE)
  above = c(ssb(stk) > blim)
  if (!any(above, na.rm = TRUE))
    stop("calcEq: no years with SSB > Blim (", blim,
         ") for stock '", name(stk), "'.", call. = FALSE)
  recAbove = c(rec(stk)[, above])
  if (!any(is.finite(recAbove) & recAbove > 0))
    stop("calcEq: no finite positive recruitment above Blim for '",
         name(stk), "'.", call. = FALSE)
  pars = FLPar(
    c(
      "a" = exp(mean(log(recAbove[is.finite(recAbove) & recAbove > 0]))) / blim,
      "b" = blim
    )
  )
  eql(stk, prior_r0 = pars["b"], model = "bevholtSV")
}
