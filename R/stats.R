#' Download summary statistics from INIA
#'
#' Returns the statistical report the GRAS query form produces for a single
#' variable: count, mean, standard deviation, minimum, five percentiles, maximum
#' and sum, computed by INIA over the requested period and broken down three
#' ways at once -- by year, by month and by ten-day period (decade).
#'
#' Unlike [inia_daily()], this endpoint accepts exactly one variable.
#'
#' @param est Station: id, code, slug, name or fragment. See [inia_station_id()].
#' @param variable A single variable: id, key, name or fragment. See
#'   [inia_var_id()].
#' @param from,to Start and end date, as `Date` or `"YYYY-MM-DD"`. Default to the
#'   station's period of record.
#' @param percentiles Five percentiles, in ascending order, between 0 and 100.
#'   Defaults to the form's own `c(5, 25, 50, 75, 95)`.
#' @param min,max Cut-off values: observations outside `[min, max]` are excluded
#'   before the statistics are computed. The defaults admit everything.
#' @param quiet Suppress progress messages.
#'
#' @return A data frame with columns `period_type` (`"year"`, `"month"` or
#'   `"decade"`), `period`, `n`, `mean`, `sd`, `min`, the five percentile
#'   columns, `max` and `sum`. Carries the same `attribution` attribute as
#'   [inia_daily()].
#'
#' @seealso [inia_daily()], [inia_terms()]
#' @export
#' @examples
#' \dontrun{
#' # Rainfall statistics at La Estanzuela, 2000-2020
#' s <- inia_stats("LE", "precip", "2000-01-01", "2020-12-31")
#' subset(s, period_type == "month")
#'
#' # Annual totals only
#' s[s$period_type == "year", c("period", "mean", "sum")]
#'
#' # Custom percentiles, excluding trace rainfall
#' inia_stats("LE", "precip", "2000-01-01", "2020-12-31",
#'            percentiles = c(10, 25, 50, 75, 90), min = 0.1)
#' }
inia_stats <- function(est,
                       variable,
                       from = NULL,
                       to = NULL,
                       percentiles = c(5, 25, 50, 75, 95),
                       min = -9999,
                       max = 9999,
                       quiet = FALSE) {
  if (missing(est)) .abort_station("<missing>", .station_table(), "must be supplied")
  if (missing(variable)) {
    stop("`variable` must be supplied \u2014 inia_stats() reports on one variable ",
         "at a time.\n  See inia_variables().", call. = FALSE)
  }

  id <- inia_station_id(est)
  if (length(id) != 1) {
    stop("`est` must be a single station; got ", length(id), ".", call. = FALSE)
  }
  var_id <- inia_var_id(variable)
  if (length(var_id) != 1) {
    stop("`variable` must resolve to exactly one variable; ",
         encodeString(as.character(variable), quote = '"'), " gave ",
         length(var_id), ".\n  Use inia_daily() for several variables at once.",
         call. = FALSE)
  }

  if (length(percentiles) != 5 || anyNA(percentiles) ||
      any(percentiles < 0 | percentiles > 100) ||
      is.unsorted(percentiles, strictly = TRUE)) {
    stop("`percentiles` must be 5 strictly increasing values between 0 and 100.",
         call. = FALSE)
  }
  if (min > max) {
    stop("`min` (", min, ") is greater than `max` (", max, ").", call. = FALSE)
  }

  .inia_notice_once()

  st <- .station_table()
  st <- st[st$id == id, , drop = FALSE]
  rng <- .resolve_dates(from, to, st, quiet = quiet)

  query <- list(
    est = id, f_ini = format(rng$from), f_fin = format(rng$to),
    vars = var_id, salida = "CSV", min = min, max = max,
    P1 = percentiles[1], P2 = percentiles[2], P3 = percentiles[3],
    P4 = percentiles[4], P5 = percentiles[5]
  )
  if (!quiet) {
    message(sprintf("Downloading statistics for %s at %s: %s to %s...",
                    .variable_table()$key[.variable_table()$id == var_id],
                    st$name, format(rng$from), format(rng$to)))
  }

  body <- .inia_get("/ver_estadisticas_consulta_web/", query)
  out <- .parse_stats(body, percentiles)

  attr(out, "attribution") <- inia_attribution()
  attr(out, "station_info") <- st
  attr(out, "variables") <- .variable_table()[.variable_table()$id == var_id, ]
  attr(out, "query") <- paste0(inia_base_url(),
                               "/ver_estadisticas_consulta_web/?",
                               paste(names(query), unlist(query), sep = "=",
                                     collapse = "&"))
  class(out) <- c("inia_data", "data.frame")
  out
}

# The report is three stacked blocks, each with its own header row, tagged in
# column 1 by A (ano/year), M (mes/month) and D (decada/ten-day period).
.parse_stats <- function(body, percentiles) {
  lines <- strsplit(body, "\r?\n")[[1]]
  rows <- lines[grepl("^[AMD],", lines)]
  rows <- rows[!grepl("^[AMD],(A.o|Mes|D.cada),", rows)]
  if (!length(rows)) {
    stop("Unexpected response from the INIA GRAS server: no statistics rows ",
         "were found. The report format may have changed.", call. = FALSE)
  }

  df <- utils::read.csv(text = paste(rows, collapse = "\n"), header = FALSE,
                        colClasses = "character", check.names = FALSE,
                        na.strings = c("", "NA"), encoding = "UTF-8")
  names(df) <- c("period_type", "period", "n", "mean", "sd", "min",
                 paste0("p", percentiles), "max", "sum")[seq_len(ncol(df))]
  df$period_type <- c(A = "year", M = "month", D = "decade")[df$period_type]
  for (j in setdiff(names(df), c("period_type", "period"))) {
    df[[j]] <- as.numeric(df[[j]])
  }
  df$period <- trimws(df$period)
  rownames(df) <- NULL
  df
}
