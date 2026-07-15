#' Simulate future TAC scenarios.
#'
#' Uses \code{buildFcstCtrl} / \code{runFcstCtrl}. Pass the returned
#' \code{fcstStks} to \code{saveSimTacResults()} to build \code{fct} and write files.
#'
#' @param stks Updated FLStocks (through advice year).
#' @param sid Stock ids.
#' @param eqs Named list of FLBRP from \code{calcEq}.
#' @param srs Stock--recruit residual frame (for recent recruitment multipliers).
#' @param recCurrent Current-regime multipliers (\code{sid}, \code{regime}).
#' @param rfpts Reference points with \code{FMSY} and \code{MSYBtrigger}.
#' @param endYr Last projection year.
#' @return List with \code{fcstCtrl}, \code{fcstStks}, \code{recentDev}.
#' @export
simTAC <- function(stks,
                   sid,
                   eqs,
                   srs,
                   recCurrent,
                   rfpts,
                   endYr = 2050L) {
  recentDev <- dlply(srs, .(sid), with, exp(mean(tail(rsd, 4))))
  fcstCtrl  <- buildFcstCtrl(sid, stks, recentDev, recCurrent, rfpts, endYr = endYr)
  fcstStks  <- runFcstCtrl(fcstCtrl, stks, eqs)

  list(
    fcstCtrl  = fcstCtrl,
    fcstStks  = fcstStks,
    recentDev = recentDev
  )
}

#' Build forecast table and write TAC artefacts from \code{simTAC()} output.
#'
#' Turns scenario \code{FLStocks} into a long \code{fct} frame, saves
#' \code{\{prefix\}-fct.RData}, and writes \code{csv/\{prefix\}-f.csv}.
#'
#' @param fcstStks Named list of FLStocks by scenario (from \code{simTAC()}).
#' @param rfpts Reference points with \code{sid} and \code{MSYBtrigger}.
#' @param ctcAdvice Advice catch FLQuants (saved with \code{fct}).
#' @param dirTAC Output directory for TAC artefacts.
#' @param prefix File prefix (\code{"pel"}, \code{"dem"}, ...).
#' @param minYear First year in TAC CSV (default \code{2021}).
#' @return List with \code{fct} and \code{tacCsv}.
#' @export
saveSimTacResults <- function(fcstStks,
                              rfpts,
                              ctcAdvice,
                              dirTAC,
                              prefix,
                              minYear = 2021L) {
  fct <- ldply(names(fcstStks), function(sc) {
    ts <- ldply(fcstStks[[sc]], function(x) {
      model.frame(
        FLQuants(x,
                 Catch    = FLCore::catch,
                 SSB      = FLCore::ssb,
                 F        = FLCore::fbar,
                 Recruits = FLCore::rec),
        drop = TRUE)
    }, .id = "sid")
    cbind(Scenario = sc, ts)
  })

  dir.create(dirTAC, recursive = TRUE, showWarnings = FALSE)
  save(fct, rfpts, ctcAdvice,
       file = file.path(dirTAC, paste0(prefix, "-fct.RData")))

  tacCsvDir <- file.path(dirTAC, "csv")
  dir.create(tacCsvDir, recursive = TRUE, showWarnings = FALSE)
  tacCsv <- buildForecastTacCsv(
    fct = fct,
    triggerBySid = subset(
      rfpts,
      sid %in% unique(as.character(fct$sid))
    )[, c("sid", "MSYBtrigger")],
    triggerCol = "MSYBtrigger",
    minYear = minYear
  )
  write.csv(tacCsv,
            file = file.path(tacCsvDir, paste0(prefix, "-f.csv")),
            row.names = FALSE)

  list(fct = fct, tacCsv = tacCsv)
}
