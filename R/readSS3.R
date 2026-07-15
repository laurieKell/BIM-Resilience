#' Read an SS3 model folder into FLR objects.
#'
#' @param dir Path to an SS3 assessment directory.
#' @return List with \code{SRR}, \code{FLStock}, and \code{refpts}.
#' @export
readSS3 <- function(dir) {
  SS  = suppressMessages(SS_output(dir, printstats = FALSE))
  
  list(SRR     = suppressMessages(readFLSRss3(dir)),
       FLStock = suppressMessages(readFLSss3(dir)),
       refpts   =ss3om::readFLRPss3(dir))}
       
#refpts  = suppressMessages(ssRefpts(SS)))}

#' Extract SS3 derived-quant rows matching MSY labels (debug output optional).
#'
#' @param out SS3 list object containing `derived_quants`.
#' @param verbose If `TRUE`, print names and head of `derived_quants`.
#' @return Subset of `derived_quants` rows whose Label matches MSY.
#' @export
ssRefpts<-function(out, verbose = FALSE) {
  if (isTRUE(verbose)) {
    print(names(out$derived_quants))
    print(head(out$derived_quants))}
  
  rp_tab = out$derived_quants
  
  rp_tab[grep("MSY", rp_tab$Label), ]}