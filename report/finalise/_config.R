# =============================================================================
# Finalisation config: shared paths and settings for the finalise/ scripts.
# Source this first; every other script in this folder sources it if needed.
# Override the project root with:  Sys.setenv(RESILIENCE_ROOT = "D:/path")
# =============================================================================

projectRoot <- local({
  envRoot <- Sys.getenv("RESILIENCE_ROOT", "")
  if (nzchar(envRoot))
    return(normalizePath(envRoot, winslash = "/", mustWork = TRUE))

  # Prefer this file's location: report/finalise/_config.R → ../..
  for (i in rev(seq_len(sys.nframe()))) {
    f <- sys.frame(i)$ofile
    if (!is.null(f) && identical(basename(f), "_config.R")) {
      return(normalizePath(file.path(dirname(f), "..", ".."),
                           winslash = "/", mustWork = TRUE))
    }
  }

  # Else walk up from cwd looking for DESCRIPTION + R/ + report/
  d <- normalizePath(getwd(), winslash = "/", mustWork = TRUE)
  for (i in seq_len(24L)) {
    if (file.exists(file.path(d, "DESCRIPTION")) &&
        dir.exists(file.path(d, "R")) &&
        dir.exists(file.path(d, "report")))
      return(d)
    parent <- dirname(d)
    if (identical(parent, d)) break
    d <- parent
  }
  stop("Project root not found. Set RESILIENCE_ROOT or source from the repo.",
       call. = FALSE)
})

paths <- list(
  root      = projectRoot,
  report    = file.path(projectRoot, "report"),
  html      = file.path(projectRoot, "report", "html"),
  latex     = file.path(projectRoot, "report", "latex"),
  latexFigs = file.path(projectRoot, "report", "latex", "figs"),
  tacCsv    = file.path(projectRoot, "data", "TAC", "csv"),
  knitter   = file.path(projectRoot, "report", "knit_to_report.R")
)

# Stock-group reports (order = render order).
reports <- c(
  pel   = file.path(paths$report, "01_pelagics.Rmd"),
  dem   = file.path(paths$report, "02_demersal.Rmd"),
  neph  = file.path(paths$report, "03_nephrops.Rmd"),
  iccat = file.path(paths$report, "04_iccat.Rmd")
)

# Expected Nephrops functional units (master list) for the QA cross-check.
expectedNephSids <- c(
  "nep.fu.11", "nep.fu.12", "nep.fu.13", "nep.fu.14", "nep.fu.15",
  "nep.fu.16", "nep.fu.19", "nep.fu.2021", "nep.fu.22"
)

# Forecast CSV per group.
tacCsvFiles <- c(
  pel   = file.path(paths$tacCsv, "pel-f.csv"),
  dem   = file.path(paths$tacCsv, "dem-f.csv"),
  neph  = file.path(paths$tacCsv, "neph-f.csv"),
  iccat = file.path(paths$tacCsv, "iccat-f.csv")
)

invisible(TRUE)
