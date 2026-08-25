# bimResilience

Application layer for BIM fisheries resilience TAC scenarios.

**Shared FLR engine (with blueMarine):** [FLBacktest](https://github.com/laurieKell/FLBacktest)  
**Repository:** https://github.com/laurieKell/BIM-Resilience  
**Architecture:** [`docs/app_vs_package.md`](docs/app_vs_package.md)

## Install / load

```r
remotes::install_github("laurieKell/FLBacktest")  # shared generics
# remotes::install_github("laurieKell/BIM-Resilience")
devtools::load_all(".")   # local development from project root
```

Prefer `FLBacktest::fwdFbar` and `FLBacktest::annualise` over local helpers.
BIM keeps only scenario labels, SAG I/O, and report glue.
## Re-run the analysis (pipeline)

| Step | Path | Role |
|------|------|------|
| 0 | `report/00_overview.Rmd` | Orientation and shipped-data check |
| 1–4 | `report/01_pelagics.Rmd` … `04_iccat.Rmd` | Stock-group OMs + TAC scenarios |
| 5–6 | `report/05_figs.Rmd`, `06_mackerel_projections.Rmd` | Figures and mackerel what-ifs |
| 7 | `report/finalise/00_run_all.R` | Stage figures, QA CSVs, appendix PDF |

```r
source("report/finalise/00_run_all.R")
runAll(render = FALSE)   # TRUE to re-knit stock-group Rmds first
```

Details: [`docs/WORKFLOW.md`](docs/WORKFLOW.md).

## Deliverables

| Deliverable | Location |
|-------------|----------|
| Executive summary | [`docs/executive_summary.md`](docs/executive_summary.md) |
| Main report draft | [`docs/report_main.md`](docs/report_main.md) |
| Manuscript outline | [`docs/manuscript_outline.md`](docs/manuscript_outline.md) |
| Supplementary catalogue | [`docs/supplementary/`](docs/supplementary/) |
| Beamer (full + 10 min) | [`report/beamer/`](report/beamer/) |
| TAC appendix (LaTeX) | [`report/latex/chapter_tac_simulations.tex`](report/latex/chapter_tac_simulations.tex) |
| FLR contribution candidates | [`flr-contrib/`](flr-contrib/) |

## Data (what is / isn't on GitHub)

| Shipped in `inst/extdata/` | From the web | Generated locally (gitignored `data/`) |
|----------------------------|--------------|----------------------------------------|
| Pelagic / demersal / albacore starting FLStocks | ICES SAG series + refpts (`loadSagBundle`) | Equilibria, TAC forecasts, Nephrops JABBA |
| `advice.csv` (bridge) | — | Full SS3 / SAM assessment folders |

Details: [`data/README.md`](data/README.md).

```r
loadShippedStocks("pelagics")
loadShippedStocks("demersal")
loadShippedStocks("iccat")
```

Optional env vars:

```r
Sys.setenv(RESILIENCE_ROOT = "/path/to/BIM-Resilience")
Sys.setenv(RESILIENCE_DATA = "/path/to/local-analysis-data")
```

## Design rules

- Prefer FLR generics (`FLCore`, `FLasher`, `FLBRP`, `mpb::fwd`) over one-off helpers; see [`man-src/FLR_GENERICS.md`](man-src/FLR_GENERICS.md) and [`flr-contrib/`](flr-contrib/).
- Fail fast with clear `stop()` messages; do not set `options(warn = -1)` for production knits.
- Project-specific orchestration stays in `bimResilience`; reusable methods are staged for FLCore / FLasher / etc.

## Rebuild packaged stocks

After regenerating FLStocks from local assessments:

```r
source("data-raw/ship_stocks.R")
```
