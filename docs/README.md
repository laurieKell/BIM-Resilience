# BIM Resilience — documentation index

Professional documentation for the BIM fisheries resilience biological simulations. Content is grounded in the TAC appendix (`report/latex/chapter_tac_simulations.tex`), the stock-group R Markdown workflows, and the `bimResilience` R package.

| Document | Audience | Purpose |
|----------|----------|---------|
| [executive_summary.md](executive_summary.md) | BIM / industry / policy | Short briefing on purpose, stocks, scenarios, key messages, caveats, and CREST use |
| [report_main.md](report_main.md) | Technical readers / report draft | Full draft report with filled methods, group results, cross-cutting interpretation |
| [manuscript_outline.md](manuscript_outline.md) | Academic authors | Peer-review manuscript outline (ICES JMS / Frontiers-style) |
| [WORKFLOW.md](WORKFLOW.md) | Analysts | Logical notebook pipeline: inputs and outputs per step |
| [supplementary/README.md](supplementary/README.md) | Reproducibility | Catalogue of supplementary materials and how to regenerate |
| [supplementary/S1_methods.md](supplementary/S1_methods.md) | Modellers | Technical methods: scenario equations, Nephrops PE, mackerel what-ifs |

## Related project locations

| Path | Contents |
|------|----------|
| `report/00_overview.Rmd` … `06_mackerel_projections.Rmd` | Pipeline entry + stock-group and figure notebooks |
| `report/latex/chapter_tac_simulations.tex` | TAC simulations appendix (canonical scenario narrative) |
| `report/latex/figs/` | Staged forecast/diagnostic figures |
| `data/TAC/csv/` | Harmonised forecast CSVs (`pel-f`, `dem-f`, `neph-f`, `iccat-f`) |
| `report/beamer/` | Biological-simulations slide decks |
| `report/finalise/00_run_all.R` | End-to-end finalisation (render → stage → QA → PDF) |
| https://github.com/laurieKell/BIM-Resilience | Code and packaged starting stocks |

## How to use these docs

1. Start with the **executive summary** for the policy/industry message.
2. Use **report_main** for a complete narrative draft suitable for pasting into the parent Resilience Report.
3. Use **WORKFLOW** and the **supplementary** catalogue when regenerating numbers or figures.
4. Do not treat absolute catch levels in prose as advice; read quantitative paths from the TAC CSVs and compare scenarios *within* each stock.
