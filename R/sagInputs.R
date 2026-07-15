#' SAG time series, reference points, and advice helpers for stock-group Rmds.

defaultProjectRoot = function() {
  if (exists("projectRoot", inherits = TRUE) &&
      is.character(projectRoot) && length(projectRoot) == 1 && nzchar(projectRoot))
    return(projectRoot)
  if (exists("findProjectRoot", mode = "function"))
    return(findProjectRoot())
  if (exists("resiliencePaths", mode = "function"))
    return(resiliencePaths()$projectRoot)
  envRoot = Sys.getenv("RESILIENCE_ROOT", "")
  if (nzchar(envRoot))
    return(normalizePath(envRoot, winslash = "/", mustWork = TRUE))
  stop(
    "Cannot resolve project root. Set RESILIENCE_ROOT or attach bimResilience.",
    call. = FALSE
  )
}

defaultSdgRoot = function(projectRoot = defaultProjectRoot()) {
  if (exists("resiliencePaths", mode = "function"))
    return(resiliencePaths(projectRoot)$dirSDG)
  file.path(projectRoot, "data/inputs/ices/sdGraphs")
}

#' Locate a StockAssessmentGraphs CSV for an ICES year folder.
#'
#' Picks the lexicographically last \code{StockAssessmentGraphs_<digits>...csv}
#' (excludes Yieldrecruit companions). Keep one Graphs CSV per year folder.
#'
#' @param year Folder under \code{sdGraphs} (e.g. 2025).
#' @param root Path to \code{data/inputs/ices/sdGraphs}.
#' @return Full path to one CSV file, or \code{NULL} if none exists.
#' @export
findSagGraphsCsv = function(year = 2025, root = defaultSdgRoot()) {
  d = file.path(root, as.character(year))
  files = list.files(d, pattern = "^StockAssessmentGraphs_[0-9].*\\.csv$")
  if (!length(files)) return(NULL)
  file.path(d, sort(files)[length(files)])
}

#' Fetch ICES SAG reference points from the web API.
#'
#' @param sid Character vector of FishStock codes.
#' @param year Assessment year passed to \code{icesSAG::findAssessmentKey}.
#' @return Data frame with \code{sid}, \code{AssessmentYear}, \code{Blim},
#'   \code{MSYBtrigger}, \code{FMSY}, \code{Fmanagement}, \code{Fpa}.
#' @export
fetchSagRefpts = function(sid, year = 2025) {
  rows = lapply(sid, function(stock) {
    keys = icesSAG::findAssessmentKey(stock, year = year)
    if (!length(keys) || all(is.na(keys))) return(NULL)
    key = keys[[1]]
    rp = icesSAG::getFishStockReferencePoints(key)
    if (!is.data.frame(rp) || !nrow(rp)) return(NULL)
    data.frame(
      AssessmentYear = rp$AssessmentYear[[1]],
      sid            = stock,
      Blim           = rp$Blim[[1]],
      MSYBtrigger    = rp$MSYBtrigger[[1]],
      FMSY           = rp$FMSY[[1]],
      Fmanagement    = rp$Fmanagement[[1]],
      Fpa            = rp$Fpa[[1]],
      stringsAsFactors = FALSE
    )
  })
  out = do.call(rbind, rows)
  if (is.null(out) || !nrow(out))
    stop("No SAG reference points returned from the web API for year ",
         year, ".", call. = FALSE)
  rownames(out) = NULL
  out
}

#' Load ICES SAG reference points for a set of stock ids.
#'
#' Prefers a local StockAssessmentGraphs CSV when present; otherwise fetches
#' from the ICES SAG web API (\code{\link{fetchSagRefpts}}).
#'
#' @param sid Character vector of FishStock codes.
#' @param year sdGraphs year folder / assessment year for the API.
#' @param root Path to \code{sdGraphs}.
#' @return Data frame with \code{sid} and ref-point columns.
#' @export
loadSagRefpts = function(sid, year = 2025, root = defaultSdgRoot()) {
  csv = findSagGraphsCsv(year = year, root = root)
  if (!is.null(csv) && file.exists(csv)) {
    rfpts = read.csv(csv, stringsAsFactors = FALSE)
    keep = c("AssessmentYear", "FishStock", "Blim", "MSYBtrigger",
             "FMSY", "Fmanagement", "Fpa")
    missing = setdiff(keep, names(rfpts))
    if (length(missing))
      stop("SAG graphs CSV missing columns: ", paste(missing, collapse = ", "),
           call. = FALSE)
    rfpts = rfpts[, keep]
    names(rfpts)[names(rfpts) == "FishStock"] = "sid"
    rfpts = subset(rfpts, sid %in% sid)
    return(rfpts[!duplicated(rfpts$sid), ])
  }
  fetchSagRefpts(sid = sid, year = year)
}

#' Read advice.csv into an FLQuants keyed by sid.
#'
#' Prefers local \code{data/advice/advice.csv}, else the packaged copy under
#' \code{inst/extdata/advice.csv}.
#'
#' @param adviceFile Path to advice CSV (wide year columns).
#' @return \code{FLQuants} of advice catch by stock.
#' @export
loadAdviceFlqs = function(adviceFile = NULL) {
  if (is.null(adviceFile))
    adviceFile = shippedAdvicePath(defaultProjectRoot())
  advice = reshape::melt(read.csv(adviceFile, stringsAsFactors = FALSE))
  FLCore::FLQuants(plyr::dlply(advice, "sid", function(d) {
    FLCore::as.FLQuant(data.frame(
      year = FLCore::an(substr(as.character(d$variable), 2, 5)),
      data = d$value))
  }))
}

