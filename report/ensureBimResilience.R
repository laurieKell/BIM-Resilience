#' Locate the project root without a machine-specific path.
#'
#' Order: \code{RESILIENCE_ROOT} if set; else walk upward from \code{start}
#' looking for \code{DESCRIPTION} plus \code{R/} and \code{report/}.
#'
#' (Also exported from the package as \code{bimResilience::findProjectRoot}.)
#'
#' @param start Directory to start walking from. Default: directory of a
#'   \code{source()}d file, else \code{getwd()}.
#' @return Absolute project-root path (forward slashes).
#' @noRd
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

#' Load bimResilience from the installed library or local \code{R/} sources.
#'
#' @param projectRoot Project root (directory containing \code{DESCRIPTION}).
#' @return Invisibly \code{TRUE}.
#' @noRd
ensureBimResilience = function(projectRoot) {
  projectRoot = normalizePath(projectRoot, winslash = "/", mustWork = TRUE)
  needed = c("resiliencePaths", "loadShippedStocks", "loadReportLibraries",
             "bimSids", "loadSagBundle", "shippedAdvicePath", "findProjectRoot")
  installedOk = requireNamespace("bimResilience", quietly = TRUE) &&
    all(vapply(needed, exists, logical(1),
               envir = asNamespace("bimResilience"), inherits = FALSE))
  if (installedOk) {
    if (!"package:bimResilience" %in% search()) {
      suppressPackageStartupMessages(
        suppressWarnings(library(bimResilience)))
    }
    return(invisible(TRUE))
  }
  if (!requireNamespace("devtools", quietly = TRUE)) {
    stop(
      "bimResilience is not installed (or is stale). ",
      "Install devtools, then from the project root run: devtools::load_all(\".\") ",
      "or devtools::install(\".\")",
      call. = FALSE
    )
  }
  if (!dir.exists(file.path(projectRoot, "R"))) {
    stop("No R/ directory under ", projectRoot, call. = FALSE)
  }
  suppressWarnings(devtools::load_all(projectRoot, quiet = TRUE))
  invisible(TRUE)
}

#' Resolve \code{report/} for knit or interactive use.
#' @noRd
.reportDir = function() {
  d = tryCatch(knitr::current_input(dir = TRUE), error = function(e) NULL)
  if (is.character(d) && length(d) == 1L && nzchar(d) &&
      file.exists(file.path(d, "ensureBimResilience.R")))
    return(normalizePath(d, winslash = "/"))
  if (file.exists("ensureBimResilience.R"))
    return(normalizePath(".", winslash = "/"))
  if (file.exists(file.path("report", "ensureBimResilience.R")))
    return(normalizePath("report", winslash = "/"))
  stop(
    "Cannot locate report/ensureBimResilience.R. ",
    "Knit the Rmd, setwd to report/ or the project root, ",
    "or set RESILIENCE_ROOT.",
    call. = FALSE
  )
}

#' Find root, load package, return \code{resiliencePaths()} list.
#' @param start Optional start directory for \code{findProjectRoot}.
#' @return Named list from \code{resiliencePaths}.
#' @noRd
bootstrapBimResilience = function(start = NULL) {
  if (is.null(start) || !nzchar(start)) start = .reportDir()
  projectRoot = findProjectRoot(start)
  ensureBimResilience(projectRoot)
  resiliencePaths(projectRoot)
}

#' Bind path variables into an environment (stock-group Rmd entry point).
#'
#' After \code{source("ensureBimResilience.R")}, call
#' \code{setupReportPaths()} so \code{projectRoot}, \code{dirOM}, etc. exist.
#'
#' @param envir Environment to receive path variables (default: caller).
#' @return Invisibly the paths list.
#' @noRd
setupReportPaths = function(envir = parent.frame()) {
  paths = bootstrapBimResilience()
  list2env(paths, envir = envir)
  invisible(paths)
}
