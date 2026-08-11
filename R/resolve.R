# Resolving user input to the ids the web API wants --------------------------
#
# The design goal: a user should never have to open the web form to look up a
# number. Ids, codes, slugs, English names, Spanish labels and unambiguous
# fragments of any of those all resolve; anything that does not resolve produces
# an error that *lists the valid options* rather than just rejecting the input.

# Case-, accent-, punctuation- and normalisation-insensitive comparison key.
# The GRAS pages mix NFC and NFD accents, so combining marks are stripped as
# well as precomposed ones.
.ACCENTED <- paste0(
  "\u00e1\u00e0\u00e4\u00e2\u00e3\u00e9\u00e8\u00eb\u00ea",
  "\u00ed\u00ec\u00ef\u00ee\u00f3\u00f2\u00f6\u00f4\u00f5",
  "\u00fa\u00f9\u00fc\u00fb\u00f1\u00e7"
)
.PLAIN <- "aaaaaeeeeiiiiooooouuuunc"

.deaccent <- function(x) {
  x <- as.character(x)
  x <- gsub("[\u0300-\u036f]", "", x)   # NFD: drop combining marks
  x <- tolower(x)
  chartr(.ACCENTED, .PLAIN, x)          # NFC: fold precomposed forms
}

.norm <- function(x) {
  gsub("[^a-z0-9]", "", .deaccent(x))
}

# sprintf's field widths count bytes, so accented station names ("Tacuarembo")
# break column alignment in every message this package prints. Pad on display
# width instead.
.pad <- function(x, width) {
  x <- as.character(x)
  paste0(x, strrep(" ", pmax(0, width - nchar(x, type = "width"))))
}

.slugify <- function(x) {
  x <- gsub("[^a-z0-9]+", "_", .deaccent(x))
  gsub("^_+|_+$", "", x)
}

#' Resolve a station to its numeric id
#'
#' Turns whatever you have -- an id, a station code, a slug, a full name or a
#' fragment of one -- into the integer `est` id the GRAS web API expects. Used
#' internally by [inia_daily()] and [inia_stats()]; exported because it is handy
#' on its own, and because its error message is the quickest way to see the
#' station list.
#'
#' @param x Station id(s), code(s), slug(s), name(s) or unambiguous name
#'   fragment(s). Numeric or character; vectors are allowed.
#' @return An integer vector of station ids.
#' @seealso [inia_stations()]
#' @family catalogue
#' @export
#' @examples
#' inia_station_id(2)
#' inia_station_id("LE")
#' inia_station_id("estanzuela")
#' inia_station_id("la_estanzuela")
#' inia_station_id(c("LE", "Las Brujas", 5))
#'
#' # An unusable value tells you what the usable ones are
#' try(inia_station_id("montevideo"))
inia_station_id <- function(x) {
  st <- .station_table()
  vapply(x, function(one) .resolve_station_one(one, st), integer(1),
         USE.NAMES = FALSE)
}

.resolve_station_one <- function(one, st) {
  if (is.null(one) || length(one) != 1 || is.na(one)) {
    .abort_station(one, st, "is missing")
  }

  # Numbers, and strings the completion default produces ("2 = INIA La Estanzuela")
  num <- suppressWarnings(as.integer(sub("^\\s*([0-9]+)\\s*(=.*)?$", "\\1",
                                         as.character(one))))
  if (!is.na(num)) {
    if (num %in% st$id) return(num)
    .abort_station(one, st, sprintf("is not a station id (valid ids: %s)",
                                    paste(sort(st$id), collapse = ", ")))
  }

  key <- .norm(one)
  if (!nzchar(key)) .abort_station(one, st, "is empty")

  hit <- which(.norm(st$code) == key | .norm(st$slug) == key |
                 .norm(st$name) == key)
  if (length(hit) == 1) return(st$id[hit])

  hit <- which(grepl(key, .norm(st$name), fixed = TRUE) |
                 grepl(key, .norm(st$slug), fixed = TRUE))
  if (length(hit) == 1) return(st$id[hit])
  if (length(hit) > 1) {
    .abort_station(one, st, sprintf(
      "is ambiguous: it matches %s",
      paste(sprintf("%d (%s)", st$id[hit], st$name[hit]), collapse = ", ")))
  }
  .abort_station(one, st, "does not match any station")
}

.abort_station <- function(one, st, why) {
  stop(
    "Station ", encodeString(as.character(one), quote = '"'), " ", why, ".\n\n",
    "Pass an id, a code, a slug, or any part of the name:\n",
    paste0(sprintf("  %-3d %s %s %s", st$id, .pad(st$code, 6),
                   .pad(st$name, 40), st$slug),
           collapse = "\n"),
    "\n\n  inia_stations()  for the same table as a data frame",
    call. = FALSE
  )
}

