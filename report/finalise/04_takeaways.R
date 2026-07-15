# =============================================================================
# 04 - Derive scenario takeaways from the TAC CSVs.
# =============================================================================
# For each stock group and sid, compares the final-year catch and biomass status
# across scenarios so the interpretive sentences in the chapter are grounded in
# the actual numbers. Writes a tidy CSV to report/latex/takeaways.csv.
#
# Usage:
#   source("report/finalise/04_takeaways.R"); takeaways()
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

takeaways <- function(outFile = file.path(paths$latex, "takeaways.csv")) {
  rows <- list()
  for (key in names(tacCsvFiles)) {
    fp <- tacCsvFiles[[key]]
    if (!file.exists(fp)) next
    d <- utils::read.csv(fp, stringsAsFactors = FALSE)
    endYr <- max(d$Year, na.rm = TRUE)
    de <- d[d$Year == endYr, ]

    for (s in sort(unique(de$sid))) {
      ds <- de[de$sid == s, ]
      for (i in seq_len(nrow(ds))) {
        rows[[length(rows) + 1L]] <- data.frame(
          group      = key,
          sid        = s,
          finalYear  = endYr,
          scenario   = ds$Scenario[i],
          finalCatch = round(ds$Catch[i], 1),
          finalBtrig = round(ds$Btrig[i], 3),
          aboveTrigger = isTRUE(ds$Btrig[i] >= 1),
          stringsAsFactors = FALSE
        )
      }
    }
  }
  res <- do.call(rbind, rows)
  utils::write.csv(res, outFile, row.names = FALSE)
  message("Wrote ", normalizePath(outFile, winslash = "/", mustWork = FALSE),
          " (", nrow(res), " rows)")

  # Console summary: share of sids above the trigger in the final year, per group+scenario.
  agg <- stats::aggregate(
    aboveTrigger ~ group + scenario, data = res,
    FUN = function(x) sprintf("%d/%d", sum(x), length(x))
  )
  cat("\nFinal-year sids at/above Btrig=1 (n above / n total):\n")
  print(agg, row.names = FALSE)
  invisible(res)
}

if (!interactive()) takeaways()
