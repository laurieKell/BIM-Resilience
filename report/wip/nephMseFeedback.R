# =============================================================================
# STAGE 2 (WORK IN PROGRESS): MSE with feedback
# =============================================================================
# These helpers implement the closed-loop, survey-HCR management-strategy
# evaluation (MSE) for the Nephrops operating models. They are NOT sourced by
# the stage-1 reports (01_pelagics, 02_demersal, 03_nephrops, 04_iccat), which
# only produce deterministic TAC scenario projections.
#
# They are parked here so stage 1 can be finished and knitted independently.
# When stage 2 is picked up, source this file from the (future) MSE report and
# supply an HCR via `hcrFunction` (e.g. `bimResilience::hcrSurvey`).
#
# Dependencies at run time: mpb (fwd, refpts), FLCore (FLPar, FLQuant),
# plyr, stats.
# =============================================================================

#' Build Standard MSE CSV table (`*-mse.csv`)
#'
#' @param x Data frame with MSE summary columns.
#' @param sidCol Column containing stock id (default `"stock"`).
#' @param yearCol Column containing year.
#' @param implErrCol Optional implementation-error column.
#' @param regimeCol Optional regime column.
#' @param recLevelCol Optional recruitment-level column.
#' @param scenarioCol Optional scenario label column.
#' @param catchMedianCol,catchQ05Col,catchQ95Col Catch summary column names.
#' @param ssbMedianCol,ssbQ05Col,ssbQ95Col Biomass summary column names.
#' @param defaultImplErr Used when `implErrCol` is absent.
#' @param defaultRegime Used when `regimeCol` is absent.
#' @param defaultRecLevel Used when `recLevelCol` is absent.
#'
#' @return Data frame with columns
#'   `sid`, `implErr`, `regime`, `recLevel`, `Scenario`, `Year`,
#'   `catch`, `catch_q05`, `catch_q95`, `ssb`, `ssb_q05`, `ssb_q95`.
#' @export
buildMseTacCsv <- function(x,
                           sidCol = "stock",
                           yearCol = "year",
                           implErrCol = "implErr",
                           regimeCol = "regime",
                           recLevelCol = "recLevel",
                           scenarioCol = NULL,
                           catchMedianCol = "catch_median",
                           catchQ05Col = "catch_q05",
                           catchQ95Col = "catch_q95",
                           ssbMedianCol = "ssb_median",
                           ssbQ05Col = "ssb_q05",
                           ssbQ95Col = "ssb_q95",
                           defaultImplErr = NA_character_,
                           defaultRegime = NA_character_,
                           defaultRecLevel = NA_character_) {
  req <- c(sidCol, yearCol, catchMedianCol, catchQ05Col, catchQ95Col, ssbMedianCol, ssbQ05Col, ssbQ95Col)
  miss <- setdiff(req, names(x))
  if (length(miss)) stop("buildMseTacCsv missing columns: ", paste(miss, collapse = ", "))

  expand_default <- function(v, n) {
    v <- as.character(v)
    if (length(v) == n) return(v)
    if (length(v) == 1L) return(rep(v, n))
    stop("Default vector must have length 1 or nrow(x); got ", length(v), " for n=", n)
  }
  hasImpl <- implErrCol %in% names(x)
  hasReg <- regimeCol %in% names(x)
  hasRec <- recLevelCol %in% names(x)
  impl <- if (hasImpl) as.character(x[[implErrCol]]) else expand_default(defaultImplErr, nrow(x))
  reg <- if (hasReg) as.character(x[[regimeCol]]) else expand_default(defaultRegime, nrow(x))
  rec <- if (hasRec) as.character(x[[recLevelCol]]) else expand_default(defaultRecLevel, nrow(x))

  scenario <- if (!is.null(scenarioCol) && scenarioCol %in% names(x)) {
    as.character(x[[scenarioCol]])
  } else {
    paste(impl, reg, rec, sep = " | ")
  }

  out <- data.frame(
    sid = as.character(x[[sidCol]]),
    implErr = impl,
    regime = reg,
    recLevel = rec,
    Scenario = scenario,
    Year = as.integer(as.numeric(x[[yearCol]])),
    catch = as.numeric(x[[catchMedianCol]]),
    catch_q05 = as.numeric(x[[catchQ05Col]]),
    catch_q95 = as.numeric(x[[catchQ95Col]]),
    ssb = as.numeric(x[[ssbMedianCol]]),
    ssb_q05 = as.numeric(x[[ssbQ05Col]]),
    ssb_q95 = as.numeric(x[[ssbQ95Col]]),
    stringsAsFactors = FALSE
  )
  out[do.call("order", out[, c("sid", "implErr", "regime", "recLevel", "Year")]), , drop = FALSE]
}

