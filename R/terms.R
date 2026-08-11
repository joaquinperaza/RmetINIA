# Terms of use of the INIA GRAS website -------------------------------------
#
# This package is a client for a free public service owned by INIA. Everything
# in this file exists so that the conditions INIA attaches to that service
# travel with the data instead of being left on the web page the user never
# sees: the source attribution requirement (condition 3) in particular is easy
# to breach by accident once data is inside R.
#
# The Spanish text below is reproduced verbatim from
# <https://www.inia.uy/gras/Clima/Banco-datos-agroclimatico> and
# <https://gras.inia.uy>. It is a notice, not package documentation, and must
# not be reworded.

.inia_terms_es <- function() {
  c(
    "CONDICIONES DE USO DEL SITIO WEB DE LA UNIDAD GRAS DEL INIA",
    "",
    "1) El acceso a toda la informacion que se presenta en el sitio web de la",
    "   Unidad GRAS del INIA es totalmente gratuito para todo tipo de usuario.",
    "",
    "2) INIA no tendra responsabilidad alguna por cualquier accion u omision que",
    "   tome el Usuario, o que deje de tomar, como consecuencia de los resultados",
    "   o referencias mostradas en este sitio web.",
    "",
    "3) Toda informacion que se extraiga del sitio web de la Unidad GRAS del INIA",
    "   y sea utilizada en publicaciones, presentaciones, sitio web, o cualquier",
    "   otro lugar, debera mencionar explicitamente y claramente dicho sitio como",
    "   la fuente de la misma.",
    "",
    "4) Ninguna reproduccion de cualquier parte de esta pagina web puede ser",
    "   vendida o distribuida con fines de lucro comercial ni modificada, salvo",
    "   previa autorizacion de INIA.",
    "",
    "5) Los emblemas y logos presentes, no deberan ser ocultados ni removidos de",
    "   ninguna pagina o elemento grafico propio en que figuren, ni podran ser",
    "   utilizados en paginas o elementos graficos ajenos, sin autorizacion previa",
    "   por parte de los webmaster (gras@inia.org.uy) del sitio web de la Unidad",
    "   GRAS del INIA.",
    "",
    "6) No se deberan establecer enlaces cuyo resultado sea la exhibicion de una",
    "   pagina o imagen del sitio web de la Unidad GRAS del INIA, enmarcada en un",
    "   recuadro ajeno.",
    "",
    "   Por el contrario, quedan autorizados todos aquellos enlaces que cumplan",
    "   las dos (2) condiciones siguientes:",
    "",
    "   a. Deberan estar senalados, clara e inequivocamente, como enlaces de",
    "      acceso al sitio web de la Unidad GRAS del INIA, o a una de sus paginas",
    "      secundarias.",
    "   b. No debera modificarse, ocultarse, ni removerse ningun contenido que",
    "      este presente en las paginas originales de la Unidad GRAS del INIA a",
    "      las que se vayan a acceder.",
    "",
    "BANCO DE DATOS AGROCLIMATICOS",
    "",
    "La base de datos climaticos de estaciones meteorologicas de INIA tiene como",
    "principal objetivo el apoyo a actividades de investigacion realizadas en las",
    "regionales del INIA.",
    "INIA no se responsabiliza por posibles errores y defectos de la misma que",
    "puedan afectar su utilizacion por terceros. Agradecemos la identificacion y",
    "notificacion de errores para la mejora de la misma (gras@inia.org.uy).",
    "",
    "Tambien se puede acceder a la serie historica de los datos abiertos de",
    "precipitaciones y temperaturas extremas de las estaciones de INIA La",
    "Estanzuela, Las Brujas, Salto Grande, Treinta y Tres y Tacuarembo a traves",
    "del Catalogo de Datos Abiertos:",
    "  https://catalogodatos.gub.uy/dataset/?q=inia"
  )
}

