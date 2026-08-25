#' Build forecast control table for FLasher::fwd
#'
#' One row per stock x scenario. Columns `ftar` and `recDev` are the values
#' passed to `fwdControl()` and `deviances=` in `FLasher::fwd()`.
#'
#' @param sid Character vector of stock ids.
#' @param stks Named FLStocks list.
#' @param recentDev Named list of recent recruitment multipliers by stock.
#' @param recCurrent Data frame with columns `sid` and `regime`.
#' @param rfpts Reference-point data frame with columns `sid` and `FMSY`.
#' @param endYr Last projection year (default 2050).
#' @param fsqNyr Number of years for status-quo F (default 3).
#' @param macRecDev Default recruitment deviation for mackerel when absent.
#' @return Data frame with columns `scenario`, `sid`, `ftar`, `recDev`, `endYr`.
#' @export
buildFcstCtrl = function(sid,
                         stks,
                         recentDev,
                         recCurrent,
                         rfpts,
                         endYr = 2050,
                         fsqNyr = 3,
                         macRecDev = exp(-0.671)) {
  scenarios = data.frame(
    scenario = c("FStatus Quo", "FStatus Quo 75%", "FStatus Quo 50%", "FMSY", "Regime"),
    ftarRef = c("fsq", "fsq", "fsq", "FMSY", "FMSY"),
    recMul = c(1, 0.75, 0.5, 1, NA_real_),
    stringsAsFactors = FALSE
  )

  ctrl = merge(
    expand.grid(sid = sid, scenario = scenarios$scenario, stringsAsFactors = FALSE),
    scenarios,
    by = "scenario"
  )
  ctrl = merge(ctrl, rfpts[, c("sid", "FMSY"), drop = FALSE], by = "sid", all.x = TRUE)
  ctrl = merge(ctrl, recCurrent[, c("sid", "regime"), drop = FALSE], by = "sid", all.x = TRUE)
  ctrl$endYr = endYr

  defaultRec = vapply(sid, function(id) {
    if (id %in% names(recentDev)) {
      unlist(recentDev[[id]])
    } else if (identical(id, "mac.27.nea")) {
      macRecDev
    } else {
      1
    }
  }, numeric(1))
  names(defaultRec) = sid
  ctrl$recentRec = defaultRec[ctrl$sid]

  ctrl$recDev = ifelse(is.na(ctrl$recMul), ctrl$regime, ctrl$recentRec * ctrl$recMul)

  missStk = setdiff(sid, names(stks))
  if (length(missStk))
    stop("buildFcstCtrl: stocks missing from 'stks': ",
         paste(missStk, collapse = ", "), ".", call. = FALSE)

  fsqF = vapply(sid, function(id) {
    tryCatch(
      fsqMean(stks[[id]], n = as.integer(fsqNyr)),
      error = function(e)
        stop("buildFcstCtrl: status-quo F failed for '", id, "': ",
             conditionMessage(e), call. = FALSE)
    )
  }, numeric(1))
  names(fsqF) = sid

  ctrl$ftar = ifelse(ctrl$ftarRef == "FMSY", ctrl$FMSY, fsqF[ctrl$sid])
  badFtar = !is.finite(ctrl$ftar)
  if (any(badFtar))
    stop("buildFcstCtrl: non-finite ftar for ",
         paste(unique(ctrl$sid[badFtar]), collapse = ", "),
         " (check FMSY in rfpts / Fbar history).", call. = FALSE)
  badRec = !is.finite(ctrl$recDev)
  if (any(badRec))
    stop("buildFcstCtrl: non-finite recDev for ",
         paste(unique(paste(ctrl$sid[badRec], ctrl$scenario[badRec], sep = "/")),
               collapse = ", "),
         " (check residuals / regime).", call. = FALSE)
  ctrl[, c("scenario", "sid", "ftar", "recDev", "endYr"), drop = FALSE]
}

#' Run forward projections from a forecast control table
#'
#' Uses \code{FLasher::fwd} per stock/scenario. Stops on the first missing
#' stock, equilibrium, SRR, or non-finite control value.
#'
#' @param ctrl Data frame from [buildFcstCtrl()].
#' @param stks Named FLStocks list.
#' @param eqs Named list of FLBRP objects (SRR taken from `attributes(eqs[[sid]])$sr`).
#' @return Named list of FLStocks objects, one per `scenario`.
#' @export
runFcstCtrl = function(ctrl, stks, eqs) {
  need = c("scenario", "sid", "ftar", "recDev", "endYr")
  miss = setdiff(need, names(ctrl))
  if (length(miss))
    stop("runFcstCtrl: 'ctrl' missing columns: ",
         paste(miss, collapse = ", "), ".", call. = FALSE)

  scenarios = unique(ctrl$scenario)
  out = setNames(vector("list", length(scenarios)), scenarios)

  for (sc in scenarios) {
    rows = ctrl[ctrl$scenario == sc, , drop = FALSE]
    stocks = vector("list", nrow(rows))
    names(stocks) = rows$sid

    for (i in seq_len(nrow(rows))) {
      row = rows[i, ]
      id = as.character(row$sid)
      if (is.null(stks[[id]]))
        stop("runFcstCtrl: no stock '", id, "' in scenario '", sc, "'.",
             call. = FALSE)
      if (is.null(eqs[[id]]))
        stop("runFcstCtrl: no equilibrium for '", id, "'.", call. = FALSE)
      sr = attributes(eqs[[id]])$sr
      if (is.null(sr))
        stop("runFcstCtrl: attributes(eqs[['", id, "']])$sr is NULL.",
             call. = FALSE)
      if (!is.finite(row$ftar) || !is.finite(row$recDev))
        stop("runFcstCtrl: non-finite ftar/recDev for '", id,
             "' in scenario '", sc, "'.", call. = FALSE)

      stk = stks[[id]]
      my = dims(stk)$maxyear
      if (row$endYr <= my)
        stop("runFcstCtrl: endYr (", row$endYr, ") must be > maxyear (",
             my, ") for '", id, "'.", call. = FALSE)
      yrs = ac((my + 1):row$endYr)
      control = fwdControl(
        year = as.numeric(yrs),
        quant = "f",
        value = rep(row$ftar, length(yrs))
      )
      devs = FLQuant(row$recDev, dimnames = list(year = yrs))
      stocks[[id]] = tryCatch(
        FLasher::fwd(
          fwdWindow(stk, end = max(an(yrs))),
          control = control,
          sr = sr,
          deviances = devs
        ),
        error = function(e)
          stop("runFcstCtrl: FLasher::fwd failed for '", id,
               "' / '", sc, "': ", conditionMessage(e), call. = FALSE)
      )
    }
    out[[sc]] = FLStocks(stocks)
  }
  out
}
