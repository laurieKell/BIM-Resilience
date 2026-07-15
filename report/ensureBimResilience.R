#' Load bimResilience from the installed library or local \code{R/} sources.
#'
#' Stock-group Rmds call this so knitting works without a manual reinstall after
#' editing files under \code{R/}.
#'
#' Flow: if the installed package is present and exports
#' \code{resiliencePaths}, attach it; otherwise
#' \code{devtools::load_all(projectRoot)}.
#'
#' @param projectRoot Project root (directory containing \code{DESCRIPTION}).
#' @return Invisibly \code{TRUE}.
#' @noRd
ensureBimResilience = function(projectRoot) {
  projectRoot = normalizePath(projectRoot, winslash = "/", mustWork = TRUE)
  installedOk = requireNamespace("bimResilience", quietly = TRUE) &&
    exists("resiliencePaths", envir = asNamespace("bimResilience"), inherits = FALSE)
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
