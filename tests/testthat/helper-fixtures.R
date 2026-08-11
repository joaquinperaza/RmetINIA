# Synthetic responses in the exact wire format of the GRAS export endpoint.
#
# The *values* below are invented, not downloaded. INIA's terms of use restrict
# redistribution of their data, so the package ships no real observations; these
# fixtures exercise the parser's handling of the format only.

fixture_export <- function() {
  paste(
    "INIA La Estanzuela (LE)",
    "Fecha,Precip. Acumulada (mm),T. Media ((TM+Tm)/2) (ºC)",
    "2024-01-01,1.1,20.0",
    "2024-01-02,0.0,21.0",
    "2024-01-03,,22.0",
    "",
    "",
    "Definición de las variables listadas",
    "Precip. Acumulada (mm)",
    "\"Precipitación acumulada diaria, medida convencionalmente\"",
    "",
    "T. Media ((TM+Tm)/2) (ºC)",
    "Temperatura media del día calculada utilizando la temperatura máxima y la mínima.",
    sep = "\n"
  )
}

# Same, but with a variable the server dropped for lack of data.
fixture_export_empty_var <- function() {
  paste(
    "INIA Tacuarembó - Glencoe (TA-GL)",
    "Fecha,Precip. Acumulada (mm)",
    "2017-01-01,0.0",
    "2017-01-02,3.3",
    "",
    "",
    "Estas variables no tienen datos para el período seleccionado",
    "Evaporación Piché (mm)",
    "",
    "Definición de las variables listadas",
    "Precip. Acumulada (mm)",
    "\"Precipitación acumulada diaria, medida convencionalmente\"",
    sep = "\n"
  )
}

fixture_stats <- function() {
  paste(
    "INIA La Estanzuela (LE)",
    "Precip. Acumulada (mm)",
    "",
    "A,Año,count,mean,std,min,5%,25%,50%,75%,95%,max,Suma",
    "A,2000,366.0,3.5,10.0,0.0,0.0,0.0,0.0,0.7,23.0,88.0,1300.0",
    "A,2001,365.0,4.0,11.0,0.0,0.0,0.0,0.0,1.2,31.0,84.0,1500.0",
    "",
    "M,Mes,count,mean,std,min,5%,25%,50%,75%,95%,max,Suma",
    "M,enero,62.0,3.4,10.8,0.0,0.0,0.0,0.0,0.1,26.0,83.0,220.0",
    "",
    "D,Década,count,mean,std,min,5%,25%,50%,75%,95%,max,Suma",
    "D,ene 1a. déc.,20.0,2.0,8.0,0.0,0.0,0.0,0.0,0.0,15.0,60.0,40.0",
    sep = "\n"
  )
}

skip_if_offline_inia <- function() {
  testthat::skip_on_cran()
  testthat::skip_if_not(
    isTRUE(as.logical(Sys.getenv("RMETINIA_LIVE_TESTS", "false"))),
    "live INIA tests disabled (set RMETINIA_LIVE_TESTS=true to run)"
  )
}
