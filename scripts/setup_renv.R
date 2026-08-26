#!/usr/bin/env Rscript
# Snapshot the current R library into renv.lock (no mass reinstall).
# Run once on the machine where the analysis already works.
if (!requireNamespace("renv", quietly = TRUE))
  stop("Install renv: install.packages('renv')", call. = FALSE)

root <- normalizePath(".", winslash = "/")
if (!file.exists(file.path(root, "renv.lock")))
  renv::init(bare = TRUE, restart = FALSE)
# Snapshot-only: also search user/site libraries where packages already live
user_lib <- Sys.getenv("R_LIBS_USER")
extra <- c(if (nzchar(user_lib)) path.expand(user_lib), .Library.site, .Library)
.libPaths(unique(c(.libPaths(), extra)))

# Explicit GitHub remotes for packages that may lack Remote* metadata when installed locally
github <- c(
  FLCore     = "flr/FLCore@devel",
  FLBRP      = "flr/FLBRP",
  FLasher    = "flr/FLasher",
  ggplotFL   = "flr/ggplotFL",
  FLBacktest = "laurieKell/FLBacktest",
  icesdata   = "flr/icesdata",
  FLRebuild  = "flr/FLRebuild"
)
dep_pkgs <- character()
for (d in c("R", "report", "data-raw")) {
  p <- file.path(root, d)
  if (dir.exists(p))
    dep_pkgs <- c(dep_pkgs, unlist(renv::dependencies(p, quiet = TRUE)$Package))
}

desc_path <- file.path(root, "DESCRIPTION")
imports <- character()
if (file.exists(desc_path)) {
  dcf <- read.dcf(desc_path)
  if ("Imports" %in% colnames(dcf) && !is.na(dcf[1, "Imports"])) {
    raw <- gsub("\n", ",", dcf[1, "Imports"], fixed = TRUE)
    parts <- trimws(unlist(strsplit(raw, ",", fixed = TRUE)))
    imports <- vapply(parts, function(x) trimws(strsplit(x, "(", fixed = TRUE)[[1]][1]), character(1))
    imports <- imports[nzchar(imports) & imports != "R"]
  }
}

deps <- unique(c(dep_pkgs, imports, names(github)))
deps <- deps[!is.na(deps) & nzchar(deps)]

lib <- if (nzchar(user_lib) && dir.exists(path.expand(user_lib))) path.expand(user_lib) else .libPaths()[[1]]
renv::snapshot(library = lib, packages = deps, prompt = FALSE, force = TRUE)
for (pkg in names(github)) {
  if (requireNamespace(pkg, quietly = TRUE))
    tryCatch(renv::record(paste0(pkg, "=", github[[pkg]])), error = function(e)
      message("record ", pkg, ": ", conditionMessage(e)))
}

message("Wrote ", file.path(root, "renv.lock"))
