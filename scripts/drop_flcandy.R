# Drop FLCandy from BIM-Resilience lock/library (prototypes only; not pipeline).
lib <- "C:/active/BIM-Resilience/renv/library/windows/R-4.6/x86_64-w64-mingw32"
.libPaths(c(lib, .libPaths()))
setwd("C:/active/BIM-Resilience")
Sys.setenv(RENV_PATHS_LIBRARY = lib, RENV_CONFIG_SYNCHRONIZED_CHECK = "FALSE")

candy_lib <- file.path(lib, "FLCandy")
if (dir.exists(candy_lib)) {
  message("Removing installed FLCandy from project library...")
  unlink(candy_lib, recursive = TRUE, force = TRUE)
}

if (!requireNamespace("jsonlite", quietly = TRUE))
  install.packages("jsonlite", repos = "https://cloud.r-project.org")

lf <- jsonlite::fromJSON("renv.lock", simplifyVector = FALSE)
had <- !is.null(lf$Packages$FLCandy)
lf$Packages$FLCandy <- NULL
# keep R version / repos as-is
jsonlite::write_json(lf, "renv.lock", pretty = TRUE, auto_unbox = TRUE)
message(if (had) "Removed FLCandy from renv.lock" else "FLCandy was not in renv.lock")

lf2 <- jsonlite::fromJSON("renv.lock", simplifyVector = FALSE)
stopifnot(is.null(lf2$Packages$FLCandy))
cat("lock R:", lf2$R$Version, "\n")
cat("FLCandy in lock:", !is.null(lf2$Packages$FLCandy), "\n")
cat("DESCRIPTION Imports has FLCandy:", grepl("FLCandy", paste(readLines("DESCRIPTION"), collapse = "\n")), "\n")
message("Done.")
