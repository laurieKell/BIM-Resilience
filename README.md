# BIM-Resilience

Biological TAC / productivity scenarios. Default branch: **`release`**.

Shared FLR engine: [FLBacktest](https://github.com/laurieKell/FLBacktest) (same stack as [backtest-ices](https://github.com/laurieKell/backtest-ices)).

This repo on GitHub is **only** what a clean PC needs to restore packages and run the TAC pipeline (`01`–`04` + finalise). Starting stocks ship in `inst/extdata/` — no local SS3/SAM.

---

## Virgin machine test

Working directory = clone root. Do these **in order**.

### 1. Prerequisites

| Need | Notes |
|------|--------|
| **R** | **4.6.1** (matches `renv.lock`) |
| **Rtools** (Windows) | **Rtools45** |
| **Git** | This repo + `laurieKell/FLBacktest` + `flr/*` |
| **Network** | CRAN, GitHub, ICES SAG |

### 2. Clone

```bash
git clone -b release https://github.com/laurieKell/BIM-Resilience.git
cd BIM-Resilience
```

### 3. Install packages

```bash
Rscript -e "install.packages('renv', repos = 'https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

If restore fails on FLR packages:

```r
install.packages(c("remotes", "devtools"), repos = "https://cloud.r-project.org")
remotes::install_github(c(
  "flr/FLCore@devel", "flr/FLBRP", "flr/FLasher", "flr/ggplotFL",
  "flr/icesdata", "flr/FLRebuild", "flr/FLife",
  "laurieKell/FLBacktest", "laurieKell/mpb"
))
devtools::install_deps(".", dependencies = TRUE)
renv::restore()
```

### 4. Smoke checks

```r
devtools::load_all(".")
loadReportLibraries()
stopifnot(length(names(loadShippedStocks("pelagics"))) > 0)
stopifnot(length(names(loadShippedStocks("demersal"))) > 0)
stopifnot(length(names(loadShippedStocks("iccat"))) > 0)
print(resiliencePaths())
message("Smoke OK")
```

### 5. Run the pipeline

Knit `report/01_pelagics.Rmd` … `04_iccat.Rmd` (RStudio **Knit**, or below), then finalise:

```r
source("report/finalise/00_run_all.R")
runAll(render = TRUE)    # re-knit 01–04 then stage / QA / appendix PDF
# runAll(render = FALSE) # if 01–04 HTML + TAC CSVs already exist
```

Outputs land under local `data/` (gitignored). SAG series are fetched from the web.

Optional path overrides:

```r
Sys.setenv(RESILIENCE_ROOT = "D:/path/to/BIM-Resilience")
Sys.setenv(RESILIENCE_DATA = "D:/path/to/local-analysis-data")
```

---

## On GitHub vs local

| On GitHub | Local only |
|-----------|------------|
| `R/`, `inst/extdata/`, `renv.lock` | Generated `data/` (OM, TAC, caches) |
| `report/01`–`04`, knit helpers, `finalise/` | Knit HTML/PDF, latex build products |
| `report/latex/*.tex` (appendix sources) | Beamer decks, overview/mackerel notebooks, `docs/` |

`FLCandy` is not part of this pipeline.
