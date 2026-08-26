# FLR generics vs project helpers

## Rule

Prefer **FLBacktest / FLCore / FLasher / FLBRP / ggplotFL / mpb** generics
over one-off helpers. BIM Resilience and [backtest-ices](https://github.com/laurieKell/backtest-ices)
share the same engine ([FLBacktest](https://github.com/laurieKell/FLBacktest)).

Before adding an exported function here:

1. Check FLBacktest (`fwdFbar`, `annualise`, `cleanStock`, `srResiduals`, …).
2. Check upstream FLR (`fwd`, `eql`, `rod`, ggplotFL `plot`).
3. If reusable beyond this report, add it to FLBacktest (not a local copy).
4. Keep bimResilience for BIM scenario labels, SAG I/O, and report artefacts.

Details: [`docs/app_vs_package.md`](../docs/app_vs_package.md).

## Prefer (call, don’t reimplement)

| Capability | Prefer |
|------------|--------|
| Constant-\(F\) projection | `FLBacktest::fwdFbar` / `fwdFmsy` |
| Seasonal collapse | `FLBacktest::annualise` |
| Equilibrium / BRP | `FLBRP::eql` / `icesdata::eql` |
| Regime residuals | `FLRebuild::rod` (+ `FLBacktest::srResiduals`) |
| Biomass-dynamic fwd | `mpb::fwd` |
| Stock metrics / plots | FLCore accessors + `ggplotFL::plot` |

## Remain project-specific in bimResilience

- SAG / advice I/O — `loadSagBundle`, path helpers
- Stock catalogue — `bimSids`, shipped OM loaders
- BIM TAC scenario labels — `buildFcstCtrl`, `simTAC`, CSV layout
- Equilibrium orchestration for this report — `calcEqAndRegimes`
- Nephrops OM scenarios — `buildNephOps`
- Beamer metric panels — `plotMacMetrics*` (presentation glue)