#' Run Survey-HCR MSE Across Nephrops Operating Models
#'
#' @param bds Named list of `biodyns` objects, each containing a `PE` OM.
#' @param hcrFunction Function implementing the survey HCR interface.
#' @param startYear Numeric first management year.
#' @param endYear Numeric final management year.
#' @param minCatch Numeric minimum catch multiplier.
#' @param obsSd Numeric SD of lognormal observation error.
#' @param misReport Numeric misreporting factor applied to realized catch.
#'
#' @return Named list of projected `biodyn` objects.
#' @export
runNephMse <- function(bds,
                       hcrFunction,
                       startYear = 2025,
                       endYear = 2040,
                       minCatch = 0.10,
                       obsSd = 0.20,
                       misReport = 0.0) {
  runSingleStock = function(bd) {
    bdMse = bd
    cntrl = FLPar(
      fmsy = refpts(bdMse)["fmsy", drop = TRUE],
      btrig = refpts(bdMse)["bmsy", drop = TRUE],
      bbuf = refpts(bdMse)["bmsy", drop = TRUE] * 0.5
    )
    indexObs = stock(bdMse)

    for (iYear in startYear:endYear) {
      lagYear = iYear - 1
      indexObs[, ac(lagYear)] = stock(bdMse)[, ac(lagYear)] * exp(stats::rnorm(1, 0, obsSd))

      tac = hcrFunction(
        iYr = iYear,
        index = indexObs,
        catch = catch(bdMse),
        cntrl = cntrl,
        minCatch = minCatch,
        lag = 1
      )

      # Apply misreporting factor to realized catch (e.g., 0.1 => 10% over TAC)
      realizedCatch = tac * (1 + misReport)
      catch(bdMse)[, ac(iYear)] = realizedCatch
      bdMse = mpb::fwd(bdMse, catch = catch(bdMse)[, -1])
    }

    bdMse
  }

  nephMse = plyr::llply(names(bds), function(id) {
    if (is.null(bds[[id]][["PE"]])) {
      stop(paste("Missing PE operating model for stock:", id))
    }
    runSingleStock(bds[[id]][["PE"]])
  })
  names(nephMse) = names(bds)
  nephMse
}


#' @noRd
.flq_year_mq <- function(q, years) {
  med = q05 = q95 = rep(NA_real_, length(years))
  for (i in seq_along(years)) {
    yr = years[i]
    v = c(q[, ac(yr)])
    v = v[is.finite(v)]
    if (!length(v)) {
      next
    }
    med[i] = stats::median(v, na.rm = TRUE)
    q05[i] = stats::quantile(v, 0.05, na.rm = TRUE, names = FALSE)
    q95[i] = stats::quantile(v, 0.95, na.rm = TRUE, names = FALSE)
  }
  data.frame(year = years, med = med, q05 = q05, q95 = q95, stringsAsFactors = FALSE)
}

#' Build Long-Format Time Series from Nephrops MSE Output
#'
#' @description
#' Long-format time series from a named list of projected \code{biodyn} objects.
#'
#' @param nephMse Named list of projected `biodyn` objects.
#'
#' @return Data frame with `sid`, `year`, `ssb`, `ssb_q05`, `ssb_q95`, `catch`,
#'   `catch_q05`, `catch_q95`, `bmsy`, `stockRel` (`ssb` / `bmsy`), `riskBmsy`.
#' @export
buildNephMseTs <- function(nephMse) {
  nephMseTs = plyr::ldply(names(nephMse), function(id) {
    bd = nephMse[[id]]

    stockQ = stock(bd)
    catchQ = catch(bd)
    ys = sort(intersect(
      as.numeric(dimnames(stockQ)$year),
      as.numeric(dimnames(catchQ)$year)
    ))
    if (length(ys) == 0) {
      stop(paste("No overlapping year dimension in stock/catch for:", id))
    }

    ss = .flq_year_mq(stockQ, ys)
    cc = .flq_year_mq(catchQ, ys)
    bmsy = as.numeric(refpts(bd)["bmsy", drop = TRUE])

    data.frame(
      sid = id,
      year = ys,
      ssb = ss$med,
      ssb_q05 = ss$q05,
      ssb_q95 = ss$q95,
      catch = cc$med,
      catch_q05 = cc$q05,
      catch_q95 = cc$q95,
      bmsy = bmsy,
      stringsAsFactors = FALSE
    )
  })

  nephMseTs$stockRel = nephMseTs$ssb / nephMseTs$bmsy
  nephMseTs$riskBmsy = nephMseTs$stockRel < 1
  nephMseTs
}

#' Build Nephrops MSE CSV Table (pel/dem `*-mse.csv` column contract)
#'
#' @param ts Data frame with `sid`, `year`, `catch`, `catch_q05`, `catch_q95`,
#'   `ssb`, `ssb_q05`, `ssb_q95`, and the scenario column named by `scenarioCol`.
#' @param scenarioCol Name of the scenario label column (default `"Scenario"`).
#'
#' @return Data frame ready for `write.csv` as **`neph-mse.csv`**.
#' @export
buildNephMseCsvTable <- function(ts, scenarioCol = "Scenario") {
  buildMseTacCsv(
    x = ts,
    sidCol = "sid",
    yearCol = "year",
    implErrCol = "__none__",
    regimeCol = "__none__",
    recLevelCol = "__none__",
    scenarioCol = scenarioCol,
    catchMedianCol = "catch",
    catchQ05Col = "catch_q05",
    catchQ95Col = "catch_q95",
    ssbMedianCol = "ssb",
    ssbQ05Col = "ssb_q05",
    ssbQ95Col = "ssb_q95",
    defaultImplErr = ts[[scenarioCol]],
    defaultRegime = "SurveyHCR",
    defaultRecLevel = "1"
  )
}


#' Summarise Risk and Catch Variability from Nephrops MSE Series
#'
#' @param mseTimeSeries Data frame from `buildNephMseTs()`.
#' @param years Numeric vector of years to include.
#'
#' @return Data frame with risk and variability metrics by stock id.
#' @export
summariseNephMse <- function(mseTimeSeries, years = 2025:2040) {
  plotDat = subset(mseTimeSeries, year %in% years)
  plyr::ddply(plotDat, .(sid), summarise,
    pStockBelowBmsy = mean(riskBmsy, na.rm = TRUE),
    meanCatch = mean(catch, na.rm = TRUE),
    cvCatch = sd(catch, na.rm = TRUE) / mean(catch, na.rm = TRUE)
  )
}
