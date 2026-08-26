## App orchestration around icesdata SAG / advice APIs.
## Projection / regimes stay in FLBacktest / FLRebuild; stock ids in icesdata::bimSids.

#' Load sids subset, SAG series, reference points, and advice for one fishery.
#'
#' Thin wrapper: \code{icesdata::bimSids}, \code{fetchSagTs}, \code{loadSagRefpts},
#' \code{loadAdviceFlqs}. Renames FLR-style SAG columns to the names used by the
#' BIM notebooks (\code{Rec}, \code{SB}, \code{F}, \code{C}, optional \code{TB}).
loadSagBundle = function(
    fishery,
    sagYears = 2025,
    sdgYear = 2025,
    projectRoot = NULL,
    includeTB = FALSE,
    dropAssYearRows = FALSE,
    dropHomEarly = FALSE,
    requireCatches = TRUE) {

  if (!requireNamespace("icesdata", quietly = TRUE))
    stop("loadSagBundle requires package icesdata.", call. = FALSE)

  if (is.null(projectRoot) || !nzchar(projectRoot))
    projectRoot = bm_root()

  allSids = icesdata::bimSids()
  sids = allSids[allSids$fishery == fishery, , drop = FALSE]
  if (!nrow(sids))
    stop("No stocks for fishery = ", fishery, call. = FALSE)

  ts = icesdata::fetchSagTs(
    sid = sids$sid,
    sagYears = sagYears,
    includeTB = includeTB,
    dropAssYearRows = dropAssYearRows,
    requireCatches = requireCatches)

  # BIM notebooks expect Rec / SB / F / C (and TB when includeTB)
  rename = c(rec = "Rec", ssb = "SB", fbar = "F", catch = "C", stock = "TB")
  for (nm in names(rename)) {
    if (nm %in% names(ts))
      names(ts)[names(ts) == nm] = rename[[nm]]
  }

  if (isTRUE(dropHomEarly))
    ts = subset(ts, !(sid == "hom.27.2a3a4a5b6a7a-ce-k8" & year < 1985))

  paths = resiliencePaths(projectRoot)
  sdgRoot = if (dir.exists(paths$dirSDG)) paths$dirSDG else NULL

  rfpts = icesdata::loadSagRefpts(
    sid = sids$sid,
    year = sdgYear,
    root = sdgRoot)
  if ("assYear" %in% names(rfpts) && !"AssessmentYear" %in% names(rfpts))
    rfpts$AssessmentYear = rfpts$assYear

  adviceFile = if (file.exists(paths$adviceCsv)) {
    paths$adviceCsv
  } else {
    shippedAdvicePath(projectRoot)
  }
  advice = icesdata::loadAdviceFlqs(adviceFile = adviceFile)

  list(sids = sids, ts = ts, rfpts = rfpts, advice = advice)
}
