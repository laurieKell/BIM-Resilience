# WORKFLOW — logical notebook pipeline

End-to-end path from overview through stock-group projections to finalised TAC appendix. Run from the **project root** (folder with `DESCRIPTION` / `Resilience.Rproj`). Override roots with `RESILIENCE_ROOT` / `RESILIENCE_DATA` if needed (see `data/README.md`).

```text
00 overview  →  01 pelagics  →  02 demersal  →  03 nephrops
             →  04 iccat     →  05 figs      →  06 mackerel
             →  finalise/00_run_all.R
```

---

## 00 — Overview (logical / report narrative)

| | |
|--|--|
| **Role** | Cross-cutting framing: purpose of biological simulations, shared scenario table, how to read within-stock gaps, CREST link. |
| **Notebook / doc** | Narrative lives in `docs/report_main.md` and the TAC chapter `report/latex/chapter_tac_simulations.tex`. Narrative discussion lives in `docs/report_main.md` (and the TAC LaTeX appendix). |
| **Inputs** | Scenario design (`buildFcstCtrl` / TAC chapter); stock list `bimSids()`. |
| **Outputs** | Executive interpretation; pointers to group CSVs/figures—not new TAC numbers. |

---

## 01 — Pelagics (`report/01_pelagics.Rmd`)

| | |
|--|--|
| **Stages** | (i) Load / optionally rebuild pelagic FLStocks → (ii) update & equilibria / regimes → (iii) simulate TAC scenarios. |
| **Inputs** | Packaged `loadShippedStocks("pelagics")`; SAG bundle (`loadSagBundle`, fishery Pelagics, sagYears 2025); `advice.csv`; optional local SS3/SAM under `data/inputs/`. |
| **Key package calls** | `calcEqAndRegimes`, `buildFcstCtrl`, `runFcstCtrl`, forecast CSV builders. |
| **Outputs** | `data/om/pel-stks.RData`, `data/om/pel-om.RData`; `data/TAC/pel-fct.RData`; `data/TAC/csv/pel-f.csv`; knitr figures under `report/html/`. |
| **Horizon / scenarios** | Through 2050; five rows: FStatus Quo, 75%, 50%, FMSY, Regime. |
| **Stocks** | `boc.27.6-8`, `hom.27.2a3a4a5b6a7a-ce-k8`, `mac.27.nea`, `whb.27.1-91214`. |

---

## 02 — Demersal (`report/02_demersal.Rmd`)

| | |
|--|--|
| **Stages** | Same three-stage pattern as pelagics. |
| **Inputs** | `loadShippedStocks("demersal")`; SAG demersal bundle; advice bridge; optional local assessments. |
| **Outputs** | `data/om/dem-stks.RData`, `data/om/dem-om.RData`; `data/TAC/dem-fct.RData`; `data/TAC/csv/dem-f.csv`. |
| **Horizon / scenarios** | Through 2050; same five-row control table as pelagics. |
| **Stocks** | Eight demersal `sid`s in `bimSids()` (anglerfishes, hake, megrims, whitings). |

---

## 03 — Nephrops (`report/03_nephrops.Rmd`)

| | |
|--|--|
| **Stages** | SAG scaffold → JABBA / biodyn OMs → `buildNephOps` harvest scenarios → CSV export. |
| **Inputs** | SAG Nephrops series; advice catches for FUs; JABBA fits (generated in-notebook). |
| **Outputs** | `data/om/neph-*.RData` (SAG, JABBA, biodyn); `data/TAC/neph-fct.RData`; `data/TAC/csv/neph-f.csv`; `neph-tac-sq.csv`. |
| **Horizon / scenarios** | Projection years through **2041** (ops use harvest years 2027:2040 windowed to endYear); scenarios: FStatus Quo, 75%, 50%, Fmsy, PE. |
| **Coverage** | Eight FUs; **`nep.fu.16` excluded** (non-convergence). |
| **Note** | Closed-loop MSE helpers live under `report/wip/` and are **not** part of stage-1 TAC appendix. |

