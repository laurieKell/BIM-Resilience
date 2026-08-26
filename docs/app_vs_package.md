# BIM Resilience application vs FLBacktest (shared with blueMarine)

**Design rule (same as blueMarine):**  
**Package = generic engine on FLR classes.**  
**Application = data, scenario labels, report narrative.**

| Concern | **FLBacktest** (`C:/active/flr/backtest`) | **bimResilience** (this repo) | **blueMarine** |
|---------|-------------------------------------------|--------------------------------|----------------|
| Constant-\(F\) `fwd` | `fwdFbar()`, `fwdFmsy()` | Call via `runFcstCtrl()` | Open-loop / gate |
| Seasonal → annual | `annualise()` | Call for northern hake | — |
| SR residuals on FLBRP | `srResiduals()` | Prefer over ad-hoc `exp(residuals)` | OM conditioning |
| Stock cleaning for `fwd` | `cleanStock()` | Call when rebuilding OMs | `02.0` |
| HCR / backtest / rebuild | `hcrICES`, `backtest`, `project_hcr` | Not used in TAC appendix | Core pipeline |
| BIM scenario labels | — | `buildFcstCtrl` (FStatus Quo, …) | — |
| SAG / advice bridge | — | `loadSagBundle`, `advice.csv` | stocks.csv / SAG |
| Report figures / CSVs | — | `saveSimTacResults`, plot glue | `06.*` |

## What was removed from bimResilience

| Former helper | Replacement |
|---------------|-------------|
| `projectFixedF` | `FLBacktest::fwdFbar` |
| `fsqMean` | `mean(c(fbar(stk)[, …]))` at the call site |
| `annualise` (local copy) | `FLBacktest::annualise` |

Thin wrappers that remain (`projectRecLevels`, `projectMShock`, `projectRandomRec`) only encode beamer layouts; each calls `fwdFbar`.

## Prototypes vs pipeline

`FLCandy` is **not** a dependency of this app. Use it only for local prototypes. Anything needed in the TAC / report pipeline belongs in **FLBacktest**, **FLRebuild**, **icesdata**, or (thin) bimResilience glue.

## Sibling apps

- blueMarine: https://github.com/laurieKell/blueMarine  
- FLBacktest: https://github.com/laurieKell/FLBacktest  
- This app: https://github.com/laurieKell/BIM-Resilience  

See also `FLBacktest` `SHARED.md` and blueMarine `docs/app_vs_package.md`.
