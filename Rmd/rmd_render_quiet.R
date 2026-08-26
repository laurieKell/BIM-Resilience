# Shared rmarkdown::render(quiet=...) default for this repository.
#
# Default (unset or "true"):  quiet render (fewer console messages).
# Verbose / chunk labels:     set environment variable RMD_RENDER_QUIET=false
#                               (PowerShell: $env:RMD_RENDER_QUIET = "false")
#
# Used by: report/knit_to_html.R, scripts/report_runner_helpers.R,
#          scripts/render_to_format_dirs.R, and the example block in 00_report.Rmd.

rmd_render_quiet <- function() {
  !identical(tolower(trimws(Sys.getenv("RMD_RENDER_QUIET", "true"))), "false")
}