---

## 04 — ICCAT albacore (`report/04_iccat.Rmd`)

| | |
|--|--|
| **Stages** | Load albacore OM → advice bridge → status-quo *F* projections under recruitment scales. |
| **Inputs** | `loadShippedStocks("iccat")` / `alb-om.RData`; advice bridge. |
| **Outputs** | `data/TAC/iccat-fct.RData`; `data/TAC/csv/iccat-f.csv`. |
| **Horizon / scenarios** | Through 2050; status-quo *F* with recruitment multipliers 1, 0.75, 0.5. |
| **Stock** | `alb-n` (North Atlantic albacore). |

---

## 05 — Beamer figures (`report/05_figs.Rmd`)

| | |
|--|--|
| **Role** | Export PNG panels for `report/beamer/biological_simulations_slides*.tex`. |
| **Inputs** | SAG retrospectives (optional blueMarine path); forecast plot objects / OM RData; pelagic OM for mackerel panels. |
| **Outputs** | `report/beamer/fig1.png`–`fig6.png`, `fig_mac_*.png` (and related). |
| **Depends on** | Ideally 01–04 (and OM products) already run so forecast objects exist. |

---

## 06 — Mackerel special projections (`report/06_mackerel_projections.Rmd`)

| | |
|--|--|
| **Role** | Illustrative what-ifs on `mac.27.nea` under status-quo *F*, beyond the shared five-row table. |
| **Inputs** | `data/om/pel-om.RData` (from 01). |
| **Scenarios** | (i) Recruitment levels 1 / 0.75 / 0.5 / 0.25; (ii) one-off *M* shock; (iii) random recruitment ensemble. |
| **Outputs** | HTML report figures; feeds Beamer `fig_mac_*` via 05 / package helpers in `R/macProjections.R`. |
| **Not** | A replacement for `pel-f.csv` schema—supplementary illustration. |

---

## Finalise — `report/finalise/00_run_all.R`

Ordered production of the TAC appendix artefacts:

| Step | Script | Action | Writes |
|------|--------|--------|--------|
| 1 | `01_render_reports.R` | Knit stock-group Rmds (HTML needed for figures) | `report/html/` (optional pdf/docx) |
| 2 | `02_stage_figures.R` | Copy knitr PNGs to stable names | `report/latex/figs/` |
| 3 | `03_qa_tac_csv.R` | Check CSVs vs chapter claims | `report/latex/qa_report.txt` |
| 4 | `04_takeaways.R` | Final-year catch/status summaries | `report/latex/takeaways.csv` |
| 5 | `05_build_appendix.R` | Compile standalone PDF | `report/latex/tac_simulations_standalone.pdf` |

```r
source("report/finalise/00_run_all.R")
runAll(render = FALSE)   # reuse existing HTML
runAll(render = TRUE)    # full re-knit (Nephrops/JABBA is slow)
```

---

## Dependency sketch

```text
advice.csv + SAG (+ packaged FLStocks)
        │
        ├─► 01 ─► pel-om + pel-f.csv ─┬─► 05 figs ─► beamer PNGs
        ├─► 02 ─► dem-om + dem-f.csv ─┤              └─► 06 uses pel-om
        ├─► 03 ─► neph-om + neph-f.csv┤
        └─► 04 ─► iccat-f.csv ────────┘
                          │
                          └─► finalise (stage figs, QA, takeaways, PDF)
```

---

## Quick reference — forecast CSVs

| Group | File | Notes |
|-------|------|-------|
| Pelagic | `data/TAC/csv/pel-f.csv` | Five scenarios → 2050 |
| Demersal | `data/TAC/csv/dem-f.csv` | Same control table |
| Nephrops | `data/TAC/csv/neph-f.csv` | Harvest-rate scenarios → 2041; 8 FUs |
| Albacore | `data/TAC/csv/iccat-f.csv` | Three recruitment scales → 2050 |
