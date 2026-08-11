# Parsing the CSV export served by ver_exporta_datos_consulta ----------------
#
# The payload is not plain CSV. It is a station header line, then a CSV block,
# then (optionally) two trailer sections in prose:
#
#   INIA La Estanzuela (LE)
#   Fecha,Precip. Acumulada (mm),T. Media ((TM+Tm)/2) (oC)
#   2024-01-01,0.5,23.3
#   ...
#
#   Estas variables no tienen datos para el periodo seleccionado
#   Evaporacion Piche (mm)
#
#   Definicion de las variables listadas
#   Precip. Acumulada (mm)
#   "Precipitacion acumulada diaria, medida convencionalmente"
#
# The "no data" trailer matters: variables listed there are silently absent from
# the CSV block, so a caller who asked for five columns can get four back with
# no indication of which one went missing. We surface it as a warning.

.RE_DATE_ROW <- "^\"?[0-9]{4}-[0-9]{2}-[0-9]{2}\"?,"
.MARK_EMPTY <- "no tienen datos"
.MARK_DEFS <- "Definici.n de las variables"

.parse_export <- function(body) {
  lines <- strsplit(body, "\r?\n")[[1]]

  hdr_i <- which(grepl("^\"?Fecha\"?,", lines))[1]
  if (is.na(hdr_i)) {
    stop("Unexpected response from the INIA GRAS server: no 'Fecha' header row ",
         "was found. The export format may have changed.", call. = FALSE)
  }

  station <- .parse_station_header(if (hdr_i > 1) lines[1] else "")

  data_i <- which(grepl(.RE_DATE_ROW, lines))
  data_i <- data_i[data_i > hdr_i]
  # Stop at the first gap, so trailer text can never be mistaken for data.
  if (length(data_i)) {
    contiguous <- c(TRUE, diff(data_i) == 1L)
    data_i <- data_i[cumprod(contiguous) == 1L]
  }

  df <- utils::read.csv(
    text = paste(c(lines[hdr_i], lines[data_i]), collapse = "\n"),
    header = TRUE, check.names = FALSE, colClasses = "character",
    na.strings = c("", "NA"), encoding = "UTF-8"
  )
  names(df)[1] <- "date"
  df$date <- as.Date(df$date)
  for (j in seq_along(df)[-1]) df[[j]] <- as.numeric(df[[j]])

  list(
    data = df,
    station = station,
    empty_variables = .parse_trailer_empty(lines),
    definitions = .parse_trailer_defs(body)
  )
}

# "INIA Tacuarembo - Glencoe (TA-GL)" -> name + code
.parse_station_header <- function(line) {
  line <- trimws(line)
  m <- regmatches(line, regexec("^(.*)\\s+\\(([^()]+)\\)\\s*$", line))[[1]]
  if (length(m) == 3) {
    list(name = trimws(m[2]), code = trimws(m[3]))
  } else {
    list(name = if (nzchar(line)) line else NA_character_, code = NA_character_)
  }
}

.parse_trailer_empty <- function(lines) {
  i <- which(grepl(.MARK_EMPTY, lines))[1]
  if (is.na(i)) return(character())
  out <- character()
  for (ln in lines[seq.int(i + 1L, length(lines))]) {
    if (grepl(.MARK_DEFS, ln)) break
    ln <- trimws(gsub('^"|"$', "", ln))
    if (nzchar(ln)) out <- c(out, ln)
  }
  out
}

# The definitions block is quoted CSV whose fields may span several lines, so it
# is parsed as records rather than by splitting on newlines. Records that match a
# known variable label open a new entry; anything else is continuation text.
.parse_trailer_defs <- function(body) {
  i <- regexpr(.MARK_DEFS, body)
  empty <- data.frame(label = character(), definition = character(),
                      stringsAsFactors = FALSE)
  if (i < 0) return(empty)

  tail_txt <- substring(body, i)
  tail_txt <- sub("^[^\n]*\n", "", tail_txt)   # drop the marker line itself

  recs <- tryCatch(
    utils::read.csv(text = tail_txt, header = FALSE, sep = ",", quote = '"',
                    blank.lines.skip = TRUE, colClasses = "character",
                    col.names = "x", fill = TRUE, encoding = "UTF-8")$x,
    error = function(e) character()
  )
  recs <- trimws(recs)
  recs <- recs[nzchar(recs)]
  if (!length(recs)) return(empty)

  known <- .norm(.variable_table()$label)
  labels <- character()
  defs <- character()
  for (r in recs) {
    if (.norm(r) %in% known) {
      labels <- c(labels, r)
      defs <- c(defs, "")
    } else if (length(labels)) {
      defs[length(defs)] <- trimws(gsub("\\s+", " ",
                                        paste(defs[length(defs)], r)))
    }
  }
  if (!length(labels)) return(empty)
  data.frame(label = labels, definition = defs, stringsAsFactors = FALSE)
}
