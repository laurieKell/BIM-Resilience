#' Paths to packaged starting FLStocks (inst/extdata).
#'
#' @param group One of \code{"pelagics"}, \code{"demersal"}, \code{"iccat"}.
#' @return Absolute path to the \code{.RData} file inside the installed package
#'   (or the local source tree when using \code{devtools::load_all()}).
#' @export
shippedStocksPath = function(group = c("pelagics", "demersal", "iccat")) {
  group = match.arg(group)
  fname = switch(
    group,
    pelagics = "pel-stks.RData",
    demersal = "dem-stks.RData",
    iccat    = "alb-om.RData"
  )
  path = system.file("extdata", fname, package = "bimResilience", mustWork = FALSE)
  if (!nzchar(path) || !file.exists(path)) {
    # Fallbacks when the package is sourced without install / load_all.
    candidates = c(
      file.path(defaultProjectRoot(), "inst", "extdata", fname),
      file.path("inst", "extdata", fname)
    )
    hit = candidates[file.exists(candidates)]
    if (!length(hit))
      stop("Shipped stock file not found: ", fname,
           ". Run data-raw/ship_stocks.R then reinstall / load_all.",
           call. = FALSE)
    path = normalizePath(hit[1], winslash = "/", mustWork = TRUE)
  }
  path
}

#' Load packaged starting stocks for reports 01 / 02 / 04.
#'
#' These are the only large analysis objects shipped with the package. SAG
#' series and reference points come from the ICES web API; OM equilibria, TAC
#' forecasts, Nephrops JABBA fits, and SS3/SAM folders are local or regenerated.
#'
#' @param group \code{"pelagics"} / \code{"demersal"}: returns an
#'   \code{FLStocks} object. \code{"iccat"}: returns a named list with
#'   \code{FLStock}, \code{SRR}, and \code{refpts} (same shape as
#'   \code{\link{readSS3}}).
#' @return \code{FLStocks} (pelagics, demersal) or a list (iccat).
#' @export
#' @examples
#' \dontrun{
#' pel = loadShippedStocks("pelagics")
#' dem = loadShippedStocks("demersal")
#' alb = loadShippedStocks("iccat")
#' }
loadShippedStocks = function(group = c("pelagics", "demersal", "iccat")) {
  group = match.arg(group)
  path = shippedStocksPath(group)
  e = new.env(parent = emptyenv())
  load(path, envir = e)

  if (identical(group, "iccat")) {
    need = c("FLStock", "SRR", "refpts")
    miss = setdiff(need, ls(e))
    if (length(miss))
      stop("alb-om.RData missing objects: ", paste(miss, collapse = ", "),
           call. = FALSE)
    return(list(FLStock = e$FLStock, SRR = e$SRR, refpts = e$refpts))
  }

  if (!exists("stks", envir = e, inherits = FALSE))
    stop(basename(path), " does not contain object 'stks'.", call. = FALSE)
  e$stks
}

#' Path to packaged advice catch table (optional bridge input).
#'
#' Prefers a local \code{data/advice/advice.csv} when present; otherwise the
#' copy under \code{inst/extdata/}.
#'
#' @param projectRoot Project root for the local copy.
#' @return Path to an advice CSV.
#' @export
shippedAdvicePath = function(projectRoot = defaultProjectRoot()) {
  local = file.path(projectRoot, "data", "advice", "advice.csv")
  if (file.exists(local)) return(normalizePath(local, winslash = "/"))
  path = system.file("extdata", "advice.csv", package = "bimResilience",
                     mustWork = FALSE)
  if (nzchar(path) && file.exists(path)) return(path)
  candidates = c(
    file.path(projectRoot, "inst", "extdata", "advice.csv"),
    file.path("inst", "extdata", "advice.csv")
  )
  hit = candidates[file.exists(candidates)]
  if (!length(hit))
    stop("advice.csv not found locally or in inst/extdata/.", call. = FALSE)
  normalizePath(hit[1], winslash = "/")
}
