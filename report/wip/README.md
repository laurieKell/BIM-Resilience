# Stage 2 (work in progress): MSE with feedback

This folder holds code for the **second stage** of the Resilience project: a
closed-loop **management-strategy evaluation (MSE) with feedback**. It is kept
separate from the stage-1 reports so that stage 1 can be finished and knitted on
its own.

## Stage 1 vs stage 2

- **Stage 1 (finished / in `report/`)** — deterministic TAC scenario
  projections for each stock group (`01_pelagics.Rmd`, `02_demersal.Rmd`,
  `03_nephrops.Rmd`, `04_iccat.Rmd`). These produce the `*-fct.RData` objects
  and the harmonised `data/TAC/csv/*-f.csv` tables. None of them source anything
  in this folder.
- **Stage 2 (this folder)** — a survey-HCR MSE loop that observes the operating
  model with error, applies a harvest-control rule, and feeds the resulting TAC
  back into the projection each year.

## Files

- `nephMseFeedback.R` — the MSE-with-feedback helpers:
  - `runNephMse()` — the closed-loop survey-HCR MSE across the Nephrops
    operating models. Requires an HCR passed as `hcrFunction`
    (e.g. `bimResilience::hcrSurvey`).
  - `buildNephMseTs()` / `buildNephMseCsvTable()` — long-format MSE time series
    and the `neph-mse.csv` table (shares the `*-mse.csv` schema).
  - `buildMseTacCsv()` — generic `*-mse.csv` builder.
  - `summariseNephMse()` — risk and catch-variability summaries.

## Picking up stage 2

Source `report/wip/nephMseFeedback.R` from the future MSE report and supply an
HCR. `buildNephOps()` (stage 1, in `report/helpers/nephOps.R`) still produces the
`PE` operating model that `runNephMse()` consumes.
