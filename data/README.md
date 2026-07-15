# Data policy for bimResilience (GitHub + local analysis)

## What ships with the package

Under `inst/extdata/` (tracked on GitHub):

| File | Used by | Contents |
|------|---------|----------|
| `pel-stks.RData` | `01_pelagics.Rmd` | Starting `FLStocks` (`stks`) |
| `dem-stks.RData` | `02_demersal.Rmd` | Starting `FLStocks` (`stks`) |
| `alb-om.RData` | `04_iccat.Rmd` | Albacore `FLStock`, `SRR`, `refpts` |
| `advice.csv` | all stock-group Rmds | Advice catch bridge (also ok to override locally) |

Load with:

```r
pel <- loadShippedStocks("pelagics")
dem <- loadShippedStocks("demersal")
alb <- loadShippedStocks("iccat")   # list(FLStock, SRR, refpts)
```

Rebuild those files after regenerating OMs:

```r
source("data-raw/ship_stocks.R")
```

## What is *not* on GitHub

The local analysis tree `data/` (~hundreds of MB) is **gitignored**. Path defaults:

```r
resiliencePaths()                 # uses <project>/data
Sys.setenv(RESILIENCE_DATA = "D:/path/to/data")
Sys.setenv(RESILIENCE_ROOT = "D:/path/to/Resilience")
```

Layout when present locally:

```
data/
├── advice/                 # local override of packaged advice.csv + ICES zips
├── inputs/                 # SS3 / SAM / optional sdGraphs CSVs (regeneration only)
│   ├── ices/sdGraphs/YYYY/ # optional cache; otherwise SAG is web-fetched
│   ├── SS/<stock>/         # rebuild FLStocks from assessments
│   └── SAM/                # rebuild SAM-based FLStocks
├── om/                     # generated OMs, JABBA, plot bundles
├── TAC/                    # generated forecast products
└── plot-objects/           # optional HTML plot caches
```

## Where each input comes from

| Need | Source |
|------|--------|
| SAG time series | Web: `icesSAG::getSAG` via `fetchSagTs()` / `loadSagBundle()` |
| SAG reference points | Web: `fetchSagRefpts()` (local sdGraphs CSV used only if present) |
| Stock master list | Code: `bimSids()` (no CSV required) |
| Starting FLStocks (01, 02, 04) | Packaged: `loadShippedStocks()` |
| Advice bridge catches | Packaged `advice.csv`, overridden by local `data/advice/advice.csv` |
| Equilibria, regimes, TAC CSVs | **Generated** by knitting the Rmds |
| Nephrops JABBA / biodyn OMs | **Generated** in `03_nephrops.Rmd` (SAG from web) |
| Full SS3 / SAM folders | Local only; needed only to *rebuild* shipped FLStocks |

## Naming convention (generated OM / TAC)

| Group    | After load stocks | After eq/regimes     | TAC scenarios |
|----------|-------------------|----------------------|---------------|
| Pelagic  | `pel-stks.RData`  | `pel-om.RData`       | `pel-fct.RData`, `csv/pel-f.csv` |
| Demersal | `dem-stks.RData`  | `dem-om.RData`       | `dem-fct.RData`, `csv/dem-f.csv` |
| Nephrops | `neph-sag.RData`  | `neph-jabba*.RData`  | `neph-fct.RData`, `csv/neph-f.csv` |
| ICCAT    | (packaged alb-om) | —                    | `iccat-fct.RData`, `csv/iccat-f.csv` |
