## Application I/O for tracked starting stocks under data/reference/
## (backtest-ices style — not packaged via inst/extdata).

shippedStocksPath = function(group = c("pelagics", "demersal", "iccat"),
                             projectRoot = NULL) {
  group = match.arg(group)
  if (is.null(projectRoot) || !nzchar(projectRoot))
    projectRoot = bm_root()
  fname = switch(
    group,
    pelagics = "pel-stks.RData",
    demersal = "dem-stks.RData",
    iccat    = "alb-om.RData"
  )
  path = file.path(projectRoot, "data", "reference", fname)
  if (!file.exists(path))
    stop("Starting stock file not found: ", path,
         ". Restore data/reference/ from the GitHub clone.",
         call. = FALSE)
  normalizePath(path, winslash = "/", mustWork = TRUE)
}

#' Load starting stocks for notebooks 01 / 02 / 04.
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

#' Path to advice catch table (tracked under data/advice/).
shippedAdvicePath = function(projectRoot = NULL) {
  if (is.null(projectRoot) || !nzchar(projectRoot))
    projectRoot = bm_root()
  path = file.path(projectRoot, "data", "advice", "advice.csv")
  if (!file.exists(path))
    stop("advice.csv not found at ", path, call. = FALSE)
  normalizePath(path, winslash = "/")
}