#' Resolve a variable to its numeric id
#'
#' Turns variable keys, English or Spanish names, fragments, or ids into the
#' numeric ids the GRAS `vars=` parameter expects. Also accepts the category
#' shortcuts understood by [inia_daily()]: `"all"`, `"common"`, `"air"`,
#' `"rain"`, `"radiation"`, `"indices"`, `"soil"`.
#'
#' @param x Variable id(s), key(s), name(s), fragment(s) or category
#'   shortcut(s). Numeric or character; vectors are allowed and are expanded
#'   in order, with duplicates removed.
#' @return An integer vector of variable ids.
#' @seealso [inia_variables()]
#' @family catalogue
#' @export
#' @examples
#' inia_var_id("precip")
#' inia_var_id(c("tmax", "tmin"))
#' inia_var_id("Precip. Acumulada (mm)")
#' inia_var_id("radiation")     # category shortcut -> all 3 radiation ids
#' inia_var_id(c(58, 59, 51))   # ids pass straight through
#'
#' # A near miss suggests the closest keys
#' try(inia_var_id("temperature"))
inia_var_id <- function(x) {
  vt <- .variable_table()
  sc <- .var_shortcuts()
  out <- unlist(lapply(x, function(one) .resolve_var_one(one, vt, sc)),
                use.names = FALSE)
  unique(as.integer(out))
}

.resolve_var_one <- function(one, vt, sc) {
  if (is.null(one) || length(one) != 1 || is.na(one)) {
    .abort_var(one, vt, "is missing")
  }

  num <- suppressWarnings(as.integer(sub("^\\s*([0-9]+)\\s*(=.*)?$", "\\1",
                                         as.character(one))))
  if (!is.na(num)) {
    if (num %in% vt$id) return(num)
    .abort_var(one, vt, "is not a known variable id")
  }

  key <- .norm(one)
  if (!nzchar(key)) .abort_var(one, vt, "is empty")

  # Category shortcuts first: "all", "soil", ...
  if (key %in% .norm(names(sc))) {
    return(vt$id[match(sc[[which(.norm(names(sc)) == key)]], vt$key)])
  }

  hit <- which(.norm(vt$key) == key | .norm(vt$name) == key |
                 .norm(vt$label) == key)
  if (length(hit) == 1) return(vt$id[hit])

  hit <- which(grepl(key, .norm(vt$key), fixed = TRUE) |
                 grepl(key, .norm(vt$name), fixed = TRUE) |
                 grepl(key, .norm(vt$label), fixed = TRUE))
  if (length(hit) == 1) return(vt$id[hit])
  if (length(hit) > 1) {
    shown <- vt$key[utils::head(hit, 8)]
    more <- length(hit) - length(shown)
    .abort_var(one, vt, sprintf(
      "is ambiguous: it matches %d variables (%s%s).\n  Narrow it down with %s",
      length(hit), paste(shown, collapse = ", "),
      if (more > 0) sprintf(", and %d more", more) else "",
      sprintf("inia_variables(%s)", encodeString(as.character(one), quote = '"'))))
  }
  .abort_var(one, vt, "does not match any variable")
}

.abort_var <- function(one, vt, why) {
  txt <- as.character(one)
  # Offer the nearest keys so a typo is one glance from being fixed.
  near <- character()
  if (length(txt) == 1 && !is.na(txt) && nzchar(txt)) {
    d <- utils::adist(.norm(txt), .norm(vt$key), partial = TRUE)[1, ]
    near <- vt$key[order(d)][seq_len(min(6, nrow(vt)))]
  }
  cats <- unique(vt$category)
  stop(
    "Variable ", encodeString(txt, quote = '"'), " ", why, ".\n\n",
    if (length(near)) paste0("Did you mean: ",
                             paste(near, collapse = ", "), "?\n\n") else "",
    "Ways to name a variable:\n",
    "  key        inia_var_id(\"precip\")\n",
    "  id         inia_var_id(51)\n",
    "  name       inia_var_id(\"Precipitation, accumulated\")\n",
    "  category   ", paste(names(.var_shortcuts()), collapse = ", "), "\n\n",
    "  inia_variables()          all 53 variables\n",
    "  inia_variables(\"rain\")    search by keyword\n",
    "  categories: ", paste(cats, collapse = " | "),
    call. = FALSE
  )
}
