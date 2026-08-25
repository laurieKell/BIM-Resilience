# FLR contribution roadmap (bimResilience)

Candidates extracted from `R/` for upstream FLR / related packages.
**Nothing here is sourced by bimResilience** — keep package code in `R/` until a PR is merged and dependencies updated.

## Target packages

| Package | Role |
|---------|------|
| **FLCore** | Core classes / methods on `FLStock`, `FLQuant`, `FLSR` |
| **FLBRP** | Equilibrium / BRP fitting (`eql`, refpts) |
| **FLasher** | Forward projection (`fwd`, `fwdControl`, `fwdWindow`) |
| **FLCandy** | Small convenience helpers over FLCore objects |
| **FLRebuild** | Regime detection (`rod`), rebuild / JABBA bridges |
| **mpb** | Biomass-dynamic / production-model `fwd` |
| **ggplotFL** | ggplot2 methods / geoms for FLR objects |
| **bimResilience-only** | Project orchestration, ICES/SAG paths, report glue |

## Function → package map

| Function (current) | Source | Target package | Status | Suggested FLR name | Rationale |
|--------------------|--------|----------------|--------|--------------------|-----------|
| `annualise` | `R/annualise.R` | **FLCore** | candidate | `annualise` | Seasonal → annual `FLStock` collapse; natural S4 method on `FLStock`. See `FLCore_annualise.R`. |
| `fsqMean` | `R/macProjections.R` | **FLCandy** or **FLCore** | candidate | `fbarMean` / `meanFbar` | Mean recent `fbar`; generic enough for any stock. |
| `calcEq` | `R/fcst.R` | **FLBRP** (or **FLRebuild**) | candidate | `eql` prior helper / `eqlBlim` | Thin BH fit with Blim→R0 prior around existing `eql()`. |
| `calcEqAndRegimes` | `R/eqRegimes.R` | bimResilience-only | project-specific | — | Orchestrates `calcEq` + FLRebuild `rod` for this project's TAC table. |
| `buildFcstCtrl` | `R/fcstCtrl.R` | **FLasher** | candidate | `fwdScenarioTable` | Builds year×scenario F / rec-dev control frame for `fwd`. |
| `runFcstCtrl` | `R/fcstCtrl.R` | **FLasher** | candidate | `fwdFromTable` | Loops control rows → `fwdControl` + `fwd`. See `FLasher_projectFixedF.R`. |
| `projectFixedF` | `R/macProjections.R` | **FLasher** | candidate | `fwdFixedF` | Single-stock fixed-F projection + constant deviance. Primed contribution file below. |
| `projectRecLevels` | `R/macProjections.R` | **FLasher** | candidate | `fwdRecLevels` | Scenario wrapper over `projectFixedF`. |
| `projectMShock` | `R/macProjections.R` | **FLasher** | candidate | `fwdMShock` | One-year M pulse then fixed-F `fwd`. |
| `projectRandomRec` | `R/macProjections.R` | **FLasher** | candidate | `fwdRandomRec` | Stochastic lognormal rec-dev iterations. |
| `simTAC` | `R/simTAC.R` | bimResilience-only | project-specific | — | Project scenario names + SAG residual multipliers. |
| `saveSimTacResults` | `R/simTAC.R` | bimResilience-only | project-specific | — | Writes project TAC artefacts / CSV layout. |
| `buildForecastTacCsv` | `R/tacCsvExports.R` | bimResilience-only | project-specific | — | BIM report CSV schema. |
| `buildNephOps` | `R/nephOps.R` | **mpb** (partial) / bimResilience-only | project-specific | `fwdScenarios` (if generalised) | Hard-coded BIM Nephrops scenarios; general harvest/`pe` loops belong in mpb examples or helpers. |
| `readSS3` | `R/readSS3.R` | bimResilience-only (thin) | already FLR (via ss3om) | — | Wrapper around `ss3om` / `r4ss`; keep local unless expanded. |
| `ssRefpts` | `R/readSS3.R` | **FLCandy** / ss3om | candidate | `ss3RefptsMSY` | MSY-label filter on SS3 `derived_quants`. |
| `loadSag*` / `fetchSag*` / `findSagGraphsCsv` / `loadAdviceFlqs` / `loadSagBundle` | `R/sagInputs.R` | bimResilience-only | project-specific | — | ICES SAG + project path conventions. |
| `plotRecResiduals` | `R/reportPlots.R` | bimResilience-only | project-specific | — | Report residual + regime polygons. |
| `plotForecastCatch` | `R/reportPlots.R` | bimResilience-only | project-specific | — | Faceted catch by BIM scenario labels. |
| `plotOptionalProjections` / `buildOptionalTsStrips` | `R/reportPlots.R` | **ggplotFL** (ideas) / bimResilience-only | project-specific | — | Depends on project `plotTs` / `projMetrics`. Prefer extending ggplotFL generics. |
| `macProjToDf` / `macProjLong` | `R/macProjections.R` | **ggplotFL** or FLCandy | candidate | `as.data.frame` metrics helper | Long Catch/SSB/F/Rec table from named stocks. |
| `plotMacMetrics` / `plotMacMetricsStochastic` | `R/macProjections.R` | **ggplotFL** | candidate | `plotMetrics` / `plotMetricsBand` | 2×2 metric panels; generalise labels away from “mac”. |
| `unpackFcstScenarios` / `assertAfterEquilibrium` / `saveGroupPlotBundle` | `R/reportPlots.R` | bimResilience-only | project-specific | — | Report workflow glue. |
| `bimSids` / paths / shipped data | `R/sids.R`, `R/paths.R`, … | bimResilience-only | project-specific | — | Stock list and filesystem layout. |
| `eql`, `rod`, `fwd` (mpb), ggplotFL `plot` / `geom_flpar` | dependencies | already FLR | already FLR | — | Prefer these generics; do not reimplement. |

## Contribution order (suggested)

1. **FLCore `annualise`** — self-contained, high reuse for seasonal stocks (`FLCore_annualise.R`).
2. **FLasher `fwdFixedF` (+ optional table runner)** — documents the projectFixedF / runFcstCtrl pattern (`FLasher_projectFixedF.R`).
3. **FLasher scenario helpers** — `fwdRecLevels`, `fwdMShock`, `fwdRandomRec` once fixed-F lands.
4. **FLBRP / FLRebuild** — expose Blim-prior `eql` helper; leave regime table assembly in bimResilience.
5. **ggplotFL** — generalise metric long-table + band plots (drop mackerel-specific names).
6. **mpb** — only if Nephrops scenario builder is generalised beyond BIM labels.

## PR destinations

| Candidate file | Upstream |
|----------------|----------|
| `FLCore_annualise.R` | https://github.com/flr/FLCore |
| `FLasher_projectFixedF.R` | https://github.com/flr/FLasher |

When contributing: match FLR roxygen / S4 style, add tests under the package’s `tests/`, and keep bimResilience calling the upstream method once released (thin re-export or Depends bump).
