# Manuscript outline — peer-review draft

**Target outlets (either suitable):** *ICES Journal of Marine Science* or *Frontiers in Marine Science* (Marine Fisheries, Aquaculture and Living Resources / Global Change and the Future Ocean).  
**Working status:** Outline with abstract draft; figures/tables to be locked against TAC CSVs and staged LaTeX figures at submission freeze.

---

## Working title

**Deterministic productivity scenarios for short- to medium-term catch trajectories: supporting fisheries resilience analysis for Irish fleets**

*Alternative:* Biological “what-if” projections under status-quo and *F*<sub>MSY</sub> fishing: bridging ICES/ICCAT advice products to industry resilience testing

---

## Abstract draft (~200 words)

Annual fisheries advice is conditioned primarily on historical observations: assessment updates extend the time series, while benchmarks revise structure and reference points. Resilience planning for fleets, however, requires forward-looking questions—how catch and biomass respond if fishing intensity remains near recent levels while recruitment or surplus-production process error is poorer than the recent mean, or if the latest productivity regime persists. We present a shared, deterministic scenario design applied to stocks of importance to Irish fisheries: four Northeast Atlantic pelagic stocks, eight demersal stocks, eight *Nephrops* functional units (one further unit excluded after non-convergence of a surplus-production fit), and North Atlantic albacore. Operating models are assembled from ICES Stock Assessment Graphs and accepted assessment objects (SS3, SAM), with JABBA-conditioned biodynamic models for *Nephrops*. After an advice-year catch bridge, age-structured stocks are projected with FLasher through 2050 under status-quo *F*, reduced recruitment multipliers (0.75 and 0.50), *F*<sub>MSY</sub>, and a Regime residual path; *Nephrops* use analogous harvest-rate and process-error controls through 2041; albacore uses status-quo *F* with three recruitment scales. We argue that within-stock scenario gaps are more informative for resilience than absolute tonnage rankings, and that such trajectories are natural biological inputs to industry economic shock-transmission tools. Caveats include fixed fishing pressure, deterministic scalars, and assessment-vintage provisionality.

**Word count:** ~195

---

## Keywords

fisheries resilience; recruitment scenarios; *F*<sub>MSY</sub>; stock assessment; ICES; ICCAT; *Nephrops*; forward projection; FLR; industry stress-testing

---

## Authorship and contributions (placeholders)

| Role | Name / affiliation | Contribution (CRediT-style) |
|------|--------------------|------------------------------|
| Lead / corresponding | Laurence T. Kell (BIM) | Conceptualisation; methodology; software; analysis; writing — original draft |
| Co-author(s) | *TBD* | *e.g.* industry framing; CREST linkage; review |
| Co-author(s) | *TBD* | *e.g.* stock-group QC; data provision |
| Funding | BIM Resilience Project | *Grant / project code TBD* |

---

## 1. Introduction (bullet outline)

- Fisheries advice as past-conditioned: updates vs benchmarks; reference points (*B*<sub>trigger</sub>, *B*<sub>lim</sub>, *F*<sub>MSY</sub>) and status flips.
- Productivity change undermines “bounce back” narratives; resilience as persist / adapt / transform.
- Gap: advice products rarely deliver transparent, multi-stock, comparable productivity what-ifs for industry planning.
- Link to socio-economic tools (CREST): biological trajectories as inputs, not TAC recommendations.
- Objectives: (i) shared scenario table; (ii) multi-group application; (iii) interpretive rules emphasising within-stock contrasts; (iv) open methods/code.

---

## 2. Methods (subsections)

### 2.1 Stock set and data sources
- `bimSids()` master list; pelagic (4), demersal (8), *Nephrops* (9 listed / 8 projected), albacore.
- SAG (2025 vintage where used), SS3/SAM/`icesdata`, advice bridge CSV.
- Exclusion of `nep.fu.16` (JABBA non-convergence).

### 2.2 Operating models
- Age-structured FLStock assembly; packaged snapshots vs rebuild path.
- Beverton–Holt equilibria and residual regimes (`calcEqAndRegimes`).
- *Nephrops* JABBA → biodyn; process-error residual diagnostics.
- Albacore ICCAT SS3 OM.

### 2.3 Advice bridge
- Role of agreed catch advice in aligning projection start states.

### 2.4 Projection engines and horizons
- `FLasher::fwd` (ICES age-structured, albacore); `mpb::fwd` (*Nephrops*).
- Horizons: 2050 vs 2041.

