#' Load FLR / assessment packages used by stock-group Rmds.
#'
#' Assumes \code{bimResilience} is already attached (call
#' \code{ensureBimResilience(projectRoot)} first). Does not re-attach the package.
#'
#' @param extra Character vector of additional package names (e.g. Nephrops).
#' @return Invisibly, the packages loaded.
#' @export
loadReportLibraries = function(extra = character()) {
  pkgs = c(
    "FLCore", "FLasher", "FLBRP", "FLRebuild",
    "ggplotFL", "icesdata", "icesSAG",
    "FLfse", "stockassessment",
    "r4ss", "ss3om",
    "xtable", "plyr", "dplyr", "reshape",
    extra
  )
  for (p in pkgs)
    suppressPackageStartupMessages(
      suppressWarnings(
        library(p, character.only = TRUE, quietly = TRUE, verbose = FALSE)))
  invisible(pkgs)
}