#' Pull ICES SAG summary tables and standardise column names.
#'
#' Uses named \code{icesSAG::getSAG} fields (not positional indices).
#'
#' @param sid Stock ids.
#' @param sagYears Assessment years to try (newest kept when catches present).
#' @param includeTB Include total biomass (\code{TBiomass}).
#' @param dropAssYearRows Drop rows where data year equals assessment year.
#' @param requireCatches Keep only assessment pulls with non-missing catches
#'   (pelagic/demersal). Set \code{FALSE} for Nephrops.
#' @return Standardised data frame (\code{sid}, \code{assYear}, \code{year}, ...).
#' @export
fetchSagTs = function(sid,
                        sagYears = 2025,
                        includeTB = FALSE,
                        dropAssYearRows = FALSE,
                        requireCatches = TRUE) {
  grid = expand.grid(stock = sid, year = sagYears, stringsAsFactors = FALSE)
  stdG = plyr::mdply(grid, function(stock, year) {
    res = icesSAG::getSAG(stock = stock, year = year)
    # getSAG returns a non-data.frame (a StockList message) when a stock has no
    # assessment for that year. That is an expected "not available" condition
    # while probing sagYears, not an error to swallow -- skip it. Any real
    # failure (network, API, bad request) propagates.
    if (!is.data.frame(res)) return(NULL)
    res
  })

  need = c("Year", "recruitment", "SSB", "F", "catches", "landings",
           "discards", "AssessmentYear")
  if (includeTB) need = c(need, "TBiomass")
  missing = setdiff(need, names(stdG))
  if (length(missing))
    stop("getSAG result missing columns: ", paste(missing, collapse = ", "),
         call. = FALSE)

  stdG = plyr::ddply(stdG, .(stock), function(d) {
    if (requireCatches)
      d = subset(d, !is.na(catches))
    if (!nrow(d)) return(d)
    subset(d, year == max(year))
  })

  out = data.frame(
    sid      = stdG$stock,
    assYear  = stdG$AssessmentYear,
    year     = stdG$Year,
    Rec      = stdG$recruitment,
    SB       = stdG$SSB,
    F        = stdG$F,
    C        = stdG$catches,
    landings = stdG$landings,
    discards = stdG$discards,
    stringsAsFactors = FALSE
  )
  if (includeTB)
    out$TB = stdG$TBiomass
  if (dropAssYearRows)
    out = subset(out, year != assYear)
  out
}

#' Load sids subset, SAG series, reference points, and advice for one fishery.
#'
#' @param fishery Value of \code{bimSids()$fishery} (e.g. \code{"Pelagics"}).
#' @param sagYears Years passed to \code{getSAG}.
#' @param sdgYear Folder year for StockAssessmentGraphs CSV.
#' @param projectRoot Project root for default paths.
#' @param includeTB Nephrops-style total biomass column.
#' @param dropAssYearRows Drop incomplete assessment-year rows.
#' @param dropHomEarly Drop horse-mackerel years before 1985.
#' @param requireCatches Passed to \code{fetchSagTs}.
#' @return Named list: \code{sids}, \code{ts}, \code{rfpts}, \code{advice}.
#' @export
loadSagBundle = function(
    fishery,
    sagYears = 2025,
    sdgYear = 2025,
    projectRoot = defaultProjectRoot(),
    includeTB = FALSE,
    dropAssYearRows = FALSE,
    dropHomEarly = FALSE,
    requireCatches = TRUE) {
  if (!exists("bimSids", mode = "function"))
    stop("bimSids() not found; attach bimResilience first.", call. = FALSE)

  allSids = bimSids()
  sids = allSids[allSids$fishery == fishery, , drop = FALSE]
  if (!nrow(sids))
    stop("No stocks for fishery = ", fishery, call. = FALSE)

  ts = fetchSagTs(
    sid = sids$sid,
    sagYears = sagYears,
    includeTB = includeTB,
    dropAssYearRows = dropAssYearRows,
    requireCatches = requireCatches)
  if (dropHomEarly)
    ts = subset(ts, !(sid == "hom.27.2a3a4a5b6a7a-ce-k8" & year < 1985))

  paths = if (exists("resiliencePaths", mode = "function"))
    resiliencePaths(projectRoot) else NULL
  sdgRoot = if (!is.null(paths)) paths$dirSDG else
    file.path(projectRoot, "data/inputs/ices/sdGraphs")
  adviceFile = if (!is.null(paths) && file.exists(paths$adviceCsv)) {
    paths$adviceCsv
  } else {
    shippedAdvicePath(projectRoot)
  }

  rfpts = loadSagRefpts(
    sid = sids$sid,
    year = sdgYear,
    root = sdgRoot)

  advice = loadAdviceFlqs(adviceFile = adviceFile)

  list(sids = sids, ts = ts, rfpts = rfpts, advice = advice)
}
