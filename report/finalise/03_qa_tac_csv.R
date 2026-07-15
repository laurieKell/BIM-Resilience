# =============================================================================
# 03 - QA the TAC forecast CSVs against the appendix chapter's claims.
# =============================================================================
# Reports, per stock group: scenario labels, SIDs, year range, Catch/B/Btrig
# ranges. Flags the known finalisation issues:
#   * Nephrops missing functional unit(s) vs the master list (e.g. nep.fu.16)
#   * Nephrops projection horizon differs from the other groups
#   * Scenario-label inconsistency across groups (e.g. "Fmsy" vs "FMSY")
#   * Btrig spanning both <1 and >>1 within a group (possible unit mismatch)
# Writes a plain-text summary to report/latex/qa_report.txt.
#
# Usage:
#   source("report/finalise/03_qa_tac_csv.R"); qaTacCsv()
# =============================================================================

local({
  a <- commandArgs(FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  cands <- c(
    if (length(f)) file.path(dirname(normalizePath(f)), "_config.R"),
    file.path(getwd(), "report/finalise/_config.R"),
    file.path(getwd(), "_config.R"),
    "C:/active/Resilience/report/finalise/_config.R"
  )
  hit <- cands[file.exists(cands)]
  if (!length(hit)) stop("_config.R not found; run from project root.", call. = FALSE)
  sys.source(hit[1], envir = globalenv(), keep.source = FALSE)
})

.rng <- function(x) {
  x <- x[is.finite(x)]
  if (!length(x)) return("n/a")
  sprintf("%.3g - %.3g", min(x), max(x))
}

qaTacCsv <- function(outFile = file.path(paths$latex, "qa_report.txt")) {
  out <- character(0)
  say <- function(...) {
    line <- paste0(...)
    out[[length(out) + 1L]] <<- line
    cat(line, "\n", sep = "")
  }

  say("TAC CSV QA report - ", format(Sys.time(), "%Y-%m-%d %H:%M"))
  say(strrep("=", 60))

  perGroup <- list()
  for (key in names(tacCsvFiles)) {
    fp <- tacCsvFiles[[key]]
    say("\n[", key, "] ", fp)
    if (!file.exists(fp)) { say("  MISSING FILE"); next }

    d <- utils::read.csv(fp, stringsAsFactors = FALSE)
    need <- c("Scenario", "sid", "Year", "Catch", "B", "Btrig")
    miss <- setdiff(need, names(d))
    if (length(miss)) say("  WARNING missing columns: ", paste(miss, collapse = ", "))

    scen  <- sort(unique(d$Scenario))
    sids  <- sort(unique(d$sid))
    yrs   <- range(d$Year, na.rm = TRUE)
    perGroup[[key]] <- list(scen = scen, sids = sids, yrs = yrs)

    say("  rows      : ", nrow(d))
    say("  scenarios : ", paste(scen, collapse = " | "))
    say("  n sids    : ", length(sids))
    say("  sids      : ", paste(sids, collapse = ", "))
    say("  years     : ", yrs[1], " - ", yrs[2])
    say("  Catch rng : ", .rng(d$Catch))
    say("  B rng     : ", .rng(d$B))
    say("  Btrig rng : ", .rng(d$Btrig))

    if (all(c("Btrig") %in% names(d))) {
      bt <- d$Btrig[is.finite(d$Btrig)]
      if (length(bt) && any(bt < 1) && any(bt > 5))
        say("  >> FLAG: Btrig spans <1 and >5 within group",
            " (min ", signif(min(bt), 3), ", max ", signif(max(bt), 3),
            ") - possible B/Btrig unit mismatch across sids; verify or caveat.")
    }
  }

  say("\n", strrep("-", 60))
  say("Cross-checks")

  # Nephrops functional-unit completeness.
  if (!is.null(perGroup$neph)) {
    have <- perGroup$neph$sids
    missingFu <- setdiff(expectedNephSids, have)
    extraFu   <- setdiff(have, expectedNephSids)
    if (length(missingFu))
      say("  >> FLAG: Nephrops missing FU(s) vs master list: ",
          paste(missingFu, collapse = ", "),
          " (likely a failed JABBA fit; drop from chapter or note as excluded).")
    if (length(extraFu))
      say("  note: Nephrops sids not in master list: ", paste(extraFu, collapse = ", "))
    if (!length(missingFu) && !length(extraFu))
      say("  Nephrops FUs match master list (", length(have), ").")
  }

  # Projection horizon consistency.
  ends <- sapply(perGroup, function(g) g$yrs[2])
  if (length(unique(ends)) > 1L)
    say("  >> FLAG: projection end-year differs across groups: ",
        paste(sprintf("%s=%d", names(ends), ends), collapse = ", "),
        " - align the chapter text with each group's actual horizon.")

  # Scenario-label consistency.
  allScen <- unlist(lapply(perGroup, `[[`, "scen"))
  lc <- tolower(allScen)
  dupCase <- unique(allScen[duplicated(lc) | duplicated(lc, fromLast = TRUE)])
  variants <- tapply(dupCase, tolower(dupCase), function(v) paste(unique(v), collapse = " / "))
  variants <- variants[sapply(strsplit(variants, " / "), length) > 1]
  if (length(variants))
    say("  >> FLAG: scenario labels differ only by case/spelling: ",
        paste(variants, collapse = "; "),
        " - standardise labels across groups and chapter.")

  writeLines(out, outFile)
  message("\nWrote ", normalizePath(outFile, winslash = "/", mustWork = FALSE))
  invisible(perGroup)
}

if (!interactive()) qaTacCsv()
