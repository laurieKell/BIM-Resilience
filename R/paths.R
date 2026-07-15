#' Locate the project root without a machine-specific path.
#'
#' Order: \code{RESILIENCE_ROOT} if set; else walk upward from \code{start}
#' looking for \code{DESCRIPTION} plus \code{R/} and \code{report/}.
#'
#' @param start Directory to start walking from. Default: \code{getwd()}, or
#'   the directory of a file being \code{source()}d.
#' @return Absolute project-root path (forward slashes).
#' @export
findProjectRoot = function(start = NULL) {
  envRoot = Sys.getenv("RESILIENCE_ROOT", "")
  if (nzchar(envRoot))
    return(normalizePath(envRoot, winslash = "/", mustWork = TRUE))

  if (is.null(start) || !nzchar(start)) {
    ofile = NULL
    for (i in seq_len(sys.nframe())) {
      e = sys.frame(i)
      if (!is.null(e$ofile)) ofile = e$ofile
    }
    start = if (!is.null(ofile)) dirname(normalizePath(ofile, winslash = "/"))
            else getwd()
  }
  start = normalizePath(start, winslash = "/", mustWork = TRUE)

  isRoot = function(d) {
    file.exists(file.path(d, "DESCRIPTION")) &&
      dir.exists(file.path(d, "R")) &&
      dir.exists(file.path(d, "report"))
  }

  d = start
  for (i in seq_len(24L)) {
    if (isRoot(d)) return(normalizePath(d, winslash = "/"))
    parent = dirname(d)
    if (identical(parent, d)) break
    d = parent
  }
  stop(
    "Cannot find project root from ", start, ". ",
    "Set Sys.setenv(RESILIENCE_ROOT = \"...\") or work from inside the repo.",
    call. = FALSE
  )
}

#' Resolve project root and standard data / report paths.
#'
#' Typical Rmd setup (no hardcoded path):
#'
#' \preformatted{
#' source(file.path(knitr::current_input(dir = TRUE), "ensureBimResilience.R"))
#' setupReportPaths()
#' loadReportLibraries()   # does not re-attach bimResilience
#' }
#'
#' Local analysis inputs and generated artefacts live under
#' \code{file.path(projectRoot, "data")} (or \code{RESILIENCE_DATA} /
#' \code{dataRoot}). That tree is gitignored; the package ships starting
#' FLStocks in \code{inst/extdata/} (see \code{\link{loadShippedStocks}}).
#' SAG time series and reference points are fetched from the ICES web API
#' when local sdGraphs CSVs are absent.
#'
#' @param projectRoot Project root. If \code{NULL}, use
#'   \code{\link{findProjectRoot}}.
#' @param dataRoot Local analysis-data directory. If \code{NULL}, use
#'   \code{RESILIENCE_DATA} if set, else \code{file.path(projectRoot, "data")}.
#' @return Named list of path strings (\code{projectRoot}, \code{dir*},
#'   \code{adviceCsv}, ...).
#' @export
resiliencePaths = function(projectRoot = NULL, dataRoot = NULL) {
  if (is.null(projectRoot) || !nzchar(projectRoot)) {
    projectRoot = findProjectRoot()
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
  dirReport  = file.path(projectRoot, "report")
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
