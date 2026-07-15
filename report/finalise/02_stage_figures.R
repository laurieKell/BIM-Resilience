# =============================================================================
# 02 - Stage appendix figures.
# =============================================================================
# Copies the knitr HTML figure PNGs into report/latex/figs/ under the stable
# names the LaTeX chapter references. Run AFTER an HTML knit (script 01).
#
# Usage:
#   source("report/finalise/02_stage_figures.R")
#   stageFigures()                 # copy all, report any missing
#   stageFigures(strict = TRUE)    # error if any source is missing
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

# source PNG (relative to report/html/) -> staged name (in report/latex/figs/)
figureMap <- c(
  "01_pelagics_files/figure-html/recruitment-residuals-1.png" = "pel-rec-residuals.png",
  "01_pelagics_files/figure-html/forecast-catch-build-1.png"  = "pel-forecast-catch.png",
  "01_pelagics_files/figure-html/plot-1.png"                  = "pel-sag-vs-stock.png",
  "02_demersal_files/figure-html/recruitment-residuals-1.png" = "dem-rec-residuals.png",
  "02_demersal_files/figure-html/forecast-catch-build-1.png"  = "dem-forecast-catch.png",
  "02_demersal_files/figure-html/plot-1.png"                  = "dem-sag-vs-stock.png",
  "03_nephrops_files/figure-html/neph-stock-ts-1.png"         = "neph-stock-ts.png",
  "03_nephrops_files/figure-html/neph-catch-ts-1.png"         = "neph-catch-ts.png",
  "03_nephrops_files/figure-html/neph-fishing-pressure-ts-1.png" = "neph-f-ts.png",
  "03_nephrops_files/figure-html/neph-jabba-stock-ts-1.png"   = "neph-jabba-stock.png",
  "03_nephrops_files/figure-html/neph-jabba-yield-ts-1.png"   = "neph-jabba-yield.png",
  "03_nephrops_files/figure-html/neph-jabba-harvest-ts-1.png" = "neph-jabba-harvest.png",
  "03_nephrops_files/figure-html/neph-process-error-ts-1.png" = "neph-proc-residuals.png",
  "03_nephrops_files/figure-html/neph-process-error-ts-2.png" = "neph-proc-error.png",
  "03_nephrops_files/figure-html/plot-nephrops-1.png"         = "neph-forecast-catch.png",
  "04_iccat_files/figure-html/equilibrium-and-residuals-1.png" = "alb-rec-residuals.png",
  "04_iccat_files/figure-html/check-1.png"                    = "alb-assessment-panels.png",
  "04_iccat_files/figure-html/forecasts-1.png"                = "alb-forecast.png"
)

stageFigures <- function(strict = FALSE) {
  dir.create(paths$latexFigs, recursive = TRUE, showWarnings = FALSE)
  srcs <- file.path(paths$html, names(figureMap))
  dsts <- file.path(paths$latexFigs, unname(figureMap))

  copied <- character(0); missing <- character(0)
  for (i in seq_along(srcs)) {
    if (file.exists(srcs[i])) {
      file.copy(srcs[i], dsts[i], overwrite = TRUE)
      copied <- c(copied, basename(dsts[i]))
      message("copied  ", basename(dsts[i]))
    } else {
      missing <- c(missing, names(figureMap)[i])
      message("MISSING ", srcs[i])
    }
  }
  message("\nStaged ", length(copied), " / ", length(srcs),
          " figures into ", paths$latexFigs)
  if (length(missing) && strict)
    stop(length(missing), " figure(s) missing; re-knit HTML first.", call. = FALSE)
  invisible(list(copied = copied, missing = missing))
}

if (!interactive()) stageFigures()
