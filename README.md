# BIM-Resilience

Biological TAC / productivity scenarios for the BIM resilience project.

| | |
|--|--|
| **Repo** | https://github.com/laurieKell/BIM-Resilience |
| **Shared FLR engine** | [FLBacktest](https://github.com/laurieKell/FLBacktest) (same stack as [blueMarine](https://github.com/laurieKell/blueMarine)) |
| **Architecture** | [`docs/app_vs_package.md`](docs/app_vs_package.md) |

This README is the checklist for installing and re-running on a **new PC**.

---

## 0. Prerequisites

| Need | Notes |
|------|--------|
| **R** | ≥ 4.0 (DESCRIPTION); **4.4.x recommended** (matches `renv.lock`) |
| **Git** | Clone from GitHub |
| **Rtools** (Windows) | Needed to compile some FLR packages if binaries are missing |
| **Network** | CRAN + GitHub (FLR org + `laurieKell/FLBacktest`) |
| **Optional** | RStudio / Positron; LaTeX (`tinytex` or MiKTeX) only if you build the appendix PDF |

GitHub auth: HTTPS with a credential helper, or SSH keys for `git@github.com:...`.

---

## 1. Clone

```bash
git clone https://github.com/laurieKell/BIM-Resilience.git
cd BIM-Resilience
```

(SSH: `git clone git@github.com:laurieKell/BIM-Resilience.git`)

Open the project at this folder (the one with `DESCRIPTION` / `Resilience.Rproj`).

---

## 2. Install R packages (renv)

From the project root:

```bash
Rscript -e "install.packages('renv', repos = 'https://cloud.r-project.org')"
Rscript -e "renv::restore()"
```

Or in R:

```r
install.packages("renv", repos = "https://cloud.r-project.org")
renv::restore()
```

`renv::restore()` installs everything recorded in `renv.lock` (CRAN + GitHub FLR packages, including FLBacktest). First restore can take a long time.

### If restore fails

Install the shared engine and this package by hand, then pull the rest as needed:

```r
install.packages(c("remotes", "devtools"), repos = "https://cloud.r-project.org")
remotes::install_github("laurieKell/FLBacktest")
# FLR stack (devel FLCore often required):
remotes::install_github(c(
  "flr/FLCore@devel", "flr/FLBRP", "flr/FLasher", "flr/ggplotFL",
  "flr/icesdata", "flr/FLRebuild"
))
devtools::install_deps(".", dependencies = TRUE)
```

---

## 3. Smoke test

From the **project root**:

```r
devtools::load_all(".")
loadReportLibraries()

# Shipped starting stocks (no local SS3/SAM required)
names(loadShippedStocks("pelagics"))
names(loadShippedStocks("demersal"))
names(loadShippedStocks("iccat"))

# Paths resolve under ./data by default
resiliencePaths()
```

If `load_all` or `loadReportLibraries` stops with a missing package, install that package and retry (or re-run `renv::restore()`).

---

## 4. Re-run the analysis

Generated OMs and TAC CSVs are written under local `data/` (gitignored). SAG series are fetched from the web unless you cache them locally.

### Full pipeline (stock groups → appendix)

Knit in order, or use the finalise driver:

| Step | What | Path |
|------|------|------|
| 0 | Orientation | `report/00_overview.Rmd` |
| 1–4 | Stock groups + TAC CSVs | `report/01_pelagics.Rmd` … `04_iccat.Rmd` |
| 5–6 | Beamer figs / mackerel what-ifs | `report/05_figs.Rmd`, `06_mackerel_projections.Rmd` |
| 7 | Stage figs, QA, appendix PDF | `report/finalise/00_run_all.R` |

```r
# From project root — after 01–04 have been knitted at least once:
source("report/finalise/00_run_all.R")
runAll(render = FALSE)   # set TRUE to re-knit 01–04 first (slow)
```

In RStudio: open each Rmd and **Knit**, working directory = project root (or `report/` via the knit helper).

Details: [`docs/WORKFLOW.md`](docs/WORKFLOW.md). More checklist notes: [`docs/SECOND_MACHINE.md`](docs/SECOND_MACHINE.md).

### Optional path overrides

Only if the clone is not your working directory, or data live elsewhere:

```r
Sys.setenv(RESILIENCE_ROOT = "D:/path/to/BIM-Resilience")
Sys.setenv(RESILIENCE_DATA = "D:/path/to/local-analysis-data")  # optional
```

---

## 5. What is / isn’t on GitHub

| On GitHub | Local only (gitignored `data/`) |
|-----------|----------------------------------|
| Starting FLStocks + `advice.csv` in `inst/extdata/` | Full SS3 / SAM folders |
| Package `R/`, notebooks, docs, beamer sources | Generated `data/om/`, `data/TAC/` |
| `renv.lock` | Knit HTML under `report/html/` |

SAG time series and reference points are **downloaded** via `icesSAG` when you knit (unless you place a local sdGraphs cache under `data/inputs/`).

See [`data/README.md`](data/README.md).

---

## 6. Deliverables (after a successful run)

| Item | Location |
|------|----------|
| Executive summary | [`docs/executive_summary.md`](docs/executive_summary.md) |
| Main report draft | [`docs/report_main.md`](docs/report_main.md) |
| TAC CSVs | `data/TAC/csv/{pel,dem,neph,iccat}-f.csv` |
| TAC appendix (LaTeX / PDF) | `report/latex/` |
| Beamer | `report/beamer/` |
| Manuscript outline | [`docs/manuscript_outline.md`](docs/manuscript_outline.md) |

---

## Design rules (short)

- Prefer **FLBacktest** / FLR generics (`fwdFbar`, `annualise`, `FLasher::fwd`, …) over new helpers — [`docs/app_vs_package.md`](docs/app_vs_package.md).
- Fail fast: do not set `options(warn = -1)` for production knits.
- Rebuild packaged stocks from local assessments only when needed: `source("data-raw/ship_stocks.R")`.

### Refreshing `renv.lock` (on a machine that already works)

```bash
Rscript scripts/setup_renv.R
```

Then commit the updated `renv.lock` so the next PC can `renv::restore()`.
