#' Resolve project root and standard data / report paths.
#'
#' Typical Rmd setup (attach package once, then FL stack):
#'
#' \preformatted{
#' projectRoot = "C:/active/Resilience"
#' source(file.path(projectRoot, "report/ensureBimResilience.R"))
#' ensureBimResilience(projectRoot)
#' list2env(resiliencePaths(projectRoot), envir = environment())
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
#' @param projectRoot Project root. If \code{NULL}, use \code{RESILIENCE_ROOT}
#'   if set, else probe cwd / parent, else \code{"C:/active/Resilience"}.
#' @param dataRoot Local analysis-data directory. If \code{NULL}, use
#'   \code{RESILIENCE_DATA} if set, else \code{file.path(projectRoot, "data")}.
#' @return Named list of path strings (\code{projectRoot}, \code{dir*},
#'   \code{adviceCsv}, ...).
#' @export
resiliencePaths = function(projectRoot = NULL, dataRoot = NULL) {
  if (is.null(projectRoot) || !nzchar(projectRoot)) {
    envRoot = Sys.getenv("RESILIENCE_ROOT", "")
    if (nzchar(envRoot)) {
      projectRoot = normalizePath(envRoot, winslash = "/", mustWork = FALSE)
    } else if (file.exists("Resilience.Rproj") || file.exists("DESCRIPTION")) {
      projectRoot = normalizePath(".", winslash = "/", mustWork = TRUE)
    } else if (file.exists(file.path("..", "Resilience.Rproj")) ||
               file.exists(file.path("..", "DESCRIPTION"))) {
      projectRoot = normalizePath("..", winslash = "/", mustWork = TRUE)
    } else {
      projectRoot = "C:/active/Resilience"
    }
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
