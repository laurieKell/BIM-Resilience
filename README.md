# BIM-Resilience

Biological TAC / productivity scenarios for the BIM resilience project.

| | |
|--|--|
| **Repo** | https://github.com/laurieKell/BIM-Resilience |
| **Default branch** | `release` |
| **Shared FLR engine** | [FLBacktest](https://github.com/laurieKell/FLBacktest) (same stack as [backtest-ices](https://github.com/laurieKell/backtest-ices)) |
| **Architecture** | [`docs/app_vs_package.md`](docs/app_vs_package.md) |

Follow **Virgin machine test** below on a clean PC. No local SS3/SAM archives are required for the default run.

---

## Virgin machine test

Do these steps **in order**, working directory = the clone root.

### 1. Prerequisites

| Need | Notes |
|------|--------|
| **R** | **4.6.1** (matches `renv.lock`) |
| **Rtools** (Windows) | **Rtools45** — compile FLR / TMB |
| **Git** | Access to this repo + `laurieKell/FLBacktest` + `flr/*` |
| **Network** | CRAN, GitHub, ICES SAG (when knitting) |

In RStudio: set R to **4.6.1**, then open this project.

### 2. Clone

```bash
git clone -b release https://github.com/laurieKell/BIM-Resilience.git
cd BIM-Resilience
```

(If `release` is already the GitHub default, a plain `git clone` is enough.)

### 3. Install packages

```bash
Rscript -e "install.packages('renv', repos = 'https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

First restore can take a long time.

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

`FLCandy` is **not** part of this pipeline.

### 4. Smoke checks

```r
devtools::load_all(".")
loadReportLibraries()

# Shipped starting stocks (inst/extdata/) — no local assessments required
stopifnot(length(names(loadShippedStocks("pelagics"))) > 0)
stopifnot(length(names(loadShippedStocks("demersal"))) > 0)
stopifnot(length(names(loadShippedStocks("iccat"))) > 0)

# Writable local data tree (created under ./data as needed)
print(resiliencePaths())
message("Smoke OK")
```

### 5. Run the analysis

Generated OMs and TAC CSVs go under local `data/` (gitignored). SAG series are fetched from the web.

| Step | What | Path |
|------|------|------|
| 0 | Orientation | `report/00_overview.Rmd` |
| 1–4 | Stock groups + TAC CSVs | `report/01_pelagics.Rmd` … `04_iccat.Rmd` |
| 5–6 | Beamer figs / mackerel what-ifs | `report/05_figs.Rmd`, `06_mackerel_projections.Rmd` |
| 7 | Stage figs, QA, appendix PDF | `report/finalise/00_run_all.R` |

```r
# After 01–04 have been knitted at least once:
source("report/finalise/00_run_all.R")
runAll(render = FALSE)   # TRUE to re-knit 01–04 first (slow)
```

Or open each Rmd and **Knit** (working directory = project root).

Details: [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

**Note:** `report/05_figs.Rmd` optionally loads a SAG snapshot from a sibling
[backtest-ices](https://github.com/laurieKell/backtest-ices) clone. Set
`BACKTEST_ICES_DATA` to that repo’s `data/` folder if needed; otherwise skip or
adapt that notebook.

### Optional path overrides

```r
Sys.setenv(RESILIENCE_ROOT = "D:/path/to/BIM-Resilience")
Sys.setenv(RESILIENCE_DATA = "D:/path/to/local-analysis-data")  # optional
```

---

## What is / isn’t on GitHub

| On GitHub (virgin run) | Local only (gitignored) |
|------------------------|-------------------------|
| Starting FLStocks + `advice.csv` in `inst/extdata/` | Full SS3 / SAM under `data/inputs/` |
| Package `R/`, report Rmds, latex/beamer **sources**, docs | Generated `data/om/`, `data/TAC/`, `data/plot-objects/` |
| `scripts/setup_renv.R`, `renv.lock` | Knit HTML/PDF/docx, `report/cache/`, beamer PDFs, Word copies |
| | `scripts/_local/` (maintainer helpers: old `data-raw/`, `flr-contrib/`, …) |

SAG time series are **downloaded** via `icesSAG` when you knit (unless you place a local sdGraphs cache under `data/inputs/`).

See [`data/README.md`](data/README.md).

---

## Deliverables (after a successful run)

| Item | Location |
|------|----------|
| Executive summary | [`docs/executive_summary.md`](docs/executive_summary.md) |
| Main report draft | [`docs/report_main.md`](docs/report_main.md) |
| TAC CSVs | `data/TAC/csv/{pel,dem,neph,iccat}-f.csv` |
| TAC appendix (LaTeX / PDF) | `report/latex/` (build locally) |
| Beamer | `report/beamer/*.tex` → PDF locally |
| Manuscript outline | [`docs/manuscript_outline.md`](docs/manuscript_outline.md) |

---

## Design rules (short)

- Prefer **FLBacktest** / FLR generics over one-off helpers — [`docs/app_vs_package.md`](docs/app_vs_package.md).
- Fail fast: do not set `options(warn = -1)` for production knits.

### Refreshing `renv.lock` (working machine only)

```bash
Rscript scripts/setup_renv.R
```

Commit the updated `renv.lock` so the next PC can `renv::restore()`.
