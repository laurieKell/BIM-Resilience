#' Resolve the first matching column name
#'
#' @noRd
.firstExistingCol = function(data, candidates, label) {
  hit <- candidates[candidates %in% names(data)]
  if (!length(hit)) {
    stop("Missing ", label, " column. Tried: ", paste(candidates, collapse = ", "))
  }
  hit[[1]]
}

#' Build Standard Forecast TAC CSV table (`*-f.csv`)
#'
#' @param fct Data frame containing forecast trajectories.
#' @param triggerBySid Data frame with columns `sid` and trigger biomass
#'   column (`MSYBtrigger` by default).
#' @param triggerCol Trigger column name in `triggerBySid`.
#' @param minYear First year to include (default `2021`).
#' @param sidCandidates Candidate sid column names in `fct`.
#' @param scenarioCandidates Candidate scenario column names in `fct`.
#' @param yearCandidates Candidate year column names in `fct`.
#' @param catchCandidates Candidate catch column names in `fct`.
#' @param biomassCandidates Candidate biomass column names in `fct`.
#'
#' @return Data frame with columns `Scenario`, `sid`, `Year`, `Catch`, `B`, `Btrig`.
#' @export
buildForecastTacCsv <- function(fct,
                                triggerBySid,
                                triggerCol = "MSYBtrigger",
                                minYear = 2021,
                                sidCandidates = c("sid", ".id"),
                                scenarioCandidates = c("Scenario", "scenario"),
                                yearCandidates = c("year", "Year"),
                                catchCandidates = c("Catch", "catch"),
                                biomassCandidates = c("B", "Stock", "SSB", "ssb", "stock")) {
  sidCol <- .firstExistingCol(fct, sidCandidates, "sid")
  scCol <- .firstExistingCol(fct, scenarioCandidates, "scenario")
  yrCol <- .firstExistingCol(fct, yearCandidates, "year")
  ctCol <- .firstExistingCol(fct, catchCandidates, "catch")
  bCol <- .firstExistingCol(fct, biomassCandidates, "biomass")

  if (!all(c("sid", triggerCol) %in% names(triggerBySid))) {
    stop("triggerBySid must include columns: sid, ", triggerCol)
  }

  core <- data.frame(
    sid = as.character(fct[[sidCol]]),
    Scenario = as.character(fct[[scCol]]),
    Year = as.integer(as.numeric(fct[[yrCol]])),
    Catch = as.numeric(fct[[ctCol]]),
    B = as.numeric(fct[[bCol]]),
    stringsAsFactors = FALSE
  )

  out <- merge(
    subset(core, Year >= minYear),
    unique(triggerBySid[, c("sid", triggerCol), drop = FALSE]),
    by = "sid",
    all.x = TRUE
  )
  out$Btrig <- out$B / as.numeric(out[[triggerCol]])
  out <- out[, c("Scenario", "sid", "Year", "Catch", "B", "Btrig"), drop = FALSE]
  out[do.call("order", out[, c("sid", "Scenario", "Year")]), , drop = FALSE]
}

# The stage-2 MSE CSV builder `buildMseTacCsv()` now lives in
# `report/wip/nephMseFeedback.R` (MSE with feedback, work in progress).
