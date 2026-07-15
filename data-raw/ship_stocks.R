# Build packaged starting stocks under inst/extdata/.
# Run from the project root (requires local data/ for one-time rebuild):
#   source("data-raw/ship_stocks.R")
#
# Shipped products:
#   pel-stks.RData  - FLStocks for report 01 (object: stks)
#   dem-stks.RData  - FLStocks for report 02 (object: stks)
#   alb-om.RData    - albacore FLStock + SRR + refpts for report 04
#   advice.csv      - advice bridge table (tiny; also regenerable locally)

projectRoot <- normalizePath(".", winslash = "/", mustWork = TRUE)
outDir <- file.path(projectRoot, "inst", "extdata")
dir.create(outDir, recursive = TRUE, showWarnings = FALSE)

pelSrc <- file.path(projectRoot, "data", "om", "pel-stks.RData")
demSrc <- file.path(projectRoot, "data", "om", "dem-stks.RData")
adviceSrc <- file.path(projectRoot, "data", "advice", "advice.csv")
albDir <- file.path(projectRoot, "data", "inputs", "SS", "alb-n")

if (!file.exists(pelSrc)) stop("Missing ", pelSrc)
if (!file.exists(demSrc)) stop("Missing ", demSrc)
if (!file.exists(adviceSrc)) stop("Missing ", adviceSrc)
if (!dir.exists(albDir)) stop("Missing ", albDir)

file.copy(pelSrc, file.path(outDir, "pel-stks.RData"), overwrite = TRUE)
file.copy(demSrc, file.path(outDir, "dem-stks.RData"), overwrite = TRUE)
file.copy(adviceSrc, file.path(outDir, "advice.csv"), overwrite = TRUE)

message("Building alb-om.RData from SS3 (may take a minute) ...")
suppressPackageStartupMessages({
  if (!requireNamespace("devtools", quietly = TRUE))
    stop("devtools required to load bimResilience for readSS3()")
  for (p in c("r4ss", "ss3om", "FLCore", "FLBRP"))
    library(p, character.only = TRUE)
  devtools::load_all(projectRoot, quiet = TRUE)
})
alb <- readSS3(albDir)
FLStock <- alb$FLStock
name(FLStock) <- "alb-n"
SRR <- alb$SRR
refpts <- alb$refpts
save(FLStock, SRR, refpts, file = file.path(outDir, "alb-om.RData"))

# Sanity checks
e1 <- new.env(); load(file.path(outDir, "pel-stks.RData"), envir = e1)
e2 <- new.env(); load(file.path(outDir, "dem-stks.RData"), envir = e2)
stopifnot(inherits(e1$stks, "FLStocks"), length(e1$stks) >= 1)
stopifnot(inherits(e2$stks, "FLStocks"), length(e2$stks) >= 1)
stopifnot(inherits(FLStock, "FLStock"))

sizes <- file.info(list.files(outDir, full.names = TRUE))$size
names(sizes) <- list.files(outDir)
message("Wrote inst/extdata/:")
print(round(sizes / 1024, 1))
message("Done.")
