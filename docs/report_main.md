# Simulation of future catch paths for BIM resilience analysis

**Draft technical report**

**Author:** Laurence T. Kell  
**Affiliation:** Bord Iascaigh Mhara (BIM), Ireland  
**Companion materials:** TAC appendix (`report/latex/chapter_tac_simulations.tex`); R package `bimResilience`; repository https://github.com/laurieKell/BIM-Resilience

---

## 1. Background and objectives

Fisheries advice is designed around annual updates and periodic benchmarks. Updates extend the time series by one year under a largely fixed model structure; benchmarks revise data treatments, assumptions and reference points (*B*<sub>trigger</sub>, *B*<sub>lim</sub>, *F*<sub>MSY</sub>). Both are essential for management, but both remain anchored in historically observed productivity. When recruitment, natural mortality or spatial availability shift, past strategies can fail even if last year’s advice was correctly calculated.

The BIM Resilience Project treats resilience as the capacity of stocks *and* fleets to persist, adapt or transform when conditions change—not merely to restore a historical equilibrium. Industry and policy partners need forward trajectories that answer transparent questions: if recent fishing intensity continues and recruitment is moderately or substantially poorer; if fishing is set to *F*<sub>MSY</sub> under recent productivity; and if the latest recruitment *regime* persists.

**Objectives of this report**

1. Document a shared scenario design across pelagic, demersal, Nephrops and North Atlantic albacore stocks relevant to Irish fisheries.
2. Summarise methods for assembling operating models (OMs), bridging to the advice year, and projecting under fixed controls.
3. Provide interpretive resilience readings by stock group, pointing to figures and CSVs for quantitative detail.
4. State caveats clearly and link biological outputs to CREST for fleet-level stress-testing.

This report is **not** an ICES or ICCAT advice product and does not recommend TACs.

---

## 2. Methods

### 2.1 Operating-model assembly

For each stock group the workflow has three stages:

1. **Assemble OMs** from ICES Stock Assessment Graphs (SAG) series, accepted assessment objects (SS3, SAM, `icesdata`), and—for Nephrops—JABBA surplus-production fits conditioning biodynamic OMs (`mpb`).
2. **Bridge to the advice year** with agreed catch advice (`advice.csv`), so projections start from a common near-term state rather than the raw terminal assessment year alone.
3. **Project forward** under a fixed control table of fishing mortality (or harvest) targets and recruitment / process-error multipliers; export catch and biomass trajectories.

Starting FLStocks for pelagic, demersal and albacore runs ship with the package (`inst/extdata/`). Nephrops OMs are generated in the Nephrops notebook from SAG and JABBA. Stock identifiers and common names are centralised in `bimSids()`.

ICES age-structured stocks use `FLasher::fwd` with stock–recruit relationships fitted via Beverton–Holt equilibria (`calcEq` / `calcEqAndRegimes`). Nephrops use `mpb::fwd` on biodyn objects. Albacore uses the ICCAT SS3-conditioned FLStock with the same status-quo *F* logic under scaled recruitment deviations.

### 2.2 Shared scenario table (age-structured ICES)

Status-quo *F* is the mean of \(\bar{F}\) over the last three assessment years. Age-structured projections (pelagic, demersal, albacore) run through **2050**; Nephrops harvest-rate projections run through **2041**.

| Scenario | Held constant | Changed | Question answered |
|----------|---------------|---------|-------------------|
| FStatus Quo | Recent mean *F*; recent recruitment residual mean | — (reference) | Baseline catch/biomass if recent fishing and productivity continue |
| FStatus Quo 75% | Recent mean *F* | Recruitment residual × 0.75 | Erosion under moderately poorer recruitment |
| FStatus Quo 50% | Recent mean *F* | Recruitment residual × 0.50 | Stronger productivity shock |
| FMSY | *F*<sub>MSY</sub>; recent residual mean | Fishing intensity vs status quo | Biomass/catch under MSY fishing and recent productivity |
| Regime | *F*<sub>MSY</sub> | Latest residual *regime* replaces short-window residual mean | Paths if the current regime persists |

Control tables are built by `buildFcstCtrl()` and run by `runFcstCtrl()` in the package.

### 2.3 Nephrops and albacore variants

**Nephrops.** Scenarios are formulated in harvest-rate space. Productivity shocks use the biodyn process-error multiplier rather than a recruitment residual. Labels in `neph-f.csv`: `FStatus Quo`, `FStatus Quo 75%`, `FStatus Quo 50%`, `Fmsy`, `PE` (autocorrelated process-error noise under *F*<sub>MSY</sub> harvest). There is no `Regime` row; capitalisation of `Fmsy` differs from age-structured `FMSY`. Eight FUs are projected; `nep.fu.16` is excluded because its JABBA fit did not converge.

