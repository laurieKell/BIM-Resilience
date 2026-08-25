# Non-interactive runner for report/06_mackerel_projections.Rmd logic.
# Usage: Rscript report/run_mackerel_projections.R

suppressPackageStartupMessages({
  reportDir = "C:/active/BIM-Resilience/report"
  source(file.path(reportDir, "ensureBimResilience.R"))
  paths = setupReportPaths()
  list2env(paths, envir = environment())
  loadReportLibraries(extra = "ggplot2")
})

sid      = "mac.27.nea"
endYr    = 2050L
fsqNyr   = 3L
recLevels = c(1, 0.75, 0.5, 0.25)
mMul      = 5
shockYear = 2035L
niter     = 50L
recSd     = NULL
seed      = 1L

load(file.path(dirOM, "pel-om.RData"))

stk  = stks[[sid]]
eql  = eqs[[sid]]
my   = dims(stk)$maxyear
ftar = mean(c(fbar(stk)[, ac(my - seq_len(fsqNyr) + 1L)]))
if (!is.finite(ftar))
  stop("Non-finite status-quo F for ", sid, call. = FALSE)

srsMac = as.data.frame(srs)
srsMac = srsMac[srsMac$sid == sid, , drop = FALSE]
recBase = exp(mean(utils::tail(srsMac$rsd, 4)))
if (is.null(recSd)) recSd = stats::sd(srsMac$rsd, na.rm = TRUE)
if (is.null(shockYear)) shockYear = my + 1L
btrig = rfpts$MSYBtrigger[rfpts$sid == sid][1]

message(sprintf(
  "mac.27.nea | maxyear=%s | Fsq=%.3f | recentDev=%.3f | recSd=%.3f | M shock year=%s (x%s)",
  my, ftar, recBase, recSd, shockYear, mMul))

# (i) recruitment levels
message("Running recruitment-level projections...")
recRuns = projectRecLevels(stk, eql, ftar, recBase, levels = recLevels, endYr = endYr)
dfRec = macProjToDf(recRuns)

# (ii) M shock
message("Running M-shock projections...")
mRuns = projectMShock(stk, eql, ftar, recBase, mMul = mMul, shockYear = shockYear, endYr = endYr)
dfM = macProjToDf(mRuns)

# (iii) random recruitment
message("Running random-recruitment projections...")
stkRand = projectRandomRec(
  stk, eql, ftar, recBase, recSd,
  endYr = endYr, niter = niter, seed = seed)
dfRand = macProjToDf(stkRand, scenarioCol = "iter")
summ = plyr::ddply(dfRand, "year", function(d) {
  data.frame(
    Catch_med = median(d$Catch),
    Catch_lo  = as.numeric(stats::quantile(d$Catch, 0.05)),
    Catch_hi  = as.numeric(stats::quantile(d$Catch, 0.95)),
    SSB_med   = median(d$SSB),
    SSB_lo    = as.numeric(stats::quantile(d$SSB, 0.05)),
    SSB_hi    = as.numeric(stats::quantile(d$SSB, 0.95)),
    Rec_med   = median(d$Recruits),
    Rec_lo    = as.numeric(stats::quantile(d$Recruits, 0.05)),
    Rec_hi    = as.numeric(stats::quantile(d$Recruits, 0.95)))
})

exIter = "iter1"
dfEx = dfRand[dfRand$iter == exIter, , drop = FALSE]

ggRec = ggplot2::ggplot(dfRec, ggplot2::aes(year, Catch, colour = Scenario)) +
  ggplot2::geom_line(linewidth = 0.7) +
  ggplot2::labs(
    title = "Mackerel: catch under different recruitment levels",
    subtitle = sprintf("Fixed Fsq = %.3f; deviance = recentDev x level", ftar),
    x = "Year", y = "Catch") +
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "bottom")

ggM = ggplot2::ggplot(dfM, ggplot2::aes(year, Catch, colour = Scenario)) +
  ggplot2::geom_line(linewidth = 0.7) +
  ggplot2::geom_vline(xintercept = shockYear, linetype = 3, colour = "grey50") +
  ggplot2::labs(
    title = sprintf("Mackerel: one-off M x %s in %s", mMul, shockYear),
    subtitle = sprintf("Fixed Fsq = %.3f; recruitment deviance = %.3f", ftar, recBase),
    x = "Year", y = "Catch") +
  ggplot2::theme_bw() +
  ggplot2::theme(legend.position = "bottom")

ggRand = ggplot2::ggplot(summ, ggplot2::aes(year)) +
  ggplot2::geom_ribbon(
    ggplot2::aes(ymin = Catch_lo, ymax = Catch_hi),
    fill = "steelblue", alpha = 0.25) +
  ggplot2::geom_line(ggplot2::aes(y = Catch_med), colour = "steelblue", linewidth = 0.9) +
  ggplot2::geom_line(
    data = dfEx, ggplot2::aes(y = Catch), colour = "black", linewidth = 0.5) +
  ggplot2::labs(
    title = "Mackerel: random recruitment (example)",
    subtitle = sprintf(
      "Fixed Fsq = %.3f; %d iters; ribbon = 5-95%%; black = %s",
      ftar, niter, exIter),
    x = "Year", y = "Catch") +
  ggplot2::theme_bw()

dirMac = file.path(dirTAC, "mackerel")
dir.create(dirMac, recursive = TRUE, showWarnings = FALSE)
dir.create(dirPlot, recursive = TRUE, showWarnings = FALSE)

macProj = list(
  params = list(
    sid = sid, endYr = endYr, ftar = ftar, recBase = recBase, recSd = recSd,
    recLevels = recLevels, mMul = mMul, shockYear = shockYear,
    niter = niter, seed = seed),
  recLevels = recRuns,
  mShock    = mRuns,
  randomRec = stkRand,
  dfRec = dfRec,
  dfM   = dfM,
  dfRand = dfRand,
  summRand = summ)

save(macProj, file = file.path(dirOM, "mac-proj.RData"))
utils::write.csv(dfRec, file.path(dirMac, "mac-rec-levels.csv"), row.names = FALSE)
utils::write.csv(dfM,   file.path(dirMac, "mac-m-shock.csv"),    row.names = FALSE)
utils::write.csv(summ,  file.path(dirMac, "mac-random-rec-summary.csv"), row.names = FALSE)

ggplot2::ggsave(file.path(dirPlot, "ggMacRecLevels.png"), ggRec,  width = 8, height = 5)
ggplot2::ggsave(file.path(dirPlot, "ggMacMShock.png"),    ggM,    width = 8, height = 5)
ggplot2::ggsave(file.path(dirPlot, "ggMacRandomRec.png"), ggRand, width = 8, height = 5)

message("Done. Wrote mac-proj.RData, CSVs under data/TAC/mackerel/, and plot-objects PNGs.")
message("Beamer fig_mac_*.png are produced by report/05_figs.Rmd.")
