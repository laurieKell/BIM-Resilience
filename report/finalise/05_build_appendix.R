# =============================================================================
# 05 - Build the standalone appendix PDF (figure staging + LaTeX compile).
# =============================================================================
# Stages figures (script 02), then compiles tac_simulations_standalone.tex to
# PDF. Uses tinytex if available, else a pdflatex on PATH (run twice for refs).
#
# Usage:
#   source("report/finalise/05_build_appendix.R"); buildAppendix()
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
if (!exists("stageFigures", mode = "function")) {
  for (stg in c("report/finalise/02_stage_figures.R", "02_stage_figures.R")) {
    if (file.exists(stg)) {
      sys.source(stg, envir = globalenv(), keep.source = FALSE)
      break
    }
  }
}

buildAppendix <- function(texFile = "tac_simulations_standalone.tex") {
  if (exists("stageFigures", mode = "function")) stageFigures()

  tex <- file.path(paths$latex, texFile)
  if (!file.exists(tex)) stop("LaTeX source not found: ", tex, call. = FALSE)

  wd <- getwd(); on.exit(setwd(wd), add = TRUE)
  setwd(paths$latex)

  if (requireNamespace("tinytex", quietly = TRUE)) {
    message("Compiling with tinytex::latexmk ...")
    pdf <- tinytex::latexmk(basename(tex), engine = "pdflatex")
  } else {
    pdflatex <- Sys.which("pdflatex")
    if (!nzchar(pdflatex))
      stop("Neither the 'tinytex' package nor a 'pdflatex' binary is available. ",
           "Install tinytex (install.packages('tinytex'); tinytex::install_tinytex()) ",
           "or a LaTeX distribution.", call. = FALSE)
    message("Compiling with pdflatex on PATH (two passes) ...")
    for (pass in 1:2) {
      st <- system2(pdflatex,
                    c("-interaction=nonstopmode", "-halt-on-error", basename(tex)),
                    stdout = TRUE, stderr = TRUE)
      status <- attr(st, "status")
      if (!is.null(status) && status != 0) {
        cat(tail(st, 30), sep = "\n")
        stop("pdflatex failed on pass ", pass, ".", call. = FALSE)
      }
    }
    pdf <- sub("\\.tex$", ".pdf", basename(tex))
  }
  message("Wrote ", normalizePath(file.path(paths$latex, basename(pdf)),
                                  winslash = "/", mustWork = FALSE))
  invisible(file.path(paths$latex, basename(pdf)))
}

if (!interactive()) buildAppendix()
