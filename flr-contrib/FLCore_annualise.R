# Candidate contribution: annualise() as FLStock S4 method
#
# PR target: https://github.com/flr/FLCore
# Suggested placement: R/FLStock.R (or R/season.R) + NAMESPACE entries for
#   export(annualise) and the S4 method registration.
# Do not source this file from bimResilience; keep the working copy in R/annualise.R
# until an upstream release is available.

#' Collapse a seasonal FLStock into annual totals / means
#'
#' Sums abundance, catch, landings, discards, and M over seasons (and units),
#' reconstructs start-of-year numbers from end-of-year \eqn{N} and mean
#' \eqn{M} / \eqn{F}, and recomputes biomass-weighted mean weights and maturity.
#'
#' @param object An \code{FLStock} with one or more seasons.
#' @param ... Not used; present for S4 consistency.
#'
#' @return An \code{FLStock} with a single season dimension and recomputed
#'   \code{catch}, \code{landings}, \code{discards}, and \code{stock} totals.
#'
#' @seealso \code{\link[FLCore]{expand}}, \code{\link[FLCore]{seasonSums}},
#'   \code{\link[FLCore]{unitSums}}
#'
#' @examples
#' \dontrun{
#' data(ple4)
#' # If ple4 were seasonal:
#' # annualise(ple4)
#' }
#'
#' @export
setGeneric("annualise", function(object, ...) standardGeneric("annualise"))

#' @rdname annualise
#' @export
setMethod("annualise", signature(object = "FLStock"),
  function(object, ...) {

    if (!is(object, "FLStock"))
      stop("object must be an FLStock.", call. = FALSE)

    dms <- dim(object)
    if (any(!is.finite(dms)) || length(dms) < 6L)
      stop("object has invalid dims(); expected a full FLStock.", call. = FALSE)

    nseason <- dms[[4L]]
    if (nseason < 1L)
      stop("object has no season dimension (dim 4 < 1).", call. = FALSE)

    # ADD slots (catch / landings / discards numbers, m, harvest, …)
    res <- qapply(object, function(s) unitSums(seasonSums(s)))

    .wtMean <- function(wt, n, label) {
      num <- unitSums(seasonSums(wt * n))
      den <- unitSums(seasonSums(n))
      out <- num / den
      # Non-zero weight mass with empty numbers ⇒ undefined mean
      if (any(den == 0 & num != 0, na.rm = TRUE) ||
          any(!is.finite(c(out)) & c(num) != 0, na.rm = TRUE))
        stop("Cannot form biomass-weighted ", label,
             ": zero or missing numbers where weight is non-zero.",
             call. = FALSE)
      if (any(!is.finite(c(out))))
        stop("Non-finite values in biomass-weighted ", label, ".",
             call. = FALSE)
      out
    }

    catch.wt(res)[]    <- .wtMean(catch.wt(object),    catch.n(object),    "catch.wt")
    landings.wt(res)[] <- .wtMean(landings.wt(object), landings.n(object), "landings.wt")
    discards.wt(res)[] <- .wtMean(discards.wt(object), discards.n(object), "discards.wt")
    stock.wt(res)[]    <- .wtMean(stock.wt(object),    stock.n(object),    "stock.wt")

    # RECONSTRUCT N at start of year from last-season N: N0 = N_end / exp(-M - F)
    stkn <- unitSums(stock.n(object)[,,, nseason])
    if (any(!is.finite(c(stkn))))
      stop("Non-finite stock.n in the final season; cannot reconstruct annual N.",
           call. = FALSE)

    m(res)       <- unitMeans(seasonSums(m(object)))
    harvest(res) <- unitMeans(seasonSums(harvest(object)))

    if (any(!is.finite(c(m(res)))) || any(!is.finite(c(harvest(res)))))
      stop("Non-finite annual m or harvest after season collapse.", call. = FALSE)

    stock.n(res)[] <- stkn / exp(-m(res) - harvest(res))
    if (any(!is.finite(c(stock.n(res)))))
      stop("Non-finite reconstructed stock.n (check m and harvest).", call. = FALSE)

    # Maturity: stock-N weighted, then scaled to max 1 by age
    matNum <- unitSums(seasonSums(mat(object) * stock.n(object)))
    matDen <- unitSums(seasonSums(stock.n(object)))
    if (any(matDen == 0 & matNum != 0, na.rm = TRUE))
      stop("Cannot form annual maturity: zero stock.n where mat is non-zero.",
           call. = FALSE)
    mat(res)[] <- matNum / matDen
    if (any(!is.finite(c(mat(res)))))
      stop("Non-finite annual maturity after weighting.", call. = FALSE)

    mat(res) <- mat(res) %/% apply(mat(res), c(1, 3:6), max)
    # Ages with all-zero maturity remain 0 after %/%; any leftover NA is an error
    if (any(is.na(c(mat(res)))))
      stop("NA in annual maturity after scaling; check seasonal mat and stock.n.",
           call. = FALSE)

    m.spwn(res)       <- 0.5
    harvest.spwn(res) <- 0.5

    catch(res)    <- computeCatch(res)
    landings(res) <- computeLandings(res)
    discards(res) <- computeDiscards(res)
    stock(res)    <- computeStock(res)

    res
  }
)
