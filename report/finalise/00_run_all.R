# =============================================================================
# 00 - Run the full finalisation pipeline in order.
# =============================================================================
# 1. Render all reports to HTML (needed for figures).
# 2. Stage appendix figures into report/latex/figs/.
# 3. QA the TAC CSVs (writes report/latex/qa_report.txt).
# 4. Derive scenario takeaways (writes report/latex/takeaways.csv).
# 5. Build the standalone appendix PDF.
#
# Usage (from the project root):
#   source("report/finalise/00_run_all.R")
#   runAll()                       # HTML render + everything
#   runAll(render = FALSE)         # skip re-knitting; reuse existing HTML
#   runAll(formats = c("html","pdf","docx"))
#
# Or:  Rscript report/finalise/00_run_all.R
#
# WARNING: rendering runs JABBA for Nephrops and is slow. Use render = FALSE to
# rerun only the QA / figure / build steps against existing HTML output.
# =============================================================================

finaliseDir <- local({
  a <- commandArgs(FALSE)
  f <- sub("^--file=", "", a[grepl("^--file=", a)])
  if (length(f)) dirname(normalizePath(f))
  else if (dir.exists(file.path(getwd(), "report/finalise"))) file.path(getwd(), "report/finalise")
  else getwd()
})

sys.source(file.path(finaliseDir, "_config.R"), envir = globalenv(), keep.source = FALSE)
sys.source(file.path(finaliseDir, "01_render_reports.R"), envir = globalenv(), keep.source = FALSE)
sys.source(file.path(finaliseDir, "02_stage_figures.R"),  envir = globalenv(), keep.source = FALSE)
sys.source(file.path(finaliseDir, "03_qa_tac_csv.R"),     envir = globalenv(), keep.source = FALSE)
sys.source(file.path(finaliseDir, "04_takeaways.R"),      envir = globalenv(), keep.source = FALSE)
sys.source(file.path(finaliseDir, "05_build_appendix.R"), envir = globalenv(), keep.source = FALSE)

runAll <- function(render = TRUE, formats = "html") {
  if (render) {
    message("\n########## 1/5 render reports ##########")
    renderAll(formats)
  } else {
    message("\n########## 1/5 render reports (SKIPPED) ##########")
  }
  message("\n########## 2/5 stage figures ##########");   stageFigures()
  message("\n########## 3/5 QA TAC CSVs ##########");      qaTacCsv()
  message("\n########## 4/5 takeaways ##########");        takeaways()
  message("\n########## 5/5 build appendix PDF ##########"); buildAppendix()
  message("\nDone. See report/latex/ for qa_report.txt, takeaways.csv, and the PDF.")
  invisible(TRUE)
}

if (!interactive()) runAll()
