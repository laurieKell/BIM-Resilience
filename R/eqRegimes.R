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
  if (!length(sid))
    stop("calcEqAndRegimes: 'sid' is empty.", call. = FALSE)
  missStk = setdiff(sid, names(stks))
  if (length(missStk))
    stop("calcEqAndRegimes: stocks missing: ",
         paste(missStk, collapse = ", "), ".", call. = FALSE)
  if (!all(c("sid", "Blim") %in% names(rfpts)))
    stop("calcEqAndRegimes: 'rfpts' must have columns sid and Blim.",
         call. = FALSE)

  eqs = plyr::mlply(sid, function(id) {
    blim = rfpts[rfpts$sid == id, "Blim"]
    if (length(blim) != 1L || !is.finite(blim))
      stop("calcEqAndRegimes: need one finite Blim for '", id, "'.",
           call. = FALSE)
    tryCatch(
      calcEq(stk = FLCore::window(stks[[id]], end = endHist), blim = blim),
      error = function(e)
        stop("calcEqAndRegimes: calcEq failed for '", id, "': ",
             conditionMessage(e), call. = FALSE)
    )
  })
  names(eqs) = sid

  rds = plyr::ldply(sid, function(id) {
    sr = attributes(eqs[[id]])$sr
    if (is.null(sr))
      stop("calcEqAndRegimes: no SRR on equilibrium for '", id, "'.",
           call. = FALSE)
    if (!requireNamespace("FLRebuild", quietly = TRUE))
      stop("calcEqAndRegimes: package FLRebuild is required for rod().",
           call. = FALSE)
    cbind(sid = id, rod(residuals(sr)))
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
