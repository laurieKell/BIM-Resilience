# FLR generics vs project helpers

## Rule

Prefer **existing FLCore / FLasher / FLBRP / FLRebuild / ggplotFL / mpb generics**
over one-off helpers. Before adding a new exported function in bimResilience:

1. Check whether an FLR method already does the job (`fwd`, `fwdControl`,
   `fwdWindow`, `eql`, `rod`, `ssb`, `fbar`, `computeCatch`, ggplotFL `plot`, …).
2. If the logic is reusable beyond this report, sketch it under `flr-contrib/`
   and contribute upstream instead of growing a parallel API.
3. Keep bimResilience wrappers thin: project paths, ICES/SAG I/O, scenario
   labels, and report artefact layout.

## Prefer upstream (call, don’t reimplement)

| Capability | Prefer |
|------------|--------|
| Forward projection | `FLasher::fwd`, `fwdControl`, `fwdWindow` |
| Equilibrium / BRP | `FLBRP::eql`, refpts accessors |
| Regime residuals | `FLRebuild::rod` |
| Biomass-dynamic fwd | `mpb::fwd` |
| Stock metrics / plots | FLCore accessors + `ggplotFL::plot` / `geom_flpar` |
| Seasonal collapse | contribute `annualise` → FLCore (see `flr-contrib/`) |

## Remain project-specific in bimResilience

These stay local even if pieces inspire FLR PRs:

- **SAG / advice I/O** — `loadSagBundle`, `fetchSagTs`, `loadSagRefpts`, `loadAdviceFlqs`, path helpers
- **Stock catalogue** — `bimSids`, shipped OM loaders
- **TAC report pipeline** — `simTAC`, `saveSimTacResults`, `buildForecastTacCsv`, `buildFcstCtrl` scenario labels
- **Equilibrium orchestration** — `calcEqAndRegimes` (wires `calcEq` + `rod` for this workflow)
- **Nephrops OM scenarios** — `buildNephOps` (BIM scenario names / PE defaults)
- **Report plot glue** — `plotRecResiduals`, `plotForecastCatch`, `saveGroupPlotBundle`, `unpackFcstScenarios`, `assertAfterEquilibrium`
- **Mackerel presentation plots** — `plotMacMetrics*`, `macProjToDf` (until generalised into ggplotFL)

Contribution candidates and rename suggestions: `flr-contrib/README.md`.
