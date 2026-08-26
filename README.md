# BIM-Resilience

Biological TAC / productivity scenarios. Default branch: **`release`**.

Project layout matches [backtest-ices](https://github.com/laurieKell/backtest-ices): app helpers in `R/`, notebooks in `Rmd/`, tracked seeds in `data/`, orchestration in `scripts/`. Shared FLR engine: [FLBacktest](https://github.com/laurieKell/FLBacktest). **Not** an R package — no `DESCRIPTION` / `inst/extdata`.

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
renv::restore()
```

### 4. Smoke checks

```r
source("R/paths.R")
root <- bm_root()
load_app(root)
loadReportLibraries()
stopifnot(length(names(loadShippedStocks("pelagics"))) > 0)
stopifnot(length(names(loadShippedStocks("demersal"))) > 0)
stopifnot(length(names(loadShippedStocks("iccat"))) > 0)
print(resiliencePaths())
message("Smoke OK")
```

### 5. Run the pipeline

Knit `Rmd/01_pelagics.Rmd` … `04_iccat.Rmd`, then finalise:

```r
source("scripts/finalise/00_run_all.R")
runAll(render = TRUE)    # re-knit 01–04 then stage / QA / appendix PDF
# runAll(render = FALSE) # if HTML + TAC CSVs already exist
```

Outputs land under local `data/` (gitignored except `reference/` + `advice/`). SAG series are fetched from the web.

```r
Sys.setenv(RESILIENCE_ROOT = "D:/path/to/BIM-Resilience")
Sys.setenv(RESILIENCE_DATA = "D:/path/to/local-analysis-data")  # optional
```

---

## Layout

| Path | Role |
|------|------|
| `R/` | Thin app helpers (paths, SAG I/O, scenario labels) |
| `Rmd/` | Pipeline notebooks `01`–`04` + knit drivers |
| `data/reference/` | Tracked starting FLStocks |
| `data/advice/advice.csv` | Tracked advice bridge |
| `scripts/finalise/` | Stage figs, QA, appendix PDF |
| `tex/` | TAC appendix LaTeX sources |
| `renv.lock` | Exact package set |

Prefer **FLBacktest** / FLR generics for projection and stock ops; keep app `R/` for project I/O and scenario tables only.
