#' Build BIM scenario control table (app-specific labels).
#'
#' Assembles the resilience report's named scenarios. Projection itself uses
#' \code{FLBacktest::fwdFbar} via [runFcstCtrl()] — do not re-implement
#' constant-\eqn{F} \code{fwd} here.
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

  fsqNyr = as.integer(fsqNyr)
  fsqF = vapply(sid, function(id) {
    stk = stks[[id]]
    my = dims(stk)$maxyear
    yrs = ac(my - seq_len(fsqNyr) + 1L)
    fb = c(fbar(stk)[, yrs])
    if (!all(is.finite(fb)))
      stop("buildFcstCtrl: non-finite Fbar for '", id, "' in years ",
           paste(yrs, collapse = ", "), ".", call. = FALSE)
    mean(fb)
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

#' Run BIM forecast scenarios with \code{FLBacktest::fwdFbar}.
#'
#' Thin app loop over the control table from [buildFcstCtrl()]. Projection
#' logic lives in FLBacktest (same engine as blueMarine).
#'
#' @param ctrl Data frame from [buildFcstCtrl()].
#' @param stks Named FLStocks list.
#' @param eqs Named list of FLBRP objects.
#' @return Named list of FLStocks objects, one per `scenario`.
#' @export
runFcstCtrl = function(ctrl, stks, eqs) {
  if (!requireNamespace("FLBacktest", quietly = TRUE))
    stop("runFcstCtrl: install FLBacktest ",
         "(remotes::install_github(\"laurieKell/FLBacktest\")).", call. = FALSE)

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

      stk = stks[[id]]
      my = dims(stk)$maxyear
      if (row$endYr <= my)
        stop("runFcstCtrl: endYr (", row$endYr, ") must be > maxyear (",
             my, ") for '", id, "'.", call. = FALSE)
      years = (my + 1L):as.integer(row$endYr)
      stocks[[id]] = FLBacktest::fwdFbar(
        stk, eqs[[id]], f = row$ftar, years = years,
        biology = "window", residuals = row$recDev)
    }
    out[[sc]] = FLStocks(stocks)
  }
  out
}