**Albacore.** Status-quo *F* under recruitment multipliers 1, 0.75 and 0.5 (reference, moderate and strong productivity reduction).

### 2.4 Exports

Harmonised tables: `data/TAC/csv/{pel,dem,neph,iccat}-f.csv` with columns `Scenario`, `sid`, `Year`, `Catch`, `B`, and `Btrig` (*B*/*B*<sub>trigger</sub>). Full trajectory objects: `*-fct.RData`. Diagnostic and forecast figures are staged under `report/latex/figs/` from knitr HTML output.

---

## 3. Results by group

Numeric catch levels are stock-specific and provisional under 2025 SAG inputs. **Do not treat absolute tonnes in this prose as results of record.** Read trajectories from the CSVs and compare scenario *gaps within* each stock. Figures live in `report/latex/figs/`.

### 3.1 Pelagic stocks

**Stocks:** boarfish (`boc.27.6-8`), western horse mackerel (`hom.27.2a3a4a5b6a7a-ce-k8`), Northeast Atlantic mackerel (`mac.27.nea`), blue whiting (`whb.27.1-91214`). Assessments from SS3, the 2025 mackerel FLStock, and SAM, reconciled to SAG before the advice bridge.

**Diagnostics.** SAG-versus-FLStock panels and stock–recruit residual plots (with regime polygons) establish that Regime multipliers are grounded in recent residual structure rather than arbitrary scalars.

**Resilience reading.** Compare status-quo paths under reduced recruitment (75% / 50%) with the Regime path. Where the Regime trajectory sits close to the reduced-recruitment paths, recent productivity already implies lower long-run catch than a multi-year residual mean would suggest. Where status-quo and *F*<sub>MSY</sub> diverge under the same residual mean, fishing intensity—not only recruitment—dominates the near-term status story. Tabulated paths: `data/TAC/csv/pel-f.csv`. Principal figures: `pel-sag-vs-stock.png`, `pel-rec-residuals.png`, `pel-forecast-catch.png`.

### 3.2 Demersal stocks

**Stocks:** anglerfishes, northern hake, megrims and whitings across west and northern shelf assessment areas (`anf.27.3a46`, `ank.27.78abd`, `hke.27.3a46-8abd`, `meg.27.7b-k8abd`, `meg.27.8c9a`, `mon.27.78abd`, `whg.27.47d`, `whg.27.7b-ce-k`). Inputs combine `icesdata`, SAM and SS3 (with season aggregation where required).

**Resilience reading.** The same five-row control table as the pelagics applies. Gaps between status-quo and low-recruitment (or Regime) paths indicate how exposed demersal catch and biomass are if current productivity persists or worsens. Cross-stock comparison of absolute catch is misleading; use *B*/*B*<sub>trigger</sub> within each `sid` and relative scenario ranks. CSV: `dem-f.csv`. Figures: `dem-sag-vs-stock.png`, `dem-rec-residuals.png`, `dem-forecast-catch.png`.

### 3.3 Nephrops functional units

**Units projected:** FU 11, 12, 13, 14, 15, 19, 20–21, 22. **Excluded:** FU 16 (JABBA non-convergence). SAG biomass, catch/landings and fishing pressure provide the observational scaffold; JABBA conditions biodyn OMs. Process-error residuals and regime decomposition mirror the recruitment-regime step used for age-structured stocks, but the forecast shocks are applied as process-error multipliers under status-quo harvest, plus *F*<sub>MSY</sub> and PE paths.

**Resilience reading.** Status-quo harvest with process error = 0.75 or 0.50 isolates productivity deterioration while fishing intensity stays recent. Relative catch-to-MSY panels support cross-FU comparison of *shape*; absolute landings scales still differ by FU. Treat `Btrig` in `neph-f.csv` as within-FU status relative to 1, not as a cross-FU magnitude (see caveats). A status-quo harvest extract is also written as `neph-tac-sq.csv`. Closed-loop MSE with a survey HCR remains a separate workstream. Figures: `neph-stock-ts.png` through `neph-forecast-catch.png` as listed in the TAC appendix.

### 3.4 North Atlantic albacore (ICCAT)

Northern albacore (`alb-n`) is conditioned on the ICCAT SS3 assessment. Advice catches bridge into the projection window; status-quo *F* is held forward under recruitment multipliers 1, 0.75 and 0.5.

**Resilience reading.** The three recruitment scales isolate productivity risk under current fishing intensity. Divergence among the three paths indicates how sensitive albacore catch and biomass are to sustained recruitment shortfalls—information CREST can map to tuna-related fleet exposure. CSV: `iccat-f.csv`. Figures: `alb-assessment-panels.png`, `alb-rec-residuals.png`, `alb-forecast.png`.

### 3.5 Mackerel illustrative what-ifs (supplement)

Beyond the shared pelagic table, Northeast Atlantic mackerel supports additional illustrative projections under status-quo *F*: finer recruitment levels (including ×0.25), a one-off natural-mortality shock (e.g. *M* × 5 in a single year), and random year-to-year recruitment (ensemble bands). These are developed in `06_mackerel_projections.Rmd` and Beamer panels (`fig_mac_*.png`); they illustrate shock *types* rather than expanding the harmonised TAC CSV schema.

---

## 4. Cross-cutting resilience interpretation

Across groups, three interpretive rules recur:

1. **Status-quo *F*/harvest isolates productivity.** Lower recruitment or process error with fishing held recent answers: “If we keep fishing as now and productivity worsens, what happens?”
2. ***F*<sub>MSY</sub> asks whether MSY-based fishing recovers or erodes biomass** under the same productivity assumption, judged against trigger ratios in the CSV.
3. **Regime (ICES age-structured)** substitutes the latest residual regime for the short-window residual mean—most useful when the recent decade is atypical of the whole series.

Cross-cutting conclusion for resilience planning: **relative scenario contrasts within a stock are more decision-relevant than absolute tonnage rankings across stocks.** Stocks where reduced-recruitment or Regime paths diverge sharply from the status-quo reference are priority candidates for CREST fleet stress-tests. Stocks where paths remain close under all five (or three) rows may still matter economically at scale, but biological exposure to the tested shocks is smaller.

---

## 5. Caveats and limitations

| Limitation | Implication |
|------------|-------------|
| 2025 SAG inputs where 2026 is incomplete | Near-term levels provisional; relative scenario differences more robust than absolute tonnes |
| Fishing pressure fixed after the bridge year | Paths show exposure under sustained pressure, not year-by-year advice with HCR feedback |
| Deterministic recruitment / PE scalars | Central contrasts only—no probability intervals or risk percentages |
| Nephrops `Btrig` not on a common scale across FUs | Read *B*/*B*<sub>trigger</sub> within a stock (relative to 1), not as cross-FU magnitude |
| FU 16 omitted | Completeness of Nephrops coverage is eight FUs for forecast CSVs |
| Figures regenerated from Rmd knits | Re-stage `report/latex/figs/` before locking report versions |

---

## 6. Link to CREST and industry application

CREST (Capacity, Resilience and Economic Shock Transmission) is the industry-facing layer that converts biological trajectories into fleet outcomes—value, effort and profit under shock transmission. The biological workstream does not replace CREST; it supplies the stock-side inputs and a prioritisation signal: which “what ifs” produce material gaps in catch or status and therefore merit economic modelling effort.

**Recommended use.** Import scenario catch and biomass series from `data/TAC/csv/`; stress-test fleets against within-stock gaps (status quo vs 75%/50%, Regime vs recent-mean residual, status quo vs *F*<sub>MSY</sub>); refresh after assessment and advice updates.

---

## 7. Data and code availability

- **Repository:** https://github.com/laurieKell/BIM-Resilience  
- **R package:** `bimResilience` (load with `devtools::load_all(".")` for local development)  
- **Forecast CSVs:** `data/TAC/csv/pel-f.csv`, `dem-f.csv`, `neph-f.csv`, `iccat-f.csv` (generated locally; see `data/README.md`)  
- **Appendix LaTeX:** `report/latex/chapter_tac_simulations.tex`  
- **Finalisation pipeline:** `source("report/finalise/00_run_all.R"); runAll()`  

Packaged starting stocks ship under `inst/extdata/`. Full SS3/SAM folders and the large local `data/` tree are not on GitHub (gitignore policy).

---

## 8. References (placeholders)

- ICES. Stock Assessment Graphs (SAG) and advice for the stocks listed in `bimSids()`. *ICES Advice* / Working Group reports (year-specific citations to be completed at freeze).
- ICCAT. North Atlantic albacore stock assessment (SS3). *Collective Volume of Scientific Papers* / SCRS documents (citation to be completed).
- Kell, L.T., et al. FLR packages: FLCore, FLBRP, FLasher, and related tools for simulation testing. https://flr-project.org/
- Winker, H., et al. JABBA: Just Another Bayesian Biomass Assessment (Nephrops surplus-production conditioning).
- BIM Resilience Project. Biological simulations and CREST linkage documentation (`docs/`, beamer decks under `report/beamer/`).

*Complete bibliographic entries at report freeze; align years with the SAG/advice vintage used in the CSVs.*
