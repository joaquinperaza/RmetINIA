.onAttach <- function(libname, pkgname) {
  if (isTRUE(getOption("RmetINIA.quiet", FALSE))) return(invisible(NULL))
  st <- .station_table()
  st <- st[order(st$id), ]
  packageStartupMessage(
    "RmetINIA ", utils::packageVersion("RmetINIA"),
    " \u2014 Banco de Datos Agroclimaticos, INIA Uruguay (Unidad GRAS)\n\n",
    paste(sprintf("  est = %d  %s %s from %s", st$id, .pad(st$code, 6),
                  .pad(st$name, 40), st$first_date), collapse = "\n"),
    "\n\n",
    '  inia_daily("LE", "2024-01-01", "2024-01-31", vars = "precip")\n',
    "  inia_cheatsheet()   inia_variables()   inia_terms()\n\n",
    "Data (c) INIA. Free to use; citing the GRAS website as the source is\n",
    "mandatory when you publish it. INIA accepts no liability for the data."
  )
}
