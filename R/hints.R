# Editor-facing discovery aids ------------------------------------------------
#
# Three mechanisms, deliberately overlapping, so that a user finds the ids they
# need without leaving the console:
#
#   inia_station$<Tab>   list with one element per station -> id
#   inia_var$<Tab>       list with one element per variable -> id
#   inia_daily(est = <Tab>)  the formal default is the labelled station list
#
# The first two work in any editor that completes list names; the third works
# wherever function defaults are shown.

.make_choices <- function(values, labels, what) {
  out <- as.list(values)
  names(out) <- labels
  structure(out, class = c("inia_choices", "list"), what = what)
}

#' Station ids by name
#'
#' A named list mapping readable station slugs to the numeric ids the GRAS web
#' API uses. Type `inia_station$` and press Tab to see all six with completion.
#'
#' Using this is optional -- [inia_daily()] accepts `"LE"`, `"estanzuela"` or `2`
#' just as happily. It exists so that ids never have to be memorised or looked
#' up on the website.
#'
#' @format A list of six integers, named `la_estanzuela`, `las_brujas`,
#'   `salto_grande`, `glencoe`, `la_magnolia`, `paso_de_la_laguna`.
#' @seealso [inia_stations()] for the full table, [inia_var] for variables.
#' @family catalogue
#' @export
#' @examples
#' inia_station$la_estanzuela
#' names(inia_station)
#'
#' \dontrun{
#' inia_daily(inia_station$las_brujas, "2024-01-01", "2024-01-31")
#' }
inia_station <- local({
  st <- .station_table()
  st <- st[order(st$id), ]
  .make_choices(st$id, st$slug, "station")
})

#' Variable ids by name
#'
#' A named list mapping the package's ASCII variable keys to the numeric ids the
#' GRAS web API uses. Type `inia_var$` and press Tab to browse all 53 with
#' completion -- `inia_var$soil` narrows to the soil temperature probes,
#' `inia_var$gdd` to the growing degree day bases, and so on.
#'
#' @format A list of 53 integers, named by variable key.
#' @seealso [inia_variables()] for the full table with units and definitions,
#'   [inia_station] for stations.
#' @family catalogue
#' @export
#' @examples
#' inia_var$precip
#' inia_var$tmax
#'
#' # Every growing degree day base
#' grep("^gdd", names(inia_var), value = TRUE)
#'
#' \dontrun{
#' inia_daily("LE", "2024-01-01", "2024-01-31",
#'            vars = c(inia_var$tmax, inia_var$tmin))
#' }
inia_var <- local({
  vt <- .variable_table()
  vt <- vt[order(vt$category, vt$key), ]
  .make_choices(vt$id, vt$key, "variable")
})

#' @export
print.inia_choices <- function(x, ...) {
  what <- attr(x, "what")
  cat(length(x), " ", what, " ids. Use with $, e.g. inia_",
      substr(what, 1, if (what == "station") 7 else 3), "$", names(x)[1],
      "\n\n", sep = "")
  nm <- names(x)
  w <- max(nchar(nm)) + 2
  for (i in seq_along(x)) {
    cat(sprintf("  %-*s %3d\n", w, nm[i], x[[i]]))
  }
  invisible(x)
}

# Completion hook used by RStudio and by utils::rc.settings(). Returning the
# names here is what makes `inia_var$<Tab>` list the keys.
#
# The generic lives in utils and must be imported, not merely referenced: S3
# method registration happens at namespace load, when only base is attached.
#' @importFrom utils .DollarNames
#' @export
.DollarNames.inia_choices <- function(x, pattern = "") {
  grep(pattern, names(x), value = TRUE)
}

#' Show a quick reference for this package
#'
#' Prints the stations, the variable categories and a worked example, so the
#' whole API surface is one call away from the console.
#'
#' @return `NULL`, invisibly.
#' @export
#' @examples
#' inia_cheatsheet()
inia_cheatsheet <- function() {
  st <- .station_table()
  vt <- .variable_table()

  cat("RmetINIA \u2014 INIA Uruguay agroclimatic data bank\n")
  cat(strrep("-", 68), "\n\n", sep = "")

  cat("STATIONS  (est = id | code | slug | name | fragment)\n")
  cat(sprintf("  %-3s %-6s %-40s %s\n", "id", "code", "name", "data from"))
  for (i in order(st$id)) {
    cat(sprintf("  %-3d %s %s %s\n", st$id[i], .pad(st$code[i], 6),
                .pad(st$name[i], 40), st$first_date[i]))
  }

  cat("\nVARIABLES  (vars = id | key | name | fragment | category)\n")
  tb <- table(vt$category)
  for (nm in names(tb)) {
    keys <- vt$key[vt$category == nm]
    cat(sprintf("  %-22s %2d  e.g. %s\n", nm, tb[[nm]],
                paste(utils::head(keys, 3), collapse = ", ")))
  }
  cat("  shortcuts: ", paste(names(.var_shortcuts()), collapse = ", "), "\n",
      sep = "")

  cat("\nEXAMPLES\n")
  cat('  inia_daily("LE", "2024-01-01", "2024-01-31", vars = "precip")\n')
  cat('  inia_daily(2, vars = c("tmax", "tmin"))          # full record\n')
  cat('  inia_daily(c("LE","LB"), vars = "air", long = TRUE)\n')
  cat('  inia_stats("LE", "precip", "2000-01-01", "2020-12-31")\n')

  cat("\nDISCOVERY\n")
  cat("  inia_stations()            inia_variables(\"humidity\")\n")
  cat("  inia_station$<Tab>         inia_var$<Tab>\n")
  cat("  inia_station_id(\"brujas\")  inia_var_id(\"soil\")\n")

  cat("\nTERMS OF USE\n")
  cat("  Free for all users. Citing the GRAS website as the source is\n")
  cat("  mandatory when publishing. INIA accepts no liability for the data.\n")
  cat("  inia_terms()   inia_attribution()   inia_browse()\n")
  invisible(NULL)
}
