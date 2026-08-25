#' Mackerel-specific forward projections (recruitment levels, M shock, random rec).
#'
#' These helpers operate on a single age-structured \code{FLStock} with an
#' \code{FLSR} (from \code{attributes(eq)$sr}). They complement the shared
#' pelagic control-table path in \code{buildFcstCtrl()} / \code{runFcstCtrl()}.
#'
#' @name macProjections
NULL

#' Status-quo mean Fbar over the last \code{n} years.
#' @export
fsqMean = function(stk, n = 3L) {
  if (!inherits(stk, "FLStock"))
    stop("fsqMean: 'stk' must be an FLStock.", call. = FALSE)
  n = as.integer(n)
  if (length(n) != 1L || is.na(n) || n < 1L)
    stop("fsqMean: 'n' must be a positive integer.", call. = FALSE)
  my = dims(stk)$maxyear
  yrs = ac(my - seq_len(n) + 1L)
  fb = c(fbar(stk)[, yrs])
  if (!all(is.finite(fb)))
    stop("fsqMean: non-finite Fbar in years ", paste(yrs, collapse = ", "),
         ".", call. = FALSE)
  mean(fb)
}

#' Project under fixed F and a constant recruitment deviance.
#'
#' Thin wrapper around \code{FLasher::fwd}. Prefer that generic directly when
#' building new workflows; see \code{flr-contrib/FLasher_projectFixedF.R}.
#'
#' @param stk FLStock through the advice year.
#' @param sr FLSR used by FLasher.
#' @param ftar Target Fbar (constant).
#' @param recDev Constant recruitment deviance scalar.
#' @param endYr Last projection year.
#' @return Projected FLStock.
#' @export
projectFixedF = function(stk, sr, ftar, recDev, endYr = 2050L) {
  if (!inherits(stk, "FLStock"))
    stop("projectFixedF: 'stk' must be an FLStock.", call. = FALSE)
  if (is.null(sr))
    stop("projectFixedF: 'sr' (stock--recruit) is required.", call. = FALSE)
  if (length(ftar) != 1L || !is.finite(ftar))
    stop("projectFixedF: 'ftar' must be a single finite number.", call. = FALSE)
  if (length(recDev) != 1L || !is.finite(recDev))
    stop("projectFixedF: 'recDev' must be a single finite number.", call. = FALSE)
  endYr = as.integer(endYr)
  my = dims(stk)$maxyear
  if (is.na(endYr) || endYr <= my)
    stop("projectFixedF: 'endYr' (", endYr, ") must be > stock maxyear (",
         my, ").", call. = FALSE)
  yrs = seq(my + 1L, endYr)
  control = fwdControl(
    year  = yrs,
    quant = "f",
    value = rep(ftar, length(yrs)))
  devs = FLQuant(recDev, dimnames = list(year = ac(yrs)))
  FLasher::fwd(
    fwdWindow(stk, end = max(yrs)),
    control   = control,
    sr        = sr,
    deviances = devs)
}

#' (i) Same F, different constant recruitment levels.
#'
#' @param levels Multipliers applied to \code{recBase} (e.g. 1, 0.75, 0.5).
#' @return Named list of FLStocks.
#' @export
projectRecLevels = function(stk, sr, ftar, recBase,
                            levels = c(1, 0.75, 0.5, 0.25),
                            endYr = 2050L) {
  out = lapply(levels, function(mul) {
    projectFixedF(stk, sr, ftar, recDev = recBase * mul, endYr = endYr)
  })
  names(out) = paste0("Rec x", levels)
  out
}

