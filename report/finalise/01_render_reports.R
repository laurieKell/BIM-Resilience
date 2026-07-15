# =============================================================================
# 01 - Render stock-group reports to HTML (and optionally PDF / Word).
# =============================================================================
# HTML is required before staging appendix figures (02): the figure PNGs only
# exist under report/html/<name>_files/figure-html/ after an HTML knit.
#
# Usage (from the project root):
#   source("report/finalise/01_render_reports.R")
#   renderAll("html")                      # all four, HTML only
#   renderAll(c("html","pdf","docx"))      # all formats
#   renderAll("html", which = c("pel","iccat"))
#
# Or:  Rscript report/finalise/01_render_reports.R html pdf
#
# NOTE: 03_nephrops runs JABBA in parallel and is slow (minutes).
# =============================================================================

# Load shared paths unless 00_run_all (or similar) already did.
if (!exists("paths", inherits = TRUE)) {
  for (cfg in c("report/finalise/_config.R", "finalise/_config.R", "_config.R")) {
    if (file.exists(cfg)) {
      sys.source(cfg, envir = globalenv(), keep.source = FALSE)
      break
    }
  }
  if (!exists("paths", inherits = TRUE))
    stop("Cannot find _config.R; setwd to the project root.", call. = FALSE)
}

renderAll <- function(formats = "html",
                      which = names(reports)) {
  stopifnot(file.exists(paths$knitter))
  env <- new.env()
  sys.source(paths$knitter, envir = env, keep.source = FALSE)

  which <- match.arg(which, names(reports), several.ok = TRUE)
  for (key in which) {
    rmd <- reports[[key]]
    message("\n=== rendering ", basename(rmd), " -> ",
            paste(formats, collapse = ", "), " ===")
    env$render_report(rmd, formats = formats)
  }
  invisible(TRUE)
}

if (!interactive()) {
  args <- commandArgs(trailingOnly = TRUE)
  renderAll(if (length(args)) args else "html")
}
