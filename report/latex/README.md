# LaTeX draft: TAC simulations chapter

## Files

| File | Role |
|------|------|
| `chapter_tac_simulations.tex` | Chapter body (`\chapter{...}`) for `\input` into the parent report |
| `tac_simulations_standalone.tex` | Thin wrapper to compile the chapter alone |
| `figs/*.png` | Staged knitr figures (stable names) |

Figure staging, QA, and the PDF build are all driven from R in
`report/finalise/` (see that folder's `README.md`).

## Compile (standalone)

All in R (stages figures, then compiles):

```r
source("report/finalise/05_build_appendix.R"); buildAppendix()
```

Or by hand:

```bat
cd C:\active\Resilience\report\latex
pdflatex tac_simulations_standalone
pdflatex tac_simulations_standalone
```

## Include in a parent report

```latex
\graphicspath{{report/latex/figs/}}  % adjust relative to the master .tex
\input{report/latex/chapter_tac_simulations}
```

## Refresh figures

Re-knit the stock-group Rmds (to HTML), then stage the PNGs in R:

```r
source("report/finalise/02_stage_figures.R"); stageFigures()
```
