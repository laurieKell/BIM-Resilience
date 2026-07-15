#' Shared residual / forecast / optional plot helpers for stock-group Rmds.

#' Recruitment residual panels with regime polygons.
#'
#' @param srs Stock--recruit frame with \code{sid}, \code{year}, \code{rsd}.
#' @param rds Regime polygons with \code{sid}, \code{year}, \code{data}, \code{regime}.
#' @return A ggplot object.
#' @export
plotRecResiduals = function(srs, rds) {
  ggplot2::ggplot(srs) +
    ggplot2::facet_wrap(~sid, scale = "free", ncol = 2) +
    ggplot2::geom_polygon(
      ggplot2::aes(year, data, group = regime),
      fill = "lavender", col = "blue",
      linewidth = 0.25, alpha = 0.5,
      data = rds) +
    ggplot2::geom_line(ggplot2::aes(year, rsd), col = "grey75") +
    ggplot2::geom_point(
      ggplot2::aes(year, rsd),
      col = "grey75", fill = "grey25", shape = 21) +
    ggplot2::xlab("year") + ggplot2::ylab("Residual") +
    ggplot2::theme_bw(base_size = 12) +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = -30),
      legend.position = "bottom")
}

#' Stop unless equilibrium objects are present in the calling environment.
#'
#' @param needed Character vector of required object names.
#' @param envir Environment to check (default: parent frame).
#' @export
assertAfterEquilibrium = function(
    needed = c("stks", "eqs", "srs", "recCurrent", "rfpts", "advice"),
    envir = parent.frame()) {
  missing = needed[!vapply(needed, exists, logical(1), envir = envir, inherits = TRUE)]
  if (length(missing))
    stop("Missing after equilibrium: ", paste(missing, collapse = ", "),
         call. = FALSE)
  invisible(TRUE)
}

#' Pull named scenario stocks from \code{simTAC()} output.
#'
#' @param fcstStks Named list of scenario FLStocks.
#' @return Named list with \code{fsq}, \code{fsq75}, \code{fsq50}, \code{fmsy}, \code{rgm}.
#' @export
unpackFcstScenarios = function(fcstStks) {
  list(
    fsq   = fcstStks[["FStatus Quo"]],
    fsq75 = fcstStks[["FStatus Quo 75%"]],
    fsq50 = fcstStks[["FStatus Quo 50%"]],
    fmsy  = fcstStks[["FMSY"]],
    rgm   = fcstStks[["Regime"]]
  )
}

#' Faceted forecast catch by scenario.
#'
#' @param fct Long forecast table from \code{saveSimTacResults()}.
#' @return A ggplot object.
#' @export
plotForecastCatch = function(fct) {
  ggplot2::ggplot(fct) +
    ggplot2::geom_line(ggplot2::aes(year, Catch, col = Scenario)) +
    ggplot2::facet_wrap(~sid, scale = "free", ncol = 2) +
    ggplot2::theme(legend.position = "bottom")
}

#' Optional SSB / F / catch time-series strips (needs \code{plotTs}).
#'
#' @return Named list with \code{ssb}, \code{f}, \code{catch} plot lists.
#' @export
buildOptionalTsStrips = function(stks, eqs, rfpts) {
  if (!exists("plotTs", mode = "function", inherits = TRUE))
    stop("plotTs() is not available on the search path.", call. = FALSE)
  list(
    ssb   = plotTs(stks, "SSB",   FLCore::ssb,   sum,  "SSB Time Series",
                   n_refpts = 2, eqs = eqs, rfpts = rfpts),
    f     = plotTs(stks, "F",     FLCore::fbar,  mean, "F Time Series",
                   n_refpts = 1, eqs = eqs, rfpts = rfpts),
    catch = plotTs(stks, "Catch", FLCore::catch, sum,  "Catch Time Series",
                   n_refpts = 1, eqs = eqs, rfpts = rfpts)
  )
}

#' Optional multi-scenario projection panels per stock.
#'
#' @export
plotOptionalProjections = function(fsq, historical, fmsy, rgm, eqs,
                                   year = 2025) {
  if (!exists("projMetrics", inherits = TRUE))
    stop("projMetrics is not available on the search path.", call. = FALSE)
  if (!exists("getRefptsProj", mode = "function", inherits = TRUE))
    stop("getRefptsProj() is not available on the search path.", call. = FALSE)

  for (id in names(fsq)) {
    stks_plot = FLCore::FLStocks(
      "Status Quo" = fsq[[id]],
      "Historical" = historical[[id]],
      "Fmsy"       = fmsy[[id]],
      "Regime"     = rgm[[id]]
    )
    p = ggplotFL::plot(stks_plot, metrics = projMetrics) +
      ggplot2::geom_vline(
        ggplot2::aes(xintercept = year),
        linetype = "dashed", color = "gray50") +
      ggplot2::theme_bw() +
      ggplot2::xlab("Year") +
      ggplot2::labs(title = id) +
      ggplot2::theme(legend.position = "bottom")
    refPars = getRefptsProj(id, eqs = eqs, albRfs = NULL)
    if (!is.null(refPars))
      p = p + ggplotFL::geom_flpar(data = refPars, x = rep(year, 4))
    print(p)
  }
  invisible(NULL)
}

#' Save a group plot bundle under \code{data/om} and \code{data/plot-objects}.
#'
#' Saves as \code{\{prefix\}Plots} in \code{\{prefix\}_plot.RData} and
#' \code{\{prefix\}_plot_html.RData}.
#'
#' @param prefix File prefix (\code{"pel"}, \code{"dem"}, ...).
#' @export
saveGroupPlotBundle = function(prefix, recResiduals, forecastCatch, timeSeries,
                               dirOM, dirPlot) {
  dir.create(dirOM, recursive = TRUE, showWarnings = FALSE)
  dir.create(dirPlot, recursive = TRUE, showWarnings = FALSE)
  objName = paste0(prefix, "Plots")
  assign(objName, list(
    recResiduals  = recResiduals,
    forecastCatch = forecastCatch,
    timeSeries    = timeSeries
  ))
  save(list = objName, file = file.path(dirOM, paste0(prefix, "_plot.RData")))
  save(list = objName, file = file.path(dirPlot, paste0(prefix, "_plot_html.RData")))
  invisible(get(objName))
}
