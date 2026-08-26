# Migrate BIM-Resilience renv library to R 4.6.1 + latest FLR from GitHub.
# Usage (from project root):
#   %LOCALAPPDATA%\Programs\R\R-4.6.1\bin\Rscript.exe --vanilla scripts/migrate_r461.R

options(
  repos = c(
    CRAN = "https://cloud.r-project.org",
    FLR = "https://flr.r-universe.dev"
  ),
  Ncpus = max(1L, parallel::detectCores() - 1L),
  pkgType = "both"
)

root <- "C:/active/BIM-Resilience"
setwd(root)

lib <- file.path(root, "renv/library/windows/R-4.6/x86_64-w64-mingw32")
dir.create(lib, recursive = TRUE, showWarnings = FALSE)
.libPaths(c(lib, .libPaths()))
Sys.setenv(
  RENV_PATHS_LIBRARY = lib,
  RENV_CONFIG_SYNCHRONIZED_CHECK = "FALSE",
  PATH = paste(
    "C:/rtools45/usr/bin",
    "C:/rtools45/x86_64-w64-mingw32.static.posix/bin",
    Sys.getenv("PATH"),
    sep = ";"
  )
)

message("R: ", R.version.string)
message("lib: ", lib)

if (!requireNamespace("renv", quietly = TRUE))
  install.packages("renv", lib = lib)
library(renv)

# Point lockfile at R 4.6.1 before restore attempts
lock <- "renv.lock"
if (file.exists(lock)) {
  txt <- readLines(lock, warn = FALSE)
  txt <- sub('"Version": "4\\.[0-9]+\\.[0-9]+"', '"Version": "4.6.1"', txt, perl = TRUE)
  # Ensure FLR r-universe is listed
  if (!any(grepl("flr.r-universe.dev", txt, fixed = TRUE))) {
    insert_at <- grep('"Repositories"', txt)[1]
    if (!is.na(insert_at)) {
      # after first CRAN block closing, add FLR — simpler: rewrite header via jsonlite later
    }
  }
  writeLines(txt, lock)
}

message("\n=== Bootstrap remotes / pak ===")
renv::install(c("remotes", "jsonlite", "pak"), prompt = FALSE)

# Patch repositories in lockfile properly
lf <- jsonlite::fromJSON(lock, simplifyVector = FALSE)
lf$R$Version <- "4.6.1"
repos <- lf$R$Repositories
names_r <- vapply(repos, function(x) x$Name, character(1))
if (!("FLR" %in% names_r)) {
  lf$R$Repositories <- c(repos, list(list(Name = "FLR", URL = "https://flr.r-universe.dev")))
}
jsonlite::write_json(lf, lock, pretty = TRUE, auto_unbox = TRUE)

message("\n=== Restore from lock (best effort) ===")
tryCatch(
  renv::restore(prompt = FALSE, clean = FALSE),
  error = function(e) message("restore errors: ", conditionMessage(e))
)

message("\n=== Install DESCRIPTION Imports + report deps ===")
cran_extra <- c(
  "ggplot2", "ggpubr", "ggridges", "ggh4x", "GGally", "ggExtra", "ggside",
  "RColorBrewer", "plyr", "dplyr", "reshape", "reshape2", "kableExtra",
  "purrr", "stringr", "readr", "tidyr", "tibble", "scales", "patchwork",
  "knitr", "rmarkdown", "openxlsx", "data.table", "jsonlite", "yaml",
  "TMB", "Rcpp", "RcppEigen", "icesSAG", "doParallel", "foreach",
  "testthat", "devtools", "withr", "lifecycle", "rlang", "cli", "glue"
)
renv::install(cran_extra, prompt = FALSE)

message("\n=== Latest FLR / shared engine from GitHub ===")
gh <- c(
  "flr/FLCore@devel",
  "flr/FLBRP",
  "flr/FLasher",
  "flr/ggplotFL",
  "flr/FLRebuild",
  "flr/icesdata",
  "flr/FLife",
  "laurieKell/FLBacktest",
  "laurieKell/mpb"
)
for (pkg in gh) {
  message("-> ", pkg)
  tryCatch(
    remotes::install_github(pkg, upgrade = "never", quiet = FALSE, force = TRUE),
    error = function(e) message("FAILED ", pkg, ": ", conditionMessage(e))
  )
}

message("\n=== FLFishery from r-universe if available ===")
tryCatch(
  install.packages("FLFishery", repos = "https://flr.r-universe.dev"),
  error = function(e) message("FLFishery failed: ", conditionMessage(e))
)

message("\n=== Record GitHub remotes + snapshot ===")
renv::record(list(
  FLCore = "flr/FLCore@devel",
  FLBRP = "flr/FLBRP",
  FLasher = "flr/FLasher",
  ggplotFL = "flr/ggplotFL",
  FLRebuild = "flr/FLRebuild",
  icesdata = "flr/icesdata",
  FLife = "flr/FLife",
  FLBacktest = "laurieKell/FLBacktest",
  mpb = "laurieKell/mpb"
))
renv::snapshot(prompt = FALSE, force = TRUE)

message("\n=== Verify ===")
pkgs <- c(
  "FLCore", "FLBRP", "FLasher", "FLBacktest", "ggplotFL", "FLRebuild",
  "icesdata", "FLife", "mpb", "ggplot2", "TMB", "knitr", "renv"
)
for (p in pkgs)
  message(sprintf("%-12s %s", p, requireNamespace(p, quietly = TRUE)))

lf2 <- jsonlite::fromJSON(lock, simplifyVector = FALSE)
message("lock R: ", lf2$R$Version)
fr <- lf2$Packages$FLRebuild
message("FLRebuild Source=", fr$Source, " Version=", fr$Version,
        " Sha=", substr(as.character(fr$RemoteSha), 1, 12))
message("n pkgs in lib: ", length(list.files(lib)))
message("Done.")
