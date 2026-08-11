#' Download daily agroclimatic data from INIA
#'
#' Queries the Banco de Datos Agroclimaticos of INIA Uruguay and returns daily
#' observations as a data frame. This wraps the public CSV export of the GRAS
#' query form.
#'
#' @section Naming stations and variables:
#' You never need to look up a number on the web form. `est` accepts an id, a
#' station code, a slug, a full name, or any unambiguous fragment; `vars`
#' accepts ids, keys, English or Spanish names, fragments, or a whole category
#' at once. Anything that fails to resolve produces an error listing the valid
#' options ([inia_station_id()], [inia_var_id()]).
#'
#' The default shown in the signature for `est` is the full station list, so
#' pressing Tab inside `inia_daily(est = )` in RStudio offers all six stations
#' with their ids. `inia_station$` and `inia_var$` do the same for the other
#' half of the problem — see [inia_station].
#'
#' ```
#'  1 = INIA Las Brujas (LB)                          from 1972-07-01
#'  2 = INIA La Estanzuela (LE)                       from 1965-07-01
#'  3 = INIA Tacuarembo - La Magnolia (TA-LM)         from 1978-02-01
#'  4 = INIA Treinta y Tres - Paso de la Laguna (TT-PL) from 1971-01-01
#'  5 = INIA Salto Grande (SG)                        from 1970-07-01
#'  6 = INIA Tacuarembo - Glencoe (TA-GL)             from 2016-11-01
#' ```
#'
#' @section Missing data:
#' Two different kinds of absence come back from this service and they are not
#' interchangeable. A variable that has *no* data at all in the window you asked
#' for is dropped from the response entirely; `inia_daily()` warns, and lists it
#' in `attr(x, "empty_variables")`. A variable that has data but not on every day
#' comes back with blanks, which become `NA`.
#'
#' @section Terms of use:
#' The data is free for any user, but citing the GRAS website as the source is
#' mandatory when you publish it, and INIA accepts no liability for errors in it
#' or for decisions taken on the basis of it. The required credit line travels
#' with the result in `attr(x, "attribution")`. See [inia_terms()] for the
#' conditions in full.
#'
#' @param est Station: id, code, slug, name or name fragment. Vectors are
#'   allowed; results for several stations are stacked. The default is the
#'   station list itself, purely so that editors offer it as a completion — you
#'   must supply a value.
#' @param from,to Start and end date, as `Date` or as `"YYYY-MM-DD"`. `from`
#'   defaults to the first day on record for the station, `to` to today. Dates
#'   outside the period of record are clamped to it, with a message.
#' @param vars Variables to download. Ids, keys, names, fragments, or any of the
#'   category shortcuts `"common"` (the default), `"all"`, `"air"`, `"rain"`,
#'   `"radiation"`, `"indices"`, `"soil"`.
#' @param long If `TRUE`, return one row per station/date/variable
#'   (`station_id`, `station`, `date`, `variable`, `value`, `unit`) instead of
#'   one column per variable.
#' @param tidy_names If `TRUE` (default), name the columns with the package's
#'   ASCII keys (`tmax`, `precip`). If `FALSE`, keep the server's Spanish
#'   headers verbatim (`"Temp. Aire Maxima (ºC)"`).
#' @param quiet Suppress progress and clamping messages.
#'
#' @return A data frame with columns `station_id`, `station` (the station code),
#'   `date`, and one column per variable — or the long form if `long = TRUE`.
#'   Carries the attributes `attribution` (the required credit line),
#'   `station_info`, `variables` (the catalogue rows actually returned),
#'   `definitions` (INIA's own definitions of each variable), `empty_variables`
#'   and `query` (the URLs used).
#'
#' @seealso [inia_stations()], [inia_variables()], [inia_stats()],
#'   [inia_write_csv()], [inia_terms()]
#' @export
#' @examples
#' \dontrun{
#' # Rainfall at La Estanzuela for one month
#' inia_daily("la_estanzuela", "2024-01-01", "2024-01-31", vars = "precip")
#'
#' # The same, naming the station however you like
#' inia_daily(2, "2024-01-01", "2024-01-31", vars = 51)
#' inia_daily("LE", "2024-01-01", "2024-01-31", vars = "precip")
#'
#' # Several variables, using the ids from the web form's URL
#' inia_daily(2, "2024-01-01", "2024-01-31", vars = c(60, 86, 71, 65, 51))
#'
#' # A whole category
#' inia_daily("Las Brujas", "2023-01-01", "2023-12-31", vars = "soil")
#'
#' # Two stations at once, in long form, ready for ggplot2
#' inia_daily(c("LE", "LB"), "2023-01-01", "2023-03-31",
#'            vars = c("tmax", "tmin"), long = TRUE)
#'
#' # The full period of record (dates default to the station's own limits)
#' le <- inia_daily("LE", vars = "precip")
#' range(le$date)
#'
#' # What INIA says each column means
#' x <- inia_daily("LE", "2024-01-01", "2024-01-05", vars = c("precip", "tmax"))
#' attr(x, "definitions")
#' attr(x, "attribution")
#' }
inia_daily <- function(est = c("1 = INIA Las Brujas (LB)",
                               "2 = INIA La Estanzuela (LE)",
                               "3 = INIA Tacuarembo - La Magnolia (TA-LM)",
                               "4 = INIA Treinta y Tres - Paso de la Laguna (TT-PL)",
                               "5 = INIA Salto Grande (SG)",
                               "6 = INIA Tacuarembo - Glencoe (TA-GL)"),
                       from = NULL,
                       to = NULL,
                       vars = c("common", "all", "air", "rain", "radiation",
                                "indices", "soil"),
                       long = FALSE,
                       tidy_names = TRUE,
                       quiet = FALSE) {
  if (missing(est)) {
    .abort_station("<missing>", .station_table(), "must be supplied")
  }
  if (missing(vars)) vars <- "common"

  ids <- inia_station_id(est)
  var_ids <- inia_var_id(vars)
  if (!length(var_ids)) {
    stop("No variables selected. See inia_variables().", call. = FALSE)
  }

  .inia_notice_once()

  parts <- lapply(ids, function(id) {
    .inia_daily_one(id, from = from, to = to, var_ids = var_ids,
                    tidy_names = tidy_names, quiet = quiet,
                    n_stations = length(ids))
  })

  out <- .rbind_fill(lapply(parts, function(p) p$data))
  attr(out, "attribution") <- inia_attribution()
  attr(out, "station_info") <- .rbind_fill(lapply(parts, function(p) p$station))
  attr(out, "variables") <- .variable_table()[.variable_table()$id %in% var_ids, ]
  attr(out, "definitions") <- unique(.rbind_fill(
    lapply(parts, function(p) p$definitions)))
  attr(out, "empty_variables") <- unique(unlist(
    lapply(parts, function(p) p$empty_variables)))
  attr(out, "query") <- vapply(parts, function(p) p$query, character(1))
  rownames(out) <- NULL

  empties <- attr(out, "empty_variables")
  if (length(empties) && !quiet) {
    warning("No data in this period for: ", paste(empties, collapse = "; "),
            ".\n  These variables were dropped by the server and are absent ",
            "from the result.\n  See attr(x, \"empty_variables\").",
            call. = FALSE)
  }

  if (long) out <- .to_long(out)
  class(out) <- c("inia_data", "data.frame")
  out
}

