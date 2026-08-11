# Built-in catalogues of stations and variables ------------------------------
#
# These mirror the `listado_estaciones` JSON block and the variable accordion
# rendered by <https://gras.inia.uy/gras/es/ConsultasWebDBC/consulta_bdagroclima/>.
# They are embedded so the package is usable (and auto-completable) offline;
# `inia_stations(refresh = TRUE)` / `inia_variables(refresh = TRUE)` re-scrape
# the live page.

# `first_date` is the first day with data reported by the web form. `last_date`
# is not embedded: it advances daily, so it is looked up live on refresh.
.station_table <- function() {
  utils::read.table(
    text = "
id|code|name|slug|first_date
2|LE|INIA La Estanzuela|la_estanzuela|1965-07-01
1|LB|INIA Las Brujas|las_brujas|1972-07-01
5|SG|INIA Salto Grande|salto_grande|1970-07-01
6|TA-GL|INIA Tacuaremb\u00f3 - Glencoe|glencoe|2016-11-01
3|TA-LM|INIA Tacuaremb\u00f3 - La Magnolia|la_magnolia|1978-02-01
4|TT-PL|INIA Treinta y Tres - Paso de la Laguna|paso_de_la_laguna|1971-01-01
",
    sep = "|", header = TRUE, stringsAsFactors = FALSE, quote = "",
    colClasses = c("integer", "character", "character", "character", "character")
  )
}

