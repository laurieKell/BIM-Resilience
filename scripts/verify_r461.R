lib <- "C:/active/BIM-Resilience/renv/library/windows/R-4.6/x86_64-w64-mingw32"
.libPaths(c(lib, .libPaths()))
cat("R:", R.version.string, "\n")
lf <- jsonlite::fromJSON("C:/active/BIM-Resilience/renv.lock", simplifyVector = FALSE)
cat("lock R:", lf$R$Version, "\n")
for (p in c("FLCore", "FLBRP", "FLasher", "FLBacktest", "ggplotFL", "FLRebuild",
            "icesdata", "FLife", "mpb", "FLFishery", "TMB", "ggplot2")) {
  ok <- requireNamespace(p, quietly = TRUE)
  ver <- if (ok) as.character(packageVersion(p)) else NA
  cat(sprintf("%-12s %s %s\n", p, if (ok) "OK" else "FAIL", ver))
}
for (nm in c("FLRebuild", "mpb", "FLCore", "FLBacktest")) {
  pkg <- lf$Packages[[nm]]
  cat(sprintf(
    "\n%s: Source=%s Version=%s Remote=%s/%s Sha=%s Url=%s\n",
    nm, pkg$Source, pkg$Version, pkg$RemoteUsername, pkg$RemoteRepo,
    substr(as.character(pkg$RemoteSha), 1, 12), pkg$RemoteUrl
  ))
}