#' @rdname inia_daily
#' @export
inia_data <- inia_daily

.inia_daily_one <- function(id, from, to, var_ids, tidy_names, quiet,
                            n_stations) {
  st <- .station_table()
  st <- st[st$id == id, , drop = FALSE]

  rng <- .resolve_dates(from, to, st, quiet = quiet)

  query <- list(
    est   = id,
    f_ini = format(rng$from),
    f_fin = format(rng$to),
    vars  = paste(sort(var_ids), collapse = "-")
  )
  if (!quiet) {
    message(sprintf("Downloading %s: %s to %s, %d variable%s...",
                    st$name, format(rng$from), format(rng$to),
                    length(var_ids), if (length(var_ids) == 1) "" else "s"))
  }

  body <- .inia_get("/ver_exporta_datos_consulta/", query)
  parsed <- .parse_export(body)

  df <- parsed$data
  vt <- .variable_table()
  if (tidy_names && ncol(df) > 1) {
    idx <- match(.norm(names(df)[-1]), .norm(vt$label))
    newnames <- ifelse(is.na(idx), .slugify(names(df)[-1]), vt$key[idx])
    names(df)[-1] <- newnames
    # Restore the order the caller asked for, for the variables that came back.
    wanted <- vt$key[match(var_ids, vt$id)]
    ord <- wanted[wanted %in% names(df)]
    df <- df[, c("date", ord), drop = FALSE]
  }

  df <- cbind(
    station_id = id,
    station = if (!is.na(parsed$station$code)) parsed$station$code else st$code,
    df,
    stringsAsFactors = FALSE
  )

  list(
    data = df,
    station = data.frame(id = id, code = st$code,
                         name = parsed$station$name %||% st$name,
                         from = rng$from, to = rng$to,
                         stringsAsFactors = FALSE),
    definitions = parsed$definitions,
    empty_variables = parsed$empty_variables,
    query = .query_url(query)
  )
}

