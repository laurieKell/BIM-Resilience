# Multi-format Knit driver for stock-group Rmds
# =============================================================================
# Rmd YAML uses:
#
#   knit: (function(inputFile, encoding) {
#     e <- new.env()
#     sys.source(file.path(dirname(normalizePath(inputFile)), "knit_to_report.R"),
#                envir = e, keep.source = FALSE)
#     e$knit_to_report(inputFile, encoding)
#   })
#
#   output:
#     html_document: ...
#     pdf_document: ...
#     word_document: ...
#
# RStudio Knit button → HTML under report/html/ (default).
# Other formats from the console (or after setting RMD_OUTPUT_FORMAT):
#
#   source("report/knit_to_report.R")
#   knit_to_report("report/01_pelagics.Rmd", format = "pdf")
#   knit_to_report("report/01_pelagics.Rmd", format = "docx")
#   render_report("report/01_pelagics.Rmd", formats = c("html", "pdf", "docx"))
#
# Env: RMD_OUTPUT_FORMAT = html | pdf | docx | word
#      RMD_RENDER_QUIET  = true | false   (see rmd_render_quiet.R)
# =============================================================================

#' Rewrite image/link URLs pointing at report/figs/ to ../figs/ relative to report/html/*.html.
#'
#' @param html_file Path to written `.html` (under report/html/).
#' @param report_dir Directory containing the `.Rmd` (normally .../report).
#' @return `html_file` invisibly
#' @noRd
fix_report_html_figure_paths <- function(html_file, report_dir) {
  if (!length(html_file) || !nzchar(html_file) || !file.exists(html_file))
    return(invisible(NULL))
  report_dir <- normalizePath(report_dir, winslash = "/", mustWork = TRUE)
  figs_dir <- normalizePath(file.path(report_dir, "figs"), winslash = "/", mustWork = FALSE)
  prefix <- paste0(figs_dir, "/")
  lines <- readLines(html_file, warn = FALSE, encoding = "UTF-8")
  swap_attr_prefix <- function(txt, attr) {
    old <- paste0(attr, "=\"", prefix)
    new <- paste0(attr, "=\"../figs/")
    gsub(old, new, txt, fixed = TRUE)
  }
  lines <- swap_attr_prefix(lines, "src")
  lines <- swap_attr_prefix(lines, "href")
  lines <- gsub("src=\"figs/", "src=\"../figs/", lines, fixed = TRUE)
  lines <- gsub("href=\"figs/", "href=\"../figs/", lines, fixed = TRUE)
  writeLines(lines, html_file, useBytes = TRUE)
  invisible(html_file)
}

#' Normalize a format name to html / pdf / docx.
#' @noRd
.normalize_report_format <- function(format) {
  if (is.null(format) || !nzchar(format)) {
    format <- Sys.getenv("RMD_OUTPUT_FORMAT", "html")
  }
  format <- tolower(trimws(as.character(format)[[1]]))
  # Accept rmarkdown format names as well as short names.
  format <- switch(format,
    "html_document" = "html",
    "pdf_document"  = "pdf",
    "word_document" = "docx",
    "word"          = "docx",
    "docx"          = "docx",
    "pdf"           = "pdf",
    "html"          = "html",
    format
  )
  if (!format %in% c("html", "pdf", "docx")) {
    stop("Unknown format '", format,
         "'. Use html, pdf, or docx (or html_document / pdf_document / word_document).",
         call. = FALSE)
  }
  format
}

#' Map short format → rmarkdown format name, output subdir, and file extension.
#' @noRd
.report_format_spec <- function(format) {
  format <- .normalize_report_format(format)
  switch(format,
    html = list(
      rmd_format = "html_document",
      out_subdir = "html",
      ext        = "html"
    ),
    pdf = list(
      rmd_format = "pdf_document",
      out_subdir = "pdf",
      ext        = "pdf"
    ),
    docx = list(
      rmd_format = "word_document",
      out_subdir = "docx",
      ext        = "docx"
    )
  )
}

#' Knit a stock-group Rmd to html, pdf, or docx under report/{html,pdf,docx}/.
#'
#' @param input_file Path to the `.Rmd`.
#' @param encoding Encoding from the RStudio Knit hook (default UTF-8).
#' @param format One of \code{"html"}, \code{"pdf"}, \code{"docx"} (or
#'   \code{"word"}). Defaults to env \code{RMD_OUTPUT_FORMAT}, else \code{"html"}.
#' @return Path to the written output file (invisibly).
#' @export
knit_to_report <- function(input_file,
                           encoding = "UTF-8",
                           format = NULL) {
  input_file <- normalizePath(input_file, winslash = "/", mustWork = TRUE)
  report_dir <- dirname(input_file)
  spec <- .report_format_spec(format)

  rq <- file.path(report_dir, "rmd_render_quiet.R")
  rq_env <- new.env()
  if (file.exists(rq))
    sys.source(rq, envir = rq_env, keep.source = FALSE)
  quiet <- if (exists("rmd_render_quiet", envir = rq_env, inherits = FALSE)) {
    rq_env$rmd_render_quiet()
  } else {
    TRUE
  }

  out_dir <- file.path(report_dir, spec$out_subdir)
  dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
  out_file <- paste0(
    tools::file_path_sans_ext(basename(input_file)),
    ".", spec$ext
  )

  knitr::opts_chunk$set(warning = FALSE, message = FALSE)
  options(warn = -1)

  rmarkdown::render(
    input_file,
    output_format = spec$rmd_format,
    encoding = encoding,
    output_dir = out_dir,
    output_file = out_file,
    quiet = quiet
  )

  out_path <- file.path(out_dir, out_file)
  if (identical(spec$ext, "html"))
    fix_report_html_figure_paths(out_path, report_dir)

  message("Wrote ", normalizePath(out_path, winslash = "/", mustWork = FALSE))
  invisible(out_path)
}

#' Knit HTML (RStudio Knit button entry point; keeps older call sites working).
#' @export
knit_to_report_html <- function(input_file, encoding = "UTF-8") {
  knit_to_report(input_file, encoding = encoding, format = "html")
}

#' Render one Rmd to one or more formats.
#'
#' @param input Path to the `.Rmd` (absolute or relative to project / cwd).
#' @param formats Character vector: any of \code{html}, \code{pdf}, \code{docx}.
#' @param encoding Passed to \code{knit_to_report()}.
#' @return Named character vector of output paths (invisibly).
#' @export
render_report <- function(input,
                          formats = c("html", "pdf", "docx"),
                          encoding = "UTF-8") {
  formats <- vapply(formats, .normalize_report_format, character(1))
  outs <- setNames(character(length(formats)), formats)
  for (i in seq_along(formats)) {
    outs[[i]] <- knit_to_report(input, encoding = encoding, format = formats[[i]])
  }
  invisible(outs)
}