# Columns:
#   id       - the numeric id used by the `vars=` query parameter
#   key      - stable ASCII slug, the recommended way to ask for a variable
#   name     - short English name
#   unit     - measurement unit
#   category - English category, matching the accordion groups on the web form
#   label    - the exact column header returned by the server (Spanish)
#   category_es / description - as shown on the web form
.variable_table <- function() {
  utils::read.table(
    text = "
id|key|name|unit|category|label|category_es|description
58|tmax|Air temperature, maximum|degC|Air|Temp. Aire M\u00e1xima (\u00baC)|Aire (Temp., HR., Viento)|Daily maximum air temperature in the standard screen.
59|tmin|Air temperature, minimum|degC|Air|Temp. Aire M\u00ecnima (\u00baC)|Aire (Temp., HR., Viento)|Daily minimum air temperature in the standard screen.
78|tmean|Air temperature, mean (24 h)|degC|Air|Temp. Aire Media (\u00baC)|Aire (Temp., HR., Viento)|Mean air temperature over the 24 hourly readings.
60|tmean_minmax|Air temperature, mean (max+min)/2|degC|Air|T. Media ((TM+Tm)/2) (\u00baC)|Aire (Temp., HR., Viento)|Daily mean computed as (maximum + minimum) / 2.
64|tmin_grass|Minimum temperature over grass|degC|Air|T.M\u00edn. s/c\u00e9sped (\u00baC)|Aire (Temp., HR., Viento)|Minimum temperature measured 5 cm above a grass surface.
83|t_range|Diurnal temperature range|degC|Air|Amplitud T\u00e9rmica (\u00baC)|Aire (Temp., HR., Viento)|Maximum minus minimum air temperature.
81|frost_agro|Agrometeorological frost|0/1|Air|Helada Agromet. (S:1/N:0)|Aire (Temp., HR., Viento)|1 when temperature over grass (5 cm) was 0 degC or lower, 0 otherwise.
82|frost_met|Meteorological frost|0/1|Air|Helada Meteo. (S:1/N:0)|Aire (Temp., HR., Viento)|1 when screen minimum temperature was 0 degC or lower, 0 otherwise.
65|wind_run|Wind run at 2 m|km/day|Air|Recorrido Viento (km/dia)|Aire (Temp., HR., Viento)|Horizontal wind run at two metres above ground.
69|rh_max|Relative humidity, maximum|%|Air|HR M\u00e1xima (%)|Aire (Temp., HR., Viento)|Highest relative humidity of the day.
70|rh_min|Relative humidity, minimum|%|Air|HR M\u00ednima (%)|Aire (Temp., HR., Viento)|Lowest relative humidity of the day.
71|rh_mean|Relative humidity, mean|%|Air|HR Media (%)|Aire (Temp., HR., Viento)|Mean of the 24 hourly relative humidity readings.
92|rh_90_99_hours|Hours with RH 90-99%|h|Air|HR >=90% y <=99% (Horas)|Aire (Temp., HR., Viento)|Hours in the day with relative humidity between 90% and 99%.
93|rh_100_hours|Hours with RH = 100%|h|Air|Humedad Rel. = 100% (Hrs)|Aire (Temp., HR., Viento)|Hours in the day with relative humidity equal to 100%.
51|precip|Precipitation, accumulated|mm|Rain and evaporation|Precip. Acumulada (mm)|Precipitaci\u00f3n y Evaporaci\u00f3n|Daily accumulated rainfall, measured conventionally.
87|precip_effective|Precipitation, effective|mm|Rain and evaporation|Precip. Efectiva (mm)|Precipitaci\u00f3n y Evaporaci\u00f3n|Daily rainfall minus surface runoff.
91|rained|Rain occurred|0/1|Rain and evaporation|Llovi\u00f3 (S:1/N:0)|Precipitaci\u00f3n y Evaporaci\u00f3n|1 when rainfall was recorded that day, 0 otherwise.
62|evap_piche|Evaporation, Piche|mm|Rain and evaporation|Evaporaci\u00f3n Pich\u00e9 (mm)|Precipitaci\u00f3n y Evaporaci\u00f3n|Water evaporated in 24 h without solar influence (Piche evaporimeter).
63|evap_pan_a|Evaporation, class A pan|mm|Rain and evaporation|Evaporaci\u00f3n Tanque A (mm)|Precipitaci\u00f3n y Evaporaci\u00f3n|Water evaporated in 24 h from a class A pan (sun and wind exposed).
85|et0_penman|Reference evapotranspiration, Penman-Monteith|mm|Rain and evaporation|Evapotransp. Penman (mm)|Precipitaci\u00f3n y Evaporaci\u00f3n|FAO Penman-Monteith reference evapotranspiration, adjusted for Uruguay.
1|sunshine_hours|Sunshine duration|h|Solar radiation|Heliofan\u00eda (Hrs.)|Radiaci\u00f3n Solar|Hours of direct insolation from the Campbell-Stokes band.
84|sunshine_relative|Relative sunshine duration|%|Solar radiation|Heliofan\u00eda Relativa (%)|Radiaci\u00f3n Solar|Actual sunshine as a percentage of the maximum possible for the day and latitude.
86|solar_radiation|Solar radiation (Angstrom)|cal/cm2|Solar radiation|Rad.Solar (xHelio)cal/cm\u00b2|Radiaci\u00f3n Solar|Solar radiation estimated with the Angstrom formula from relative sunshine.
97|gdd_4_5|Growing degree days, base 4.5 degC|degC|Cold and heat indices|Grados Dias 04.5\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 4.5 degC; empty when the mean is below the base.
96|gdd_6_0|Growing degree days, base 6.0 degC|degC|Cold and heat indices|Grados Dias 06.0\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 6.0 degC; empty when the mean is below the base.
98|gdd_7_0|Growing degree days, base 7.0 degC|degC|Cold and heat indices|Grados Dias 07.0\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 7.0 degC; empty when the mean is below the base.
99|gdd_8_0|Growing degree days, base 8.0 degC|degC|Cold and heat indices|Grados Dias 08.0\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 8.0 degC; empty when the mean is below the base.
100|gdd_9_0|Growing degree days, base 9.0 degC|degC|Cold and heat indices|Grados Dias 09.0\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 9.0 degC; empty when the mean is below the base.
101|gdd_10_0|Growing degree days, base 10.0 degC|degC|Cold and heat indices|Grados Dias 10.0\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 10.0 degC; empty when the mean is below the base.
102|gdd_10_5|Growing degree days, base 10.5 degC|degC|Cold and heat indices|Grados Dias 10.5\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 10.5 degC; empty when the mean is below the base.
103|gdd_12_8|Growing degree days, base 12.8 degC|degC|Cold and heat indices|Grados Dias 12.8\u00ba (\u00baC)|Indices Fr\u00edo y Calor|Daily mean temperature minus 12.8 degC; empty when the mean is below the base.
88|thermal_units_rice|Thermal units for rice|units|Cold and heat indices|Un. T\u00e9rmicas Arroz|Indices Fr\u00edo y Calor|(max + min)/2 minus 10 degC, capping max at 34 degC and min at 21 degC; 0 when below base.
89|chill_units_richardson|Chill units (Richardson)|units|Cold and heat indices|Unidad Fr\u00edo (Richardson)|Indices Fr\u00edo y Calor|Daily sum of hourly Richardson chill units for dormancy break.
90|chill_hours_weinberger|Chill hours, T <= 7.2 degC (Weinberger)|h|Cold and heat indices|T <=7.2 (Weinberger)(Hrs)|Indices Fr\u00edo y Calor|Hours in the day with temperature at or below 7.2 degC.
94|tmin_below_15|Minimum temperature below 15 degC|0/1|Cold and heat indices|T.Min < 15\u00baC (S:1/N:0)|Indices Fr\u00edo y Calor|1 when the screen minimum temperature was below 15 degC, 0 otherwise.
39|soil_cov_5cm_max|Soil temperature, grass-covered, 5 cm, maximum|degC|Soil|Temp. SC 05cm (max) (\u00baC)|Suelo|Maximum temperature 5 cm deep under grass cover.
57|soil_cov_5cm_mean|Soil temperature, grass-covered, 5 cm, mean|degC|Soil|Temp. SC 05cm (med) (\u00baC)|Suelo|Mean temperature 5 cm deep under grass cover.
42|soil_cov_5cm_min|Soil temperature, grass-covered, 5 cm, minimum|degC|Soil|Temp. SC 05cm (min) (\u00baC)|Suelo|Minimum temperature 5 cm deep under grass cover.
40|soil_cov_10cm_max|Soil temperature, grass-covered, 10 cm, maximum|degC|Soil|Temp. SC 10cm (max) (\u00baC)|Suelo|Maximum temperature 10 cm deep under grass cover.
55|soil_cov_10cm_mean|Soil temperature, grass-covered, 10 cm, mean|degC|Soil|Temp. SC 10cm (med) (\u00baC)|Suelo|Mean temperature 10 cm deep under grass cover.
43|soil_cov_10cm_min|Soil temperature, grass-covered, 10 cm, minimum|degC|Soil|Temp. SC 10cm (min) (\u00baC)|Suelo|Minimum temperature 10 cm deep under grass cover.
41|soil_cov_20cm_max|Soil temperature, grass-covered, 20 cm, maximum|degC|Soil|Temp. SC 20cm (max) (\u00baC)|Suelo|Maximum temperature 20 cm deep under grass cover.
56|soil_cov_20cm_mean|Soil temperature, grass-covered, 20 cm, mean|degC|Soil|Temp. SC 20cm (med) (\u00baC)|Suelo|Mean temperature 20 cm deep under grass cover.
44|soil_cov_20cm_min|Soil temperature, grass-covered, 20 cm, minimum|degC|Soil|Temp. SC 20cm (min) (\u00baC)|Suelo|Minimum temperature 20 cm deep under grass cover.
50|soil_bare_5cm_max|Soil temperature, bare, 5 cm, maximum|degC|Soil|Temp. SD 05cm (max) (\u00baC)|Suelo|Maximum temperature 5 cm deep in bare soil.
52|soil_bare_5cm_mean|Soil temperature, bare, 5 cm, mean|degC|Soil|Temp. SD 05cm (med) (\u00baC)|Suelo|Mean temperature 5 cm deep in bare soil.
46|soil_bare_5cm_min|Soil temperature, bare, 5 cm, minimum|degC|Soil|Temp. SD 05cm (min) (\u00baC)|Suelo|Minimum temperature 5 cm deep in bare soil.
48|soil_bare_10cm_max|Soil temperature, bare, 10 cm, maximum|degC|Soil|Temp. SD 10cm (max) (\u00baC)|Suelo|Maximum temperature 10 cm deep in bare soil.
53|soil_bare_10cm_mean|Soil temperature, bare, 10 cm, mean|degC|Soil|Temp. SD 10cm (med) (\u00baC)|Suelo|Mean temperature 10 cm deep in bare soil.
45|soil_bare_10cm_min|Soil temperature, bare, 10 cm, minimum|degC|Soil|Temp. SD 10cm (min) (\u00baC)|Suelo|Minimum temperature 10 cm deep in bare soil.
49|soil_bare_20cm_max|Soil temperature, bare, 20 cm, maximum|degC|Soil|Temp. SD 20cm (max) (\u00baC)|Suelo|Maximum temperature 20 cm deep in bare soil.
54|soil_bare_20cm_mean|Soil temperature, bare, 20 cm, mean|degC|Soil|Temp. SD 20cm (med) (\u00baC)|Suelo|Mean temperature 20 cm deep in bare soil.
47|soil_bare_20cm_min|Soil temperature, bare, 20 cm, minimum|degC|Soil|Temp. SD 20cm (min) (\u00baC)|Suelo|Minimum temperature 20 cm deep in bare soil.
",
    sep = "|", header = TRUE, stringsAsFactors = FALSE, quote = "",
    colClasses = c("integer", rep("character", 7))
  )
}

# Category shortcuts accepted by `vars =`. `common` is the set most users of the
# web form pick first; `all` is every variable in the catalogue.
.var_shortcuts <- function() {
  list(
    all = .variable_table()$key,
    common = c("tmax", "tmin", "tmean_minmax", "precip", "rh_mean",
               "wind_run", "solar_radiation"),
    air = .variable_table()$key[.variable_table()$category == "Air"],
    rain = .variable_table()$key[.variable_table()$category == "Rain and evaporation"],
    radiation = .variable_table()$key[.variable_table()$category == "Solar radiation"],
    indices = .variable_table()$key[.variable_table()$category == "Cold and heat indices"],
    soil = .variable_table()$key[.variable_table()$category == "Soil"]
  )
}
