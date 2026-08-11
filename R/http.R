#' Base URL of the GRAS/INIA agroclimatic query service
#'
#' Exposed so it can be overridden for testing, or pointed at a mirror, with
#' `options(RmetINIA.base_url = "...")`.
#'
#' @return A length-one character vector.
#' @export
#' @examples
#' inia_base_url()
inia_base_url <- function() {
  getOption("RmetINIA.base_url", "https://gras.inia.uy/gras/es/ConsultasWebDBC")
}

.inia_user_agent <- function() {
  getOption(
    "RmetINIA.user_agent",
    sprintf("RmetINIA/%s (R package; +https://gras.inia.uy)",
            utils::packageVersion("RmetINIA"))
  )
}

# Perform a GET against the GRAS service and return the body as a UTF-8 string.
#
# Two non-obvious details about this server, both discovered empirically and
# both required for the request to succeed at all:
#
#   1. Requests negotiated over HTTP/2 are answered with a Cloudflare interstitial
#      (HTTP 403 "Just a moment..."). The same request over HTTP/1.1 succeeds.
#      `http_version = 2` is libcurl's CURL_HTTP_VERSION_1_1.
#   2. libcurl's default `curl/<version>` User-Agent is also rejected. We send an
#      honest, self-identifying agent string instead.
#
# Requests are rate limited to be a polite client of a free public service.
.inia_get <- function(path, query, timeout = 120) {
  req <- httr2::request(paste0(inia_base_url(), path))
  req <- httr2::req_url_query(req, !!!query)
  req <- httr2::req_user_agent(req, .inia_user_agent())
  req <- httr2::req_options(req, http_version = 2)
  req <- httr2::req_timeout(req, timeout)
  req <- httr2::req_throttle(req, rate = getOption("RmetINIA.rate", 1))
  req <- httr2::req_retry(req, max_tries = 3, backoff = function(i) 2^i)

  resp <- tryCatch(
    httr2::req_perform(req),
    httr2_http = function(e) {
      stop(sprintf(
        "The INIA GRAS server refused the request (HTTP %s).\n  URL: %s",
        e$resp$status_code, req$url
      ), call. = FALSE)
    },
    httr2_failure = function(e) {
      stop(sprintf(
        paste0("Could not reach the INIA GRAS server (%s).\n",
               "  Check your internet connection, then retry."),
        conditionMessage(e)
      ), call. = FALSE)
    }
  )

  body <- httr2::resp_body_string(resp, encoding = "UTF-8")

  # The service answers invalid parameter combinations with a 200 OK HTML page
  # rather than an error status, so the payload has to be sniffed.
  if (grepl("^\\s*<!doctype html|^\\s*<html", body, ignore.case = TRUE)) {
    stop(
      "The INIA GRAS server returned an HTML page instead of data.\n",
      "  This normally means the query itself was rejected — usually an unknown\n",
      "  station id, or a start date later than the end date.\n",
      "  URL: ", req$url,
      call. = FALSE
    )
  }
  body
}
