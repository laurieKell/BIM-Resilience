# Executive summary: biological simulations for fisheries resilience

**BIM Resilience Project**  
**Author:** Laurence T. Kell (BIM)  
**Scope:** Deterministic short- to medium-term catch and biomass trajectories under shared productivity and fishing-intensity scenarios. This is **not** ICES or ICCAT advice and does not recommend TACs for the coming year.

---

## Purpose

Annual stock advice is largely conditioned on the past: update peels add one year’s data; benchmarks periodically reset assumptions and reference points. Resilience planning asks a different question—what happens if fishing pressure stays near recent levels while recruitment or productivity is poorer than the recent mean, or if the latest productivity regime persists?

These biological simulations supply transparent, comparable “what-if” trajectories that CREST (Capacity, Resilience and Economic Shock Transmission) can carry through to fleet value, effort and profit. The aim is exposure diagnosis under sustained controls, not a prediction of what managers will decide year by year.

## Stocks covered

| Group | Coverage | Projection horizon |
|-------|----------|--------------------|
| **Pelagic** | 4 stocks: boarfish, western horse mackerel, Northeast Atlantic mackerel, blue whiting | through 2050 |
| **Demersal** | ~8 stocks: anglerfishes, northern hake, megrims, whitings (west / northern shelf) | through 2050 |
| **Nephrops** | 8 functional units (FU 11, 12, 13, 14, 15, 19, 20–21, 22); FU 16 excluded (JABBA non-convergence) | through 2041 |
| **ICCAT** | North Atlantic albacore | through 2050 |

Operating models are assembled from ICES Stock Assessment Graphs (SAG), accepted assessment objects (SS3, SAM, `icesdata`), and—for Nephrops—JABBA surplus-production fits. An advice-year bridge aligns projections to a common near-term state.

## Scenario design (shared logic)

Age-structured ICES stocks (pelagic and demersal) share one control table:

| Scenario | Fishing intensity | Productivity assumption | Question |
|----------|-------------------|-------------------------|----------|
| **FStatus Quo** | Recent mean *F* (last 3 assessment years) | Recent recruitment residual mean | Baseline if recent fishing and productivity continue |
| **FStatus Quo 75%** | Same status-quo *F* | Residual × 0.75 | Moderate recruitment shortfall under current fishing |
| **FStatus Quo 50%** | Same status-quo *F* | Residual × 0.50 | Stronger productivity shock |
| **FMSY** | *F*<sub>MSY</sub> | Recent residual mean | Does MSY-based fishing improve or worsen biomass under recent productivity? |
| **Regime** | *F*<sub>MSY</sub> | Latest stock–recruit residual *regime* | If the current regime persists, how do paths differ from the multi-year residual mean? |

Nephrops use the same *logic* in harvest-rate / process-error space (status-quo harvest with process-error multipliers 1, 0.75, 0.50; *F*<sub>MSY</sub> harvest; and an autocorrelated process-error path). Albacore reports status-quo *F* under recruitment multipliers 1, 0.75 and 0.5. Tabulated paths live in `data/TAC/csv/`; figures in `report/latex/figs/`.

## Key messages

1. **Advice is past-conditioned; resilience needs future what-ifs.** Update and benchmark cycles describe status relative to reference points; they do not by themselves stress-test industry exposure to poorer recruitment or a persistent low-productivity regime.
2. **Within-stock scenario gaps matter more than absolute tonnes.** Catch scales differ widely between stocks. The vertical gap between scenario lines is the effect of the assumption that changed. Use *B*/*B*<sub>trigger</sub> in the CSVs to judge status *within* a stock.
3. **Status-quo *F* with lower recruitment** asks: if we keep fishing as now and productivity worsens, what happens to catch and biomass? **Regime** asks whether recent productivity already implies materially different long-run paths than the short-window residual mean.
4. **CREST is the industry link.** Biological trajectories are inputs to fleet-level shock transmission—not an answering machine for next year’s TAC. Stress-testing should use these paths to prioritise which industry “what ifs” warrant further modelling effort.

## Caveats (read before using numbers)

- **Fixed fishing pressure** after the advice bridge: no annual HCR feedback in these stage-1 runs (a separate Nephrops MSE stream is staged elsewhere). Paths show exposure under *sustained* pressure.
- **Deterministic scalars**, not stochastic ensembles: figures show central scenario contrasts, not probability intervals or risk percentages.
- **2025 SAG inputs** where 2026 assessments are incomplete: near-term absolute levels are provisional; relative scenario differences are more robust.
- **Nephrops *B*/*B*<sub>trigger</sub> scaling** is not comparable across functional units in the CSV (values can range from near zero to very large between FUs). Read status relative to 1 *within* each FU until per-FU scaling is reconciled.
- **FU 16** is not in the Nephrops forecast CSV.

## Recommendation

CREST and industry partners should use these biological trajectories as the standard stress-test inputs for fleet outcomes: compare status-quo versus reduced-recruitment (and Regime / *F*<sub>MSY</sub>) paths *within* each stock, then propagate catch and biomass series into economic and capacity modules. Treat absolute tonnes as indicative of scale, not as advice; refresh when 2026 assessments and advice bridges are final.

**Code and data pointers:** https://github.com/laurieKell/BIM-Resilience · TAC appendix `report/latex/chapter_tac_simulations.tex` · CSVs under `data/TAC/csv/`.
