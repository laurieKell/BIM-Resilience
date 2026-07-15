# =============================================================================
# Finalisation config: shared paths and settings for the finalise/ scripts.
# Source this first; every other script in this folder sources it.
# Override the project root with:  Sys.setenv(RESILIENCE_ROOT = "D:/path")
# =============================================================================

projectRoot <- Sys.getenv("RESILIENCE_ROOT", "C:/active/Resilience")
if (!dir.exists(projectRoot))
  stop("Project root not found: ", projectRoot,
       " (set RESILIENCE_ROOT).", call. = FALSE)

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
