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

local({
  findConfig <- function() {
    a <- commandArgs(FALSE)
    f <- sub("^--file=", "", a[grepl("^--file=", a)])
    cands <- c(
      if (length(f)) file.path(dirname(normalizePath(f)), "_config.R"),
      file.path(getwd(), "report/finalise/_config.R"),
      file.path(getwd(), "finalise/_config.R"),
      file.path(getwd(), "_config.R"),
      "C:/active/Resilience/report/finalise/_config.R"
    )
    hit <- cands[file.exists(cands)]
    if (!length(hit)) stop("_config.R not found; run from project root.", call. = FALSE)
    hit[1]
  }
  sys.source(findConfig(), envir = globalenv(), keep.source = FALSE)
})

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
