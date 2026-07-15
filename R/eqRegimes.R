#' Equilibrium BRPs and recruitment-regime summaries for TAC scenarios.
#'
#' Requires \code{calcEq()} and \code{rod()} from FLRebuild.
#'
#' @param stks Updated \code{FLStocks}.
#' @param sid Stock ids (order used for naming).
#' @param rfpts Reference-point table with \code{sid} and \code{Blim}.
#' @param endHist Last year used when fitting \code{calcEq}.
#' @return Named list: \code{eqs}, \code{rds}, \code{srs}, \code{recRegime}, \code{recCurrent}.
#' @export
calcEqAndRegimes = function(stks, sid, rfpts, endHist = 2020) {
  eqs = plyr::mlply(sid, function(id) {
    calcEq(
      stk = FLCore::window(stks[[id]], end = endHist),
      rfpts[rfpts$sid == id, "Blim"])
  })
  names(eqs) = sid

  rds = plyr::ldply(sid, function(id) {
    cbind(sid = id, rod(residuals(attributes(eqs[[id]])$sr)))
  })

  srs = plyr::ldply(sid, function(id) {
    sr = attributes(eqs[[id]])$sr
    cbind(
      sid = id,
      model.frame(FLCore::FLQuants(
        hat = predict(sr),
        rec = FLCore::rec(sr),
        rsd = residuals(sr))))
  })

  recRegime = plyr::ddply(rds, .(sid, regime), with, {
    data.frame(data = exp(mean(data)))
  })

  recCurrent = plyr::ddply(recRegime, .(sid), with, {
    data.frame(regime = utils::tail(data, 1))
  })

  list(
    eqs = eqs,
    rds = rds,
    srs = srs,
    recRegime = recRegime,
    recCurrent = recCurrent
  )
}
