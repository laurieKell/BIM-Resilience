# Report pipeline

Numbered notebooks under this folder form the biological-simulation workflow.

| File | Purpose |
|------|---------|
| `00_overview.Rmd` | Entry point, reproducibility checklist |
| `01_pelagics.Rmd` | Pelagic ICES stocks → `data/TAC/csv/pel-f.csv` |
| `02_demersal.Rmd` | Demersal ICES stocks → `dem-f.csv` |
| `03_nephrops.Rmd` | Nephrops FUs (JABBA / biodyn) → `neph-f.csv` |
| `04_iccat.Rmd` | NA albacore → `iccat-f.csv` |
| `05_figs.Rmd` | Shared / presentation figures |
| `06_mackerel_projections.Rmd` | Mackerel recruitment / M-shock / random-rec what-ifs |
| `ensureBimResilience.R` | Path bootstrap + `devtools::load_all` |
| `knit_to_report.R` | Knit helper (HTML / PDF / Word) |
| `finalise/` | Stage figures, QA, takeaways, appendix PDF |
| `latex/` | TAC appendix chapter + standalone PDF |
| `beamer/` | Full and 10-minute slide decks |
| `wip/` | Experimental (not part of the locked pipeline) |

Narrative drafts live in `docs/` (not duplicated here).

```r
source("report/finalise/00_run_all.R")
runAll(render = FALSE)
```