.query_url <- function(query) {
  paste0(inia_base_url(), "/ver_exporta_datos_consulta/?",
         paste(names(query), unlist(query), sep = "=", collapse = "&"))
}

# Clamp the requested window to the station's period of record. Asking for dates
# outside it makes the server answer HTTP 500, so this is a correctness measure
# as much as a convenience.
.resolve_dates <- function(from, to, st, quiet = FALSE) {
  first <- as.Date(st$first_date)
  today <- Sys.Date()

  from <- if (is.null(from)) first else .as_date(from, "from")
  to <- if (is.null(to)) today else .as_date(to, "to")

  if (from > to) {
    stop("`from` (", format(from), ") is later than `to` (", format(to), ").",
         call. = FALSE)
  }
  if (to < first) {
    stop(st$name, " has no data before ", format(first), ", but `to` is ",
         format(to), ".\n  See inia_stations() for each station's period of ",
         "record.", call. = FALSE)
  }
  if (from > today) {
    stop("`from` (", format(from), ") is in the future.", call. = FALSE)
  }

  if (from < first) {
    if (!quiet) {
      message("  ", st$name, " starts on ", format(first),
              "; `from` moved up from ", format(from), ".")
    }
    from <- first
  }
  if (to > today) {
    if (!quiet) message("  `to` clamped to today (", format(today), ").")
    to <- today
  }
  list(from = from, to = to)
}

.as_date <- function(x, arg) {
  if (inherits(x, "Date")) return(x)
  if (inherits(x, "POSIXt")) return(as.Date(x))
  out <- suppressWarnings(as.Date(as.character(x)))
  if (is.na(out)) {
    stop("`", arg, "` = ", encodeString(as.character(x), quote = '"'),
         " is not a date. Use a Date object or \"YYYY-MM-DD\".", call. = FALSE)
  }
  out
}

.to_long <- function(x) {
  idc <- intersect(c("station_id", "station", "date"), names(x))
  vc <- setdiff(names(x), idc)
  if (!length(vc)) return(x)
  out <- do.call(rbind, lapply(vc, function(v) {
    data.frame(x[idc], variable = v, value = x[[v]], stringsAsFactors = FALSE)
  }))
  vt <- .variable_table()
  out$unit <- vt$unit[match(out$variable, vt$key)]
  out <- out[order(out$station_id, out$date, out$variable), , drop = FALSE]
  rownames(out) <- NULL
  out
}

.rbind_fill <- function(dfs) {
  dfs <- Filter(function(d) !is.null(d) && nrow(d) > 0, dfs)
  if (!length(dfs)) return(data.frame())
  cols <- unique(unlist(lapply(dfs, names)))
  do.call(rbind, lapply(dfs, function(d) {
    miss <- setdiff(cols, names(d))
    for (m in miss) d[[m]] <- NA
    d[, cols, drop = FALSE]
  }))
}

`%||%` <- function(a, b) if (is.null(a) || (length(a) == 1 && is.na(a))) b else a

#' @export
print.inia_data <- function(x, ...) {
  y <- x
  attributes(y) <- attributes(y)[c("names", "row.names", "class")]
  class(y) <- "data.frame"
  n <- nrow(y)
  if (n > 12) {
    print(utils::head(y, 6))
    cat("... ", format(n - 12, big.mark = ","), " more rows ...\n", sep = "")
    print(utils::tail(y, 6))
  } else {
    print(y)
  }
  cat("\n", attr(x, "attribution"), "\n", sep = "")
  invisible(x)
}
