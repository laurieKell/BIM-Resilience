#' Mackerel illustration scenarios on top of \code{FLBacktest::fwdFbar}.
#'
#' Prefer calling \code{fwdFbar} directly in new notebooks. These thin wrappers
#' only encode the three beamer “what-if” layouts (rec levels, M pulse,
#' random recruitment). Metric tables use FLCore \code{model.frame(FLQuants)}.
#'
#' @name macProjections
NULL

#' Same F, different constant recruitment levels (via \code{fwdFbar}).
#'
#' @param stk FLStock through the advice year.
#' @param eql FLBRP with stock–recruit (same object passed to \code{fwdFbar}).
#' @param ftar Target Fbar.
#' @param recBase Baseline multiplicative residual.
#' @param levels Multipliers applied to \code{recBase}.
#' @param endYr Last projection year.
#' @return Named list of FLStocks.
#' @export
projectRecLevels = function(stk, eql, ftar, recBase,
                            levels = c(1, 0.75, 0.5, 0.25),
                            endYr = 2050L) {
  if (!requireNamespace("FLBacktest", quietly = TRUE))
    stop("Install FLBacktest.", call. = FALSE)
  years = (dims(stk)$maxyear + 1L):as.integer(endYr)
  out = lapply(levels, function(mul) {
    FLBacktest::fwdFbar(
      stk, eql, f = ftar, years = years, biology = "window",
      residuals = recBase * mul)
  })
  names(out) = paste0("Rec x", levels)
  out
}

#' One-off natural-mortality shock, then resume baseline M.
#'
#' @param mMul Multiplier applied to M in the shock year.
#' @param shockYear Year of the M pulse; default first projection year.
#' @param label Scenario name for the shocked run.
#' @inheritParams projectRecLevels
#' @return Named list with \code{Baseline} and the shocked run.
#' @export
projectMShock = function(stk, eql, ftar, recDev,
                         mMul = 2,
                         shockYear = NULL,
                         endYr = 2050L,
                         label = NULL) {
  if (!requireNamespace("FLBacktest", quietly = TRUE))
    stop("Install FLBacktest.", call. = FALSE)
  my = dims(stk)$maxyear
  if (is.null(shockYear)) shockYear = my + 1L
  if (is.null(label))
    label = paste0("M x", mMul, " in ", shockYear)
  years = (my + 1L):as.integer(endYr)

  baseline = FLBacktest::fwdFbar(
    stk, eql, f = ftar, years = years, biology = "window",
    residuals = recDev)

  stkShock = FLCore::fwdWindow(stk, end = max(years))
  m(stkShock)[, ac(shockYear)] = m(stkShock)[, ac(shockYear)] * mMul
  shocked = FLBacktest::fwdFbar(
    stkShock, eql, f = ftar, years = years, biology = "window",
    residuals = recDev)

  setNames(list(baseline, shocked), c("Baseline", label))
}

#' Random year-to-year recruitment around a mean deviance.
#'
#' @param recMean Mean multiplicative residual.
#' @param recSd SD on the log scale (bias-corrected so \code{E[dev] = recMean}).
#' @param niter Number of iterations.
#' @param seed RNG seed.
#' @inheritParams projectRecLevels
#' @return Named list of FLStocks.
#' @export
projectRandomRec = function(stk, eql, ftar, recMean, recSd,
                            endYr = 2050L,
                            niter = 50L,
                            seed = 1L) {
  if (!requireNamespace("FLBacktest", quietly = TRUE))
    stop("Install FLBacktest.", call. = FALSE)
  years = (dims(stk)$maxyear + 1L):as.integer(endYr)
  set.seed(seed)
  out = vector("list", niter)
  names(out) = paste0("iter", seq_len(niter))
  for (i in seq_len(niter)) {
    logDev = stats::rnorm(
      length(years),
      mean = log(recMean) - 0.5 * recSd^2,
      sd = recSd)
    out[[i]] = FLBacktest::fwdFbar(
      stk, eql, f = ftar, years = years, biology = "window",
      residuals = exp(logDev))
  }
  out
}

#' Long table of Catch / SSB / F / Recruits from a named list of FLStocks.
#'
#' Thin convenience around \code{model.frame(FLQuants(...))}.
#' @export
macProjToDf = function(stks, scenarioCol = "Scenario") {
  plyr::ldply(names(stks), function(sc) {
    x = stks[[sc]]
    df = model.frame(
      FLQuants(
        x,
        Catch    = FLCore::catch,
        SSB      = FLCore::ssb,
        F        = FLCore::fbar,
        Recruits = FLCore::rec),
      drop = TRUE)
    cbind(setNames(data.frame(sc, stringsAsFactors = FALSE), scenarioCol), df)
  })
}

.macMetricLevels = c("Catch", "SSB", "Recruits", "F")
.macMetricLabs = c(
  Catch = "Catch (t)", SSB = "SSB (t)", Recruits = "Recruits", F = "Fbar")

#' Melt Catch/SSB/Recruits/F for faceted plots (report glue).
#' @export
macProjLong = function(df, idCols = NULL) {
  mets = .macMetricLevels
  if (is.null(idCols))
    idCols = setdiff(names(df), mets)
  d = reshape::melt(df, id.vars = idCols, measure.vars = mets)
  d$variable = factor(as.character(d$variable), levels = mets)
  d
}

#' Deterministic scenario lines (beamer / report panels).
#' @export
plotMacMetrics = function(df, title, subtitle = NULL, vline = NULL) {
  d = macProjLong(df)
  p = ggplot2::ggplot(
    d, ggplot2::aes(.data$year, .data$value, colour = .data$Scenario)) +
    ggplot2::geom_line(linewidth = 0.65) +
    ggplot2::facet_wrap(
      ~variable, scales = "free_y", ncol = 2,
      labeller = ggplot2::as_labeller(.macMetricLabs)) +
    ggplot2::labs(title = title, subtitle = subtitle, x = "Year", y = NULL) +
    ggplot2::theme_bw() +
    ggplot2::theme(legend.position = "bottom")
  if (!is.null(vline))
    p = p + ggplot2::geom_vline(
      xintercept = vline, linetype = 3, colour = "grey50")
  p
}

#' Stochastic summary bands (beamer / report panels).
#' @export
plotMacMetricsStochastic = function(df, title, subtitle = NULL,
                                    exIter = "iter1", probs = c(0.05, 0.95)) {
  d = macProjLong(df)
  summ = plyr::ddply(d, c("year", "variable"), function(x) {
    data.frame(
      med = stats::median(x$value),
      lo  = as.numeric(stats::quantile(x$value, probs[1])),
      hi  = as.numeric(stats::quantile(x$value, probs[2])))
  })
  ex = d[d$iter == exIter, , drop = FALSE]
  ggplot2::ggplot(summ, ggplot2::aes(.data$year)) +
    ggplot2::geom_ribbon(
      ggplot2::aes(ymin = .data$lo, ymax = .data$hi),
      fill = "steelblue", alpha = 0.25) +
    ggplot2::geom_line(
      ggplot2::aes(y = .data$med), colour = "steelblue", linewidth = 0.85) +
    ggplot2::geom_line(
      data = ex, ggplot2::aes(y = .data$value),
      colour = "black", linewidth = 0.45) +
    ggplot2::facet_wrap(
      ~variable, scales = "free_y", ncol = 2,
      labeller = ggplot2::as_labeller(.macMetricLabs)) +
    ggplot2::labs(title = title, subtitle = subtitle, x = "Year", y = NULL) +
    ggplot2::theme_bw()
}
