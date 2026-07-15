# bimResilience

R package and stock-group workflows for BIM fisheries resilience analysis.

## Install

```r
# remotes::install_github("YOUR_ORG/bimResilience")
devtools::load_all(".")   # local development
```

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

Optional env vars (override discovery; no machine-specific default):

```r
Sys.setenv(RESILIENCE_ROOT = "/path/to/BIM-Resilience")
Sys.setenv(RESILIENCE_DATA = "/path/to/local-analysis-data")
```

If unset, the project root is found by walking up from the Rmd / working directory
until `DESCRIPTION`, `R/`, and `report/` are present.

## Reports

```r
source("report/finalise/00_run_all.R")
runAll(render = FALSE)   # or render = TRUE to re-knit
```

## Rebuild packaged stocks

After regenerating FLStocks from local assessments:

```r
source("data-raw/ship_stocks.R")
```
