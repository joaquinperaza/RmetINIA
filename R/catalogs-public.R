#' INIA weather stations
#'
#' The six INIA agroclimatic stations served by the Banco de Datos
#' Agroclimaticos, with the numeric id used by the `est=` query parameter, the
#' station code that appears in the downloaded files, and the period of record.
#'
#' Anywhere this package asks for a station you may pass **any** of: the numeric
#' id (`2`), the code (`"LE"`), the slug (`"la_estanzuela"`), the full name, or
#' any unambiguous fragment of the name (`"estanzuela"`). See
#' [inia_station_id()].
#'
#' ```
#'  id  code   name                                     slug               first_date
#'   1  LB     INIA Las Brujas                          las_brujas         1972-07-01
#'   2  LE     INIA La Estanzuela                       la_estanzuela      1965-07-01
#'   3  TA-LM  INIA Tacuarembo - La Magnolia            la_magnolia        1978-02-01
#'   4  TT-PL  INIA Treinta y Tres - Paso de la Laguna  paso_de_la_laguna  1971-01-01
#'   5  SG     INIA Salto Grande                        salto_grande       1970-07-01
#'   6  TA-GL  INIA Tacuarembo - Glencoe                glencoe            2016-11-01
#' ```
#'
#' @param refresh If `TRUE`, re-read the live station list from the GRAS query
#'   form instead of using the copy embedded in the package. This is the only
#'   way to get an up-to-date `last_date`, which advances every day.
#' @return A data frame with columns `id`, `code`, `name`, `slug`, `first_date`
#'   and (when `refresh = TRUE`) `last_date`.
#' @seealso [inia_variables()] for the variable catalogue, [inia_station_id()]
#'   to resolve a name to an id.
#' @family catalogue
#' @export
#' @examples
#' inia_stations()
#'
#' # Stations with data going back before 1975
#' s <- inia_stations()
#' s[as.Date(s$first_date) < as.Date("1975-01-01"), c("id", "name", "first_date")]
#'
#' \dontrun{
#' # Live list, including the last day currently available at each station
#' inia_stations(refresh = TRUE)
#' }
inia_stations <- function(refresh = FALSE) {
  out <- if (refresh) .fetch_stations() else .station_table()
  out <- out[order(out$id), , drop = FALSE]
  rownames(out) <- NULL
  class(out) <- c("inia_catalog", "data.frame")
  out
}

#' INIA agroclimatic variables
#'
#' The 53 daily variables offered by the Banco de Datos Agroclimaticos, with the
#' numeric id used by the `vars=` query parameter, a stable ASCII `key`, a short
#' English `name`, the unit, and the exact Spanish column `label` the server
#' returns.
#'
#' Anywhere this package asks for a variable you may pass the id (`51`), the key
#' (`"precip"`), the English or Spanish name, or an unambiguous fragment of
#' either (`"precipitation"`). See [inia_var_id()].
#'
#' Not every variable is measured at every station, and none of them are
#' measured over the full record everywhere. Variables with no data in the
#' requested window are dropped by the server; [inia_daily()] warns and reports
#' them in the `"empty_variables"` attribute rather than letting them vanish
#' silently.
#'
#' @param search Optional case- and accent-insensitive string. Keeps only rows
#'   whose key, name, label or description matches. This is the fastest way to
#'   find a variable you only half remember: `inia_variables("humidity")`.
#' @param category Optional category filter, one or more of `"Air"`,
#'   `"Rain and evaporation"`, `"Solar radiation"`, `"Cold and heat indices"`,
#'   `"Soil"`. Partial, case-insensitive matches are accepted (`"soil"`).
#' @param refresh If `TRUE`, re-scrape the live variable list from the GRAS query
#'   form. Returns the full official Spanish definitions in `description`
#'   instead of the condensed English ones. Requires the \pkg{rvest} package.
#' @return A data frame with columns `id`, `key`, `name`, `unit`, `category`,
#'   `label`, `category_es` and `description`.
#' @seealso [inia_stations()], [inia_var_id()]
#' @family catalogue
#' @export
#' @examples
#' inia_variables()
#'
#' # Find a variable you only half remember
#' inia_variables("humidity")
#' inia_variables("helada")      # Spanish works too
#'
#' # Everything measured in the soil
#' inia_variables(category = "soil")
#'
#' # The ids to pass to the raw web API
#' inia_variables(category = "Solar radiation")$id
inia_variables <- function(search = NULL, category = NULL, refresh = FALSE) {
  out <- if (refresh) .fetch_variables() else .variable_table()

  if (!is.null(category)) {
    cats <- unique(out$category)
    keep <- unlist(lapply(category, function(cc) {
      hit <- cats[.norm(cats) == .norm(cc)]
      if (!length(hit)) hit <- cats[grepl(.norm(cc), .norm(cats), fixed = TRUE)]
      if (!length(hit)) {
        stop("Unknown category ", encodeString(cc, quote = '"'), ".\n",
             "  Available: ", paste(encodeString(cats, quote = '"'), collapse = ", "),
             call. = FALSE)
      }
      hit
    }))
    out <- out[out$category %in% keep, , drop = FALSE]
  }

  if (!is.null(search)) {
    pat <- .norm(search)
    hay <- paste(.norm(out$key), .norm(out$name), .norm(out$label),
                 .norm(out$description))
    out <- out[grepl(pat, hay, fixed = TRUE), , drop = FALSE]
    if (!nrow(out)) {
      message("No variable matches ", encodeString(search, quote = '"'),
              ". Try inia_variables() to see all 53.")
    }
  }

  rownames(out) <- NULL
  class(out) <- c("inia_catalog", "data.frame")
  out
}

