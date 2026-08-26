#' Load FLR / assessment packages used by stock-group Rmds.
#'
#' Call after sourcing \code{R/paths.R} and \code{load_app()} (or
#' \code{setupReportPaths()}).
loadReportLibraries = function(extra = character()) {
  required = c("FLCore", "FLasher", "FLBRP", "FLBacktest", "plyr", "dplyr")
  optional = c(
    "FLRebuild", "ggplotFL", "icesdata", "icesSAG",
    "FLfse", "stockassessment", "r4ss", "ss3om",
    "xtable", "reshape",
    extra
  )
  missingReq = required[!vapply(required, requireNamespace, logical(1),
                                quietly = TRUE)]
  if (length(missingReq))
    stop("loadReportLibraries: required packages not installed: ",
         paste(missingReq, collapse = ", "),
         ". Install FLBacktest with ",
         "remotes::install_github(\"laurieKell/FLBacktest\").",
         call. = FALSE)

  for (p in required) {
    if (!paste0("package:", p) %in% search())
      suppressPackageStartupMessages(
        library(p, character.only = TRUE, quietly = TRUE, verbose = FALSE))
  }

  missingOpt = character(0)
  for (p in optional) {
    if (!requireNamespace(p, quietly = TRUE)) {
      missingOpt = c(missingOpt, p)
      next
    }
    if (!paste0("package:", p) %in% search())
      suppressPackageStartupMessages(
        library(p, character.only = TRUE, quietly = TRUE, verbose = FALSE))
  }
  if (length(missingOpt))
    message("loadReportLibraries: optional packages not available (skipped): ",
            paste(unique(missingOpt), collapse = ", "))
  invisible(c(required, setdiff(optional, missingOpt)))
}
