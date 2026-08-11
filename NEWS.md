# RmetINIA 0.2.0

## Terms of use and attribution

* Added `inia_terms()`, which prints INIA's conditions of use for the GRAS
  website verbatim, and `inia_attribution()`, which returns the source credit
  line those conditions require (`lang = "es"` or `"en"`).
* Every result from `inia_daily()` and `inia_stats()` now carries that credit
  line in its `"attribution"` attribute, so it survives being passed around a
  script.
* Added `inst/CITATION`, so `citation("RmetINIA")` returns a reference for the
  data bank first and for the software second.
* The attribution requirement is surfaced once per session on the first
  download, and on attach. Silence both with `options(RmetINIA.quiet = TRUE)`.
* Added `inia_browse()`, which opens the official pages unframed and unmodified.
* Added `inia_write_csv()`, which writes UTF-8 with a byte order mark and `.`
  decimals so Excel opens the file cleanly on any locale, and writes the source
  credit into the file as a leading comment.
* `DESCRIPTION` now records INIA/GRAS as copyright holder and data contributor,
  and states that the MIT licence covers the R code only.

## Fixes

* Fixed a namespace load failure: `.DollarNames` is now imported from `utils`
  rather than merely referenced, so `inia_var$<Tab>` completion registers when
  the namespace is loaded with only base attached.
* The warning about variables the server dropped for having no data is no longer
  suppressed by `quiet = TRUE`; `quiet` now only silences progress messages.
  Silently returning fewer columns than were requested is the failure this check
  exists to catch.
* `inia_stations(refresh = TRUE)` and `inia_variables(refresh = TRUE)` no longer
  fail against the HTML guard that protects the data endpoints.
* An unparseable `from` or `to` now reports which argument was wrong instead of
  surfacing `as.Date()`'s "standard unambiguous format" error.
* Ambiguous variable matches list the first eight candidates and a way to
  narrow the search, instead of printing up to 25 keys.
* Messages and error tables align correctly around accented station names,
  which `sprintf()` pads by bytes rather than display width.
* All R source is now ASCII, with `\uxxxx` escapes for Spanish text.

## Package

* Renamed from `iniaR` to `RmetINIA`.
* Added GitHub Actions workflows for `R CMD check` on Linux/macOS/Windows, and
  a weekly job that checks the embedded catalogues against the live GRAS site.
* Added a test suite: 120 offline tests plus 32 opt-in tests against the live
  service (`RMETINIA_LIVE_TESTS=true`).

# RmetINIA 0.1.0

* First version.
* `inia_daily()` / `inia_data()` download daily observations for one or more
  stations, with `long`, `tidy_names` and `quiet` options.
* `inia_stats()` downloads INIA's statistical report for a single variable,
  broken down by year, month and ten-day period.
* Embedded catalogues of the 6 stations and 53 variables, with live refresh via
  `inia_stations(refresh = TRUE)` and `inia_variables(refresh = TRUE)`.
* Stations and variables can be named by id, code, slug, English or Spanish
  name, or unambiguous fragment; unresolvable input errors with the valid
  options listed (`inia_station_id()`, `inia_var_id()`).
* Completion aids `inia_station$`, `inia_var$` and `inia_cheatsheet()`.
* Requests are forced onto HTTP/1.1 and sent with a self-identifying
  User-Agent, both of which the GRAS host requires; throttled to one request per
  second.