#' @export
print.inia_catalog <- function(x, ...) {
  y <- as.data.frame(x)
  if (!is.null(y$description)) {
    y$description <- ifelse(nchar(y$description) > 46,
                            paste0(substr(y$description, 1, 45), "\u2026"),
                            y$description)
  }
  print.data.frame(y, right = FALSE, ...)
  invisible(x)
}

# Live refreshers -------------------------------------------------------------

.form_html <- function() {
  .inia_get("/consulta_bdagroclima/", query = list(), allow_html = TRUE)
}

.fetch_stations <- function() {
  html <- .form_html()
  # <script id="listado_estaciones" type="application/json">
  #   [[2, "INIA La Estanzuela", "1965-07-01", "2026-08-10"], ...]
  m <- regmatches(
    html,
    regexpr('id="listado_estaciones"[^>]*>\\s*\\[\\[.*?\\]\\]', html)
  )
  if (!length(m)) {
    stop("Could not find the station list on the GRAS query form. ",
         "The page layout may have changed; use inia_stations() without ",
         "refresh = TRUE, or report this.", call. = FALSE)
  }
  json <- sub('^id="listado_estaciones"[^>]*>\\s*', "", m)

  rows <- regmatches(json, gregexpr('\\[\\s*[0-9]+\\s*,[^]]*\\]', json))[[1]]
  parsed <- lapply(rows, function(r) {
    id <- as.integer(sub('^\\[\\s*([0-9]+).*$', "\\1", r))
    strs <- regmatches(r, gregexpr('"(\\\\.|[^"\\\\])*"', r))[[1]]
    strs <- .unescape_json(substr(strs, 2, nchar(strs) - 1))
    data.frame(id = id, name = strs[1], first_date = strs[2],
               last_date = strs[3], stringsAsFactors = FALSE)
  })
  live <- do.call(rbind, parsed)

  # Keep the code and slug from the embedded table, which the live JSON lacks.
  emb <- .station_table()[, c("id", "code", "slug")]
  out <- merge(live, emb, by = "id", all.x = TRUE)
  out[, c("id", "code", "name", "slug", "first_date", "last_date")]
}

.fetch_variables <- function() {
  if (!requireNamespace("rvest", quietly = TRUE)) {
    stop("inia_variables(refresh = TRUE) needs the 'rvest' package.\n",
         '  install.packages("rvest")', call. = FALSE)
  }
  html <- xml2::read_html(charToRaw(.form_html()), encoding = "UTF-8")
  accs <- rvest::html_elements(html, "div.accordion")
  live <- do.call(rbind, lapply(accs, function(a) {
    cat_es <- rvest::html_text2(rvest::html_element(a, "label.accordion-label"))
    items <- rvest::html_elements(a, "div.grid-variable-item")
    if (!length(items)) return(NULL)
    do.call(rbind, lapply(items, function(it) {
      data.frame(
        id = as.integer(rvest::html_attr(
          rvest::html_element(it, "input[name=Variable]"), "value")),
        label = trimws(rvest::html_text2(
          rvest::html_element(it, "label.variable"))),
        category_es = cat_es,
        description = trimws(gsub("\\s+", " ", rvest::html_attr(
          rvest::html_element(it, "div.tooltip-content p"), "title"))),
        stringsAsFactors = FALSE
      )
    }))
  }))
  if (is.null(live) || !nrow(live)) {
    stop("Could not parse the variable list from the GRAS query form. ",
         "The page layout may have changed; use inia_variables() without ",
         "refresh = TRUE, or report this.", call. = FALSE)
  }

  emb <- .variable_table()[, c("id", "key", "name", "unit", "category")]
  out <- merge(emb, live, by = "id", all = TRUE)
  # A variable added to the site since this package was built has no key yet.
  new <- is.na(out$key)
  if (any(new)) {
    out$key[new] <- .slugify(out$label[new])
    out$name[new] <- out$label[new]
    out$unit[new] <- NA_character_
    out$category[new] <- out$category_es[new]
    warning(sum(new), " variable(s) on the GRAS site are not in the catalogue ",
            "embedded in this package: ",
            paste(out$label[new], collapse = ", "),
            ". Their keys were generated automatically.", call. = FALSE)
  }
  out[order(out$category, out$key), c("id", "key", "name", "unit", "category",
                                      "label", "category_es", "description")]
}

.unescape_json <- function(x) {
  vapply(x, function(s) {
    s <- gsub('\\\\"', '"', s)
    m <- gregexpr("\\\\u[0-9a-fA-F]{4}", s)[[1]]
    if (m[1] != -1) {
      codes <- regmatches(s, gregexpr("\\\\u[0-9a-fA-F]{4}", s))[[1]]
      for (cd in unique(codes)) {
        s <- gsub(cd, intToUtf8(strtoi(substr(cd, 3, 6), 16L)), s, fixed = TRUE)
      }
    }
    gsub("\\\\\\\\", "\\\\", s)
  }, character(1), USE.NAMES = FALSE)
}
