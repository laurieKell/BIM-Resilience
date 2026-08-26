# Project root detection (portable; backtest-ices style — not an R package)

#' Find the BIM-Resilience repository root
#'
#' Looks upward for \code{data/reference/stocks.csv} and \code{scripts/finalise/00_run_all.R}.
#' Override with \code{Sys.setenv(RESILIENCE_ROOT = "...")}.
bm_root = function(start = NULL) {
  envRoot = Sys.getenv("RESILIENCE_ROOT", "")
  if (nzchar(envRoot))
    return(normalizePath(envRoot, winslash = "/", mustWork = TRUE))

  markers = c("data/reference/stocks.csv", "scripts/finalise/00_run_all.R")
  starts = unique(c(
    start,
    getwd(),
    if (requireNamespace("knitr", quietly = TRUE)) {
      inp = tryCatch(knitr::current_input(dir = TRUE), error = function(e) NULL)
      if (!is.null(inp) && nzchar(inp)) dirname(inp) else NULL
    }
  ))
  starts = starts[!is.null(starts) & nzchar(starts)]
  for (s in starts) {
    d = normalizePath(s, winslash = "/", mustWork = FALSE)
    for (i in seq_len(12L)) {
      if (all(file.exists(file.path(d, markers))))
        return(normalizePath(d, winslash = "/"))
      parent = dirname(d)
      if (identical(parent, d)) break
      d = parent
    }
  }
  stop(
    "Cannot find BIM-Resilience root (need data/reference/stocks.csv). ",
    "Set RESILIENCE_ROOT or knit from Rmd/.",
    call. = FALSE
  )
}

# Alias used by older helpers / Rmds
findProjectRoot = function(start = NULL) bm_root(start)

#' Resolve project root and standard data / notebook paths.
resiliencePaths = function(projectRoot = NULL, dataRoot = NULL) {
  if (is.null(projectRoot) || !nzchar(projectRoot)) {
    projectRoot = bm_root()
  } else {
    projectRoot = normalizePath(projectRoot, winslash = "/", mustWork = FALSE)
  }

  if (is.null(dataRoot) || !nzchar(dataRoot)) {
    envDat = Sys.getenv("RESILIENCE_DATA", "")
    dataRoot = if (nzchar(envDat)) envDat else file.path(projectRoot, "data")
  }
  dirDat = normalizePath(dataRoot, winslash = "/", mustWork = FALSE)

  dirAdvice  = file.path(dirDat, "advice")
  dirInputs  = file.path(dirDat, "inputs")
  dirOM      = file.path(dirDat, "om")
  dirTAC     = file.path(dirDat, "TAC")
  dirPlot    = file.path(dirDat, "plot-objects")
  dirSS      = file.path(dirInputs, "SS")
  dirSAM     = file.path(dirInputs, "SAM")
  dirIces    = file.path(dirInputs, "ices")
  dirSDG     = file.path(dirIces, "sdGraphs")
  dirReport  = file.path(projectRoot, "Rmd")
  dirPkg     = file.path(projectRoot, "R")

  list(
    projectRoot = projectRoot,
    dirDat      = dirDat,
    dirAdvice   = dirAdvice,
    dirInputs   = dirInputs,
    dirOM       = dirOM,
    dirTAC      = dirTAC,
    dirPlot     = dirPlot,
    dirSS       = dirSS,
    dirSAM      = dirSAM,
    dirIces     = dirIces,
    dirSDG      = dirSDG,
    dirReport   = dirReport,
    dirPkg      = dirPkg,
    adviceCsv   = file.path(dirAdvice, "advice.csv")
  )
}

#' Source all app helpers under \code{R/} (order: paths already loaded).
load_app = function(root = bm_root()) {
  files = c(
    "sids.R",
    "shippedData.R",
    "sagInputs.R",
    "reportLibs.R",
    "reportPlots.R",
    "eqRegimes.R",
    "fcst.R",
    "fcstCtrl.R",
    "simTAC.R",
    "tacCsvExports.R",
    "nephOps.R",
    "readSS3.R",
    "macProjections.R"
  )
  for (f in files) {
    p = file.path(root, "R", f)
    if (file.exists(p)) source(p, local = FALSE)
  }
  invisible(TRUE)
}

#' Bind path variables into the caller (Rmd entry point).
setupReportPaths = function(envir = parent.frame()) {
  root = bm_root()
  if (!exists("loadShippedStocks", mode = "function", inherits = TRUE))
    load_app(root)
  paths = resiliencePaths(root)
  list2env(paths, envir = envir)
  invisible(paths)
}