#' Terms of use of the INIA GRAS data
#'
#' Prints, verbatim, the conditions INIA attaches to the use of the GRAS website
#' and of the Banco de Datos Agroclimaticos. Reading them is your obligation as
#' a user of the service; this function only makes them reachable without
#' leaving R.
#'
#' The three conditions that bite most often in practice:
#'
#' * **Attribution is mandatory (condition 3).** Any use of this data in a
#'   publication, presentation or website must cite the GRAS website explicitly
#'   and clearly as the source. Use [inia_attribution()] to get a ready-made
#'   credit line, or `citation("RmetINIA")` for a formal reference.
#' * **No commercial resale or modified redistribution (condition 4)** without
#'   prior authorisation from INIA (`gras@inia.org.uy`).
#' * **INIA disclaims all liability (condition 2)** for errors or defects in the
#'   data and for anything you do, or fail to do, on the basis of it. Errors you
#'   find are welcome at `gras@inia.org.uy`.
#'
#' The MIT licence of this package covers the R source code only. It does not,
#' and cannot, licence the data: the data belongs to INIA and reaches you under
#' the terms below.
#'
#' @return The terms, invisibly, as a character vector of lines.
#' @family legal
#' @export
#' @examples
#' inia_terms()
inia_terms <- function() {
  txt <- .inia_terms_es()
  cat(txt, sep = "\n")
  cat("\nFuente / source: https://www.inia.uy/gras/Clima/Banco-datos-agroclimatico\n")
  invisible(txt)
}

#' Attribution line required when publishing INIA GRAS data
#'
#' Condition 3 of the GRAS terms of use requires that the GRAS website be named
#' explicitly and clearly as the source wherever the data is used. This returns
#' a credit line you can paste into a figure caption, a table footnote, a
#' methods section or a README.
#'
#' Every data frame returned by [inia_daily()] and [inia_stats()] carries this
#' same string in its `"attribution"` attribute, so it survives being passed
#' around a script:
#' `attr(x, "attribution")`.
#'
#' @param lang `"es"` (default) or `"en"`.
#' @param accessed Date of access, defaulting to today. Set to `NULL` to omit.
#' @return A length-one character vector.
#' @family legal
#' @export
#' @examples
#' inia_attribution()
#' inia_attribution("en")
#' inia_attribution(accessed = NULL)
inia_attribution <- function(lang = c("es", "en"), accessed = Sys.Date()) {
  lang <- match.arg(lang)
  when <- if (is.null(accessed)) "" else {
    sprintf(if (lang == "es") " (consultado el %s)" else " (accessed %s)",
            format(as.Date(accessed)))
  }
  if (lang == "es") {
    sprintf(paste0("Fuente: Banco de Datos Agroclimaticos, Unidad GRAS, ",
                   "Instituto Nacional de Investigacion Agropecuaria (INIA), ",
                   "Uruguay. https://www.inia.uy/gras/Clima/Banco-datos-agroclimatico%s"),
            when)
  } else {
    sprintf(paste0("Source: Banco de Datos Agroclimaticos, GRAS Unit, ",
                   "Instituto Nacional de Investigacion Agropecuaria (INIA), ",
                   "Uruguay. https://www.inia.uy/gras/Clima/Banco-datos-agroclimatico%s"),
            when)
  }
}

# Condition 3 is the one a user can breach without noticing, so the attribution
# requirement is surfaced once per session on the first download rather than
# only in the docs. `RmetINIA.quiet = TRUE` silences it for scripted use.
.inia_env <- new.env(parent = emptyenv())

.inia_notice_once <- function() {
  if (isTRUE(getOption("RmetINIA.quiet", FALSE))) return(invisible(NULL))
  if (isTRUE(.inia_env$notified)) return(invisible(NULL))
  .inia_env$notified <- TRUE
  packageStartupMessage(
    "Data (c) INIA Uruguay, Unidad GRAS. Free to use; citing the GRAS website ",
    "as the source\nis mandatory when you publish it. INIA accepts no liability ",
    "for errors in the data.\n  inia_attribution()  ready-made credit line\n",
    "  inia_terms()        full conditions of use\n",
    "  (silence with options(RmetINIA.quiet = TRUE))"
  )
  invisible(NULL)
}

#' Open the INIA GRAS data bank in a browser
#'
#' Opens the official page in your normal browser, unframed and unmodified, as
#' conditions 6a and 6b of the terms of use require.
#'
#' @param what `"databank"` for the Banco de Datos Agroclimaticos landing page,
#'   `"query"` for the interactive query form this package wraps, or
#'   `"opendata"` for the national open data catalogue entries for INIA
#'   rainfall and extreme temperature series.
#' @return The URL opened, invisibly.
#' @family legal
#' @export
#' @examples
#' \dontrun{
#' inia_browse()
#' inia_browse("query")
#' }
inia_browse <- function(what = c("databank", "query", "opendata")) {
  what <- match.arg(what)
  url <- switch(what,
    databank = "https://www.inia.uy/gras/Clima/Banco-datos-agroclimatico",
    query    = "https://gras.inia.uy/gras/es/ConsultasWebDBC/consulta_bdagroclima/",
    opendata = "https://catalogodatos.gub.uy/dataset/?q=inia"
  )
  utils::browseURL(url)
  invisible(url)
}
