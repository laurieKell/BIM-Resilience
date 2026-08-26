#!/usr/bin/env Rscript
# Snapshot the current R library into renv.lock (working machine only).
if (!requireNamespace("renv", quietly = TRUE))
  stop("Install renv: install.packages('renv')", call. = FALSE)

root <- normalizePath(".", winslash = "/")
if (!file.exists(file.path(root, "renv.lock")))
  renv::init(bare = TRUE, restart = FALSE)

github <- list(
  FLCore     = "flr/FLCore@devel",
  FLBRP      = "flr/FLBRP",
  FLasher    = "flr/FLasher",
  ggplotFL   = "flr/ggplotFL",
  FLBacktest = "laurieKell/FLBacktest",
  icesdata   = "flr/icesdata",
  FLRebuild  = "flr/FLRebuild",
  FLife      = "flr/FLife",
  mpb        = "laurieKell/mpb"
)

deps <- unique(c(
  unlist(renv::dependencies(file.path(root, "Rmd"), quiet = TRUE)$Package),
  unlist(renv::dependencies(file.path(root, "scripts"), quiet = TRUE)$Package),
  unlist(renv::dependencies(file.path(root, "R"), quiet = TRUE)$Package),
  names(github),
  "rmarkdown", "knitr", "plyr", "dplyr", "ggplot2", "reshape",
  "devtools", "remotes"
))
deps <- deps[!is.na(deps) & nzchar(deps)]

renv::snapshot(packages = deps, prompt = FALSE, force = TRUE)
renv::record(github)
message("Wrote ", file.path(root, "renv.lock"), " (renv ", packageVersion("renv"), ")")