### 2.5 Scenario design
- Full control table (status quo / 75% / 50% / FMSY / Regime).
- *Nephrops* PE formulation and label differences (`Fmsy`, `PE`).
- Albacore three-scale recruitment design.
- Optional: mackerel special projections as sensitivity illustrations (main text brief; details in S1).

### 2.6 Outputs and reproducibility
- Harmonised CSV schema; figure staging; GitHub package.

---

## 3. Results (subsections)

### 3.1 Diagnostics: SAG alignment and residual regimes
- Cross-group confirmation that OMs track SAG status metrics; residual polygons define Regime multipliers.

### 3.2 Pelagic catch and status paths
- Qualitative pattern description; **point to** `pel-f.csv` and forecast figures—no invented tonnes.

### 3.3 Demersal catch and status paths
- Same control table; within-stock gaps vs cross-stock scale.

### 3.4 *Nephrops* harvest-rate scenarios
- Relative catch/MSY; PE vs deterministic multipliers; FU coverage.

### 3.5 Albacore under recruitment scales
- Three-path sensitivity under status-quo *F*.

### 3.6 Cross-cutting synthesis
- Ranking stocks by *relative* exposure (scenario gap), not absolute catch.

---

## 4. Discussion (points)

- Advice vs resilience: complementary products; what-ifs do not replace HCR advice.
- Why fixed-*F* exposure paths are useful for industry stress-tests despite lacking annual feedback.
- Deterministic design as clarity trade-off vs full MSE; where stochastic PE / random recruitment fits (mackerel example).
- *B*/*B*<sub>trigger</sub> scaling caveat for *Nephrops* and implications for multi-stock dashboards.
- Assessment vintage and benchmark sensitivity—“even the past may change.”
- CREST / fleet application: prioritising which biological shocks merit economic modelling.
- Limitations and extensions: closed-loop MSE, climate-forced recruitment, multi-fleet allocation.

---

## Figures and tables (proposed)

| ID | Content | Source |
|----|---------|--------|
| Table 1 | Stock list by group with assessment type | `bimSids()` + methods |
| Table 2 | Scenario control table (held / changed / question) | TAC chapter |
| Fig. 1 | Conceptual flowchart: OM → advice bridge → scenarios → CREST | new schematic |
| Fig. 2 | Pelagic SAG vs stock and residual regimes | `report/latex/figs/pel-*.png` |
| Fig. 3 | Pelagic forecast catch by scenario | `pel-forecast-catch.png` |
| Fig. 4 | Demersal forecast catch by scenario | `dem-forecast-catch.png` |
| Fig. 5 | *Nephrops* JABBA / PE diagnostics and forecast | `neph-*.png` |
| Fig. 6 | Albacore assessment and forecast | `alb-*.png` |
| Fig. 7 | Cross-stock resilience summary (e.g. final-year scenario gap index) | derived from CSVs at freeze—**do not invent pre-freeze** |

---

## Supplementary material (list)

| Item | Description |
|------|-------------|
| S1 | Technical methods (equations, Nephrops PE, mackerel what-ifs) — see `docs/supplementary/S1_methods.md` |
| S2 | Full stock identifiers and common names |
| S3 | Forecast CSV schema and file inventory |
| S4 | Regeneration workflow (`WORKFLOW.md` / `finalise/00_run_all.R`) |
| Code S1 | `bimResilience` package and Rmds 01–06 |
| Optional | Beamer decks as communication artefacts (not peer-review core) |

---

## Target journal notes

| Journal | Fit | Notes |
|---------|-----|-------|
| **ICES Journal of Marine Science** | Strong: multi-stock ICES methods, advice–projection interface, FLR | Emphasise methods clarity, stock coverage, caveats on non-advice status; follow ICES data policy |
| **Frontiers in Marine Science** | Strong: resilience framing, industry application, open science | Suitable Research Topic on climate/resilience; abstract style already close; may allow richer CREST discussion |

**Submission checklist (later):** freeze SAG/advice vintage; regenerate CSVs and figures; replace qualitative Results with summary statistics from `takeaways.csv` / CSVs; complete references; ethics/data availability statements; author contributions.

---

## One-sentence pitch

A transparent, multi-stock scenario kit that turns advice-conditioned operating models into comparable productivity what-ifs for resilience and industry stress-testing—without pretending to be next year’s TAC.