#' (ii) One-off natural-mortality shock, then resume baseline M.
#'
#' Multiplies \code{m} by \code{mMul} for a single year (default: first
#' projection year), then projects at fixed F with constant \code{recDev}.
#'
#' @param mMul Multiplier applied to M in the shock year (e.g. 2 = double M).
#' @param shockYear Year of the M pulse; default \code{maxyear(stk) + 1}.
#' @param label Scenario name for the shocked run.
#' @return Named list with \code{Baseline} (no M shock) and the shocked run.
#' @export
projectMShock = function(stk, sr, ftar, recDev,
                         mMul = 2,
                         shockYear = NULL,
                         endYr = 2050L,
                         label = NULL) {
  my = dims(stk)$maxyear
  if (is.null(shockYear)) shockYear = my + 1L
  if (is.null(label))
    label = paste0("M x", mMul, " in ", shockYear)

  yrs = seq(my + 1L, as.integer(endYr))
  control = fwdControl(
    year  = yrs,
    quant = "f",
    value = rep(ftar, length(yrs)))
  devs = FLQuant(recDev, dimnames = list(year = ac(yrs)))

  baseline = FLasher::fwd(
    fwdWindow(stk, end = max(yrs)),
    control   = control,
    sr        = sr,
    deviances = devs)

  stkShock = fwdWindow(stk, end = max(yrs))
  m(stkShock)[, ac(shockYear)] = m(stkShock)[, ac(shockYear)] * mMul
  shocked = FLasher::fwd(
    stkShock,
    control   = control,
    sr        = sr,
    deviances = devs)

  setNames(list(baseline, shocked), c("Baseline", label))
}

#' (iii) Random year-to-year recruitment around a mean deviance.
#'
#' Draws log-normal multipliers with \code{sd = recSd} on the log scale
#' (mean on the log scale bias-corrected so \code{E[dev] = recMean}).
#' Each iteration is projected separately and returned as a list of FLStocks.
#'
#' @param niter Number of stochastic iterations.
#' @param seed RNG seed for reproducibility.
#' @return Named list of FLStocks (\code{iter1}, \code{iter2}, ...).
#' @export
projectRandomRec = function(stk, sr, ftar, recMean, recSd,
                            endYr = 2050L,
                            niter = 50L,
                            seed = 1L) {
  yrs = seq(dims(stk)$maxyear + 1L, as.integer(endYr))
  control = fwdControl(
    year  = yrs,
    quant = "f",
    value = rep(ftar, length(yrs)))

  set.seed(seed)
  out = vector("list", niter)
  names(out) = paste0("iter", seq_len(niter))

  for (i in seq_len(niter)) {
    # Bias-corrected lognormal: E[exp(X)] = recMean
    logDev = stats::rnorm(
      length(yrs),
      mean = log(recMean) - 0.5 * recSd^2,
      sd   = recSd)
    devs = FLQuant(exp(logDev), dimnames = list(year = ac(yrs)))
    out[[i]] = FLasher::fwd(
      fwdWindow(stk, end = max(yrs)),
      control   = control,
      sr        = sr,
      deviances = devs)
  }
  out
}

#' Long table of Catch / SSB / F / Recruits from a named list of FLStocks.
#'
#' @param stks Named list of FLStock (one scenario or iteration each).
#' @export
macProjToDf = function(stks, scenarioCol = "Scenario") {
  ldply(names(stks), function(sc) {
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
  Catch    = "Catch (t)",
  SSB      = "SSB (t)",
  Recruits = "Recruits",
  F        = "Fbar")

#' Long (melted) metric table for Catch / SSB / Recruits / F.
#' @export
macProjLong = function(df, idCols = NULL) {
  mets = .macMetricLevels
  if (is.null(idCols))
    idCols = setdiff(names(df), mets)
  d = reshape::melt(df, id.vars = idCols, measure.vars = mets)
  d$variable = factor(as.character(d$variable), levels = mets)
  d
}

#' Deterministic scenario lines: Catch, SSB, Recruits, F (2×2).
#'
#' @param df Output of [macProjToDf()] with a \code{Scenario} column.
#' @param vline Optional vertical reference year (e.g. M-shock year).
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

#' Stochastic summary bands: Catch, SSB, Recruits, F (2×2).
#'
#' @param df Output of [macProjToDf()] with an \code{iter} column.
#' @param exIter Example iteration to overlay (default \code{"iter1"}).
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
