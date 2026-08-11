#' RmetINIA: agroclimatic data from INIA Uruguay
#'
#' A client for the Banco de Datos Agroclimaticos of INIA Uruguay
#' (Instituto Nacional de Investigacion Agropecuaria), served by the GRAS unit
#' at <https://gras.inia.uy>. It wraps the public CSV export behind the
#' interactive query form, and carries catalogues of the six stations and 53
#' variables so that ids can be discovered from R.
#'
#' @section Getting started:
#' ```r
#' inia_cheatsheet()                                    # one-screen overview
#' inia_stations()                                      # the six stations
#' inia_variables("rain")                               # find a variable
#' inia_daily("LE", "2024-01-01", "2024-01-31",         # download
#'            vars = c("precip", "tmax", "tmin"))
#' ```
#'
#' @section Terms of use -- read before publishing:
#' The data is free for every type of user, but it is not public domain and it
#' is not covered by this package's MIT licence, which applies to the R source
#' code only. INIA's conditions require in particular that:
#'
#' * the GRAS website be cited **explicitly and clearly** as the source in any
#'   publication, presentation or website that uses the data;
#' * no part of the site be sold, redistributed for commercial profit, or
#'   modified, without prior authorisation from INIA;
#' * INIA's emblems and logos not be removed, hidden or reused elsewhere without
#'   authorisation.
#'
#' INIA accepts no liability for errors or defects in the data, nor for any
#' action taken or not taken on the basis of it; errors found are welcome at
#' `gras@inia.org.uy`. Call [inia_terms()] for the conditions in full and
#' [inia_attribution()] for a ready-made credit line.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
## usethis namespace: end
NULL
