# Finalising the TAC simulations appendix (all in R)

Scripts to finalise `chapter_tac_simulations.tex` and build the standalone
appendix PDF. Everything here is R — no Python, no PowerShell required.

Run from the **project root** (the folder with `DESCRIPTION` / `Resilience.Rproj`).
Override with `Sys.setenv(RESILIENCE_ROOT = "...")` if needed.

## Scripts

| Script | Does | Writes |
|---|---|---|
| `_config.R` | Shared paths, report list, expected Nephrops FUs. Sourced by the rest. | — |
| `01_render_reports.R` | Knit the four Rmds to HTML (and optionally PDF/Word). | `report/html/`, `report/pdf/`, `report/docx/` |
| `02_stage_figures.R` | Copy knitr PNGs into the appendix figs folder (stable names). | `report/latex/figs/` |
| `03_qa_tac_csv.R` | Check the TAC CSVs against the chapter's claims; flag mismatches. | `report/latex/qa_report.txt` |
| `04_takeaways.R` | Final-year catch/status per sid & scenario, to ground the prose. | `report/latex/takeaways.csv` |
| `05_build_appendix.R` | Stage figures + compile the standalone PDF (tinytex or pdflatex). | `report/latex/tac_simulations_standalone.pdf` |
| `00_run_all.R` | Run all of the above in order. | all of the above |

Quick start (reuse existing HTML, skip the slow re-knit):

```r
source("report/finalise/00_run_all.R")
runAll(render = FALSE)
```

Full run from scratch:

```r
source("report/finalise/00_run_all.R")
runAll(render = TRUE, formats = "html")   # HTML needed for figures
```

Individual steps:

```r
source("report/finalise/03_qa_tac_csv.R"); qaTacCsv()
source("report/finalise/04_takeaways.R");  takeaways()
```

## Finalisation checklist

Content/accuracy (applied to `chapter_tac_simulations.tex`; verify against
`qa_report.txt`):

- [x] **Nephrops FU count.** Chapter now states 8 FUs projected and notes
      `nep.fu.16` excluded (JABBA non-convergence).
- [x] **Nephrops scenario labels.** Prose now matches the CSV labels
      (`FStatus Quo`, `FStatus Quo 75%`, `FStatus Quo 50%`, `Fmsy`, `PE`),
      corrects the 75%/50% meaning (process-error multiplier, not a harvest
      cut), and flags the `Fmsy` vs `FMSY` capitalisation difference.
- [x] **Nephrops horizon.** Chapter now states Nephrops runs to 2041, others to
      2050 (in the scenario text and the data-pointers table).
- [x] **Btrig anomaly.** Added a caveat that `Btrig` is not on a common scale
      across FUs; read it within-stock. *Still needs a root-cause decision:*
      verify the per-FU B/Btrig scaling, then remove/soften the caveat.
- [ ] Confirm takeaway sentences (pelagic/demersal resilience) against
      `takeaways.csv` numbers.

Readability (the suggested edits — already present in the chapter):

- [x] Plain-language framing paragraph near the top.
- [x] Scenario table states held constant / changed / question answered.
- [x] Interpretive sentence each for pelagics and demersals.
- [x] Caveats state limitation **and** implication.
- [x] Key-message bullets for non-modelling readers.

Production:

- [ ] Re-knit HTML so figures are current (`01`).
- [ ] Stage figures (`02`) and confirm none reported MISSING.
- [ ] Confirm captions/callouts/CSV references align.
- [ ] Build the PDF (`05`) and skim it.
- [ ] Paste the finalised chapter into `Resilience Report V8.0.docx` as the
      appendix (or attach the PDF).
```
