#' bimResilience: BIM fisheries resilience analysis tools
#'
#' Workflow helpers for ICES / ICCAT stock load, update, and TAC scenarios.
#' Stock-group Rmds attach the package with \code{ensureBimResilience()} /
#' \code{loadReportLibraries()}.
#'
#' \strong{Data policy.} Starting FLStocks for pelagics, demersal and albacore
#' ship in \code{inst/extdata/} (\code{\link{loadShippedStocks}}). SAG series and
#' reference points are read from the ICES web API. Generated OMs, TAC tables,
#' Nephrops JABBA fits and full SS3/SAM folders stay in a local
#' \code{data/} tree (gitignored; see \code{data/README.md}).
#'
#' @keywords internal
"_PACKAGE"
