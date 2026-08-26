# Second-machine checklist

Follow the project **[README](../README.md)** (sections 0–4). Condensed copy:

## Clone + restore

```bash
git clone https://github.com/laurieKell/BIM-Resilience.git
cd BIM-Resilience
Rscript -e "install.packages('renv', repos='https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

In R from the project root:

```r
devtools::load_all(".")
loadReportLibraries()
names(loadShippedStocks("pelagics"))
```

## Re-run

```r
source("report/finalise/00_run_all.R")
runAll(render = FALSE)   # TRUE to re-knit 01–04 first
```

## Requirements

- R ≥ 4.0 (4.4.x recommended; matches `renv.lock`)
- Network for CRAN + GitHub (`flr/*`, `laurieKell/FLBacktest`)
- Windows: Rtools if packages need compiling

## Refresh the lock (working machine only)

```bash
Rscript scripts/setup_renv.R
```

Commit `renv.lock` afterward so other PCs can restore.
