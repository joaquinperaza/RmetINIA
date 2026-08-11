# RmetINIA

<!-- badges: start -->
[![R-CMD-check](https://github.com/joaquinperaza/RmetINIA/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/joaquinperaza/RmetINIA/actions/workflows/R-CMD-check.yaml)
[![live-catalogue-check](https://github.com/joaquinperaza/RmetINIA/actions/workflows/live-catalogue-check.yaml/badge.svg)](https://github.com/joaquinperaza/RmetINIA/actions/workflows/live-catalogue-check.yaml)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

An R client for the **Banco de Datos Agroclimáticos** of INIA Uruguay
(Instituto Nacional de Investigación Agropecuaria), served by the
[Unidad GRAS](https://gras.inia.uy).

It wraps the CSV export behind the
[interactive query form](https://gras.inia.uy/gras/es/ConsultasWebDBC/consulta_bdagroclima/)
and carries catalogues of the **6 stations** and **53 variables**, so station
and variable ids can be discovered and auto-completed from R instead of being
looked up on the website.

```r
inia_daily("LE", "2024-01-01", "2024-01-31", vars = c("precip", "tmax", "tmin"))
#>   station_id station       date precip tmax tmin
#> 1          2      LE 2024-01-01    0.5 30.1 16.5
#> ...
```

---

## Installation

Not on CRAN. Install straight from GitHub:

```r
# install.packages("remotes")
remotes::install_github("joaquinperaza/RmetINIA")
```

Or with [pak](https://pak.r-lib.org), which resolves dependencies faster:

```r
# install.packages("pak")
pak::pak("joaquinperaza/RmetINIA")
```

Or:
```r
devtools::install_github("joaquinperaza/RmetINIA")
```


### Dependencies

The only hard dependency is [httr2](https://httr2.r-lib.org), and the installers
above pull it in automatically. `rvest` and `xml2` are optional, needed only by
`inia_variables(refresh = TRUE)`:

```r
install.packages(c("rvest", "xml2"))
```

### Checking it worked

```r
library(RmetINIA)
packageVersion("RmetINIA")
inia_cheatsheet()
```

---

## Terms of use — read this before publishing

The data is **free for every type of user**, but it is *not* public domain and
it is *not* covered by this package's MIT licence, which applies to the R source
code only. INIA's conditions, reproduced in full by `inia_terms()`, require in
particular that:

1. **Attribution is mandatory.** Any use of the data in a publication,
   presentation or website must cite the GRAS website **explicitly and clearly**
   as the source.
2. **No commercial resale or modified redistribution** of any part of the site
   without prior authorisation from INIA (`gras@inia.org.uy`).
3. **INIA's emblems and logos** must not be removed, hidden, or reused
   elsewhere without authorisation.
4. **No framing.** Links must be clearly signposted as links to the GRAS site,
   and must not alter or hide its content.

INIA accepts **no liability** for errors or defects in the data, nor for any
action you take or fail to take on the basis of it. The database exists
primarily to support research at INIA's regional stations. Errors you find are
welcome at `gras@inia.org.uy`.

The package is built so the attribution requirement is hard to breach by
accident:

```r
inia_terms()          # the conditions, verbatim, in Spanish
inia_attribution()    # a ready-made credit line
citation("RmetINIA")  # formal reference for the data bank and the software
```

Every result carries the credit line with it, so it survives being passed
around a script:

```r
x <- inia_daily("LE", "2024-01-01", "2024-01-31", vars = "precip")
attr(x, "attribution")
#> "Fuente: Banco de Datos Agroclimaticos, Unidad GRAS, Instituto Nacional de
#>  Investigacion Agropecuaria (INIA), Uruguay. https://www.inia.uy/gras/...
#>  (consultado el 2026-08-11)"
```

`inia_write_csv()` writes that line into the exported file as a leading comment,
so the credit travels with the data when the file is shared onward.

Historical open data for rainfall and extreme temperatures at five of the
stations is also published on the national open data portal:
`inia_browse("opendata")`.

---

## Stations

| `est` | code | station | slug | data from |
|---|---|---|---|---|
| 1 | LB | INIA Las Brujas | `las_brujas` | 1972-07-01 |
| 2 | LE | INIA La Estanzuela | `la_estanzuela` | 1965-07-01 |
| 3 | TA-LM | INIA Tacuarembó – La Magnolia | `la_magnolia` | 1978-02-01 |
| 4 | TT-PL | INIA Treinta y Tres – Paso de la Laguna | `paso_de_la_laguna` | 1971-01-01 |
| 5 | SG | INIA Salto Grande | `salto_grande` | 1970-07-01 |
| 6 | TA-GL | INIA Tacuarembó – Glencoe | `glencoe` | 2016-11-01 |

You never have to remember which number is which. **Every one of these
resolves to station 2:**

```r
inia_daily(2, ...)
inia_daily("LE", ...)
inia_daily("la_estanzuela", ...)
inia_daily("INIA La Estanzuela", ...)
inia_daily("estanzuela", ...)          # any unambiguous fragment
inia_daily(inia_station$la_estanzuela, ...)
```

And getting it wrong prints the whole list rather than just failing:

```r
inia_station_id("montevideo")
#> Error: Station "montevideo" does not match any station.
#>
#> Pass an id, a code, a slug, or any part of the name:
#>   1   LB     INIA Las Brujas                          las_brujas
#>   2   LE     INIA La Estanzuela                       la_estanzuela
#>   3   TA-LM  INIA Tacuarembó - La Magnolia            la_magnolia
#>   4   TT-PL  INIA Treinta y Tres - Paso de la Laguna  paso_de_la_laguna
#>   5   SG     INIA Salto Grande                        salto_grande
#>   6   TA-GL  INIA Tacuarembó - Glencoe                glencoe
#>
#>   inia_stations()  for the same table as a data frame
```

---

## Variables

53 daily variables in five categories:

| category | n | examples |
|---|---|---|
| Air | 14 | `tmax`, `tmin`, `tmean`, `rh_mean`, `wind_run`, `frost_met` |
| Cold and heat indices | 12 | `gdd_10_0`, `chill_units_richardson`, `thermal_units_rice` |
| Rain and evaporation | 6 | `precip`, `precip_effective`, `et0_penman`, `evap_pan_a` |
| Solar radiation | 3 | `sunshine_hours`, `sunshine_relative`, `solar_radiation` |
| Soil | 18 | `soil_cov_5cm_mean`, `soil_bare_20cm_max`, … |

Same flexibility as for stations — **all of these mean precipitation:**

```r
vars = "precip"
vars = 51
vars = "Precip. Acumulada (mm)"           # the server's own Spanish label
vars = "Precipitation, accumulated"
vars = inia_var$precip
```

Category shortcuts pull a whole group at once:

```r
vars = "common"      # the default: tmax, tmin, tmean_minmax, precip,
                     # rh_mean, wind_run, solar_radiation
vars = "all"         # all 53
vars = "air"         # or "rain", "radiation", "indices", "soil"
```

### Finding a variable

```r
inia_variables()                       # all 53, with units and definitions
inia_variables("humidity")             # search, case- and accent-insensitive
inia_variables("helada")               # Spanish works too
inia_variables(category = "soil")      # one category
inia_var$<Tab>                         # autocomplete all 53 keys
grep("^gdd", names(inia_var), value = TRUE)   # every degree-day base
```

A near miss suggests the closest keys:

```r
inia_var_id("temperatur")
#> Error: Variable "temperatur" is ambiguous: it matches 25 variables
#>   (tmax, tmin, tmean, tmean_minmax, tmin_grass, t_range, tmin_below_15,
#>    soil_cov_5cm_max, and 17 more).
#>   Narrow it down with inia_variables("temperatur")
```

---

## Usage

### Daily data

```r
library(RmetINIA)

# One station, one month, three variables
inia_daily("LE", "2024-01-01", "2024-01-31",
           vars = c("precip", "tmax", "tmin"))

# The ids straight out of a URL you copied from the web form
inia_daily(2, "2024-01-01", "2024-01-31", vars = c(60, 86, 71, 65, 51))

# Dates are optional — they default to the station's full period of record
le <- inia_daily("LE", vars = "precip")
range(le$date)
#> [1] "1965-07-01" "2026-08-11"

# Several stations at once, in long form, ready for ggplot2
inia_daily(c("LE", "LB", "SG"), "2023-01-01", "2023-12-31",
           vars = c("tmax", "tmin"), long = TRUE)

# Keep the server's original Spanish column headers
inia_daily("LE", "2024-01-01", "2024-01-05", vars = "precip",
           tidy_names = FALSE)
```

### Summary statistics

INIA's own statistical report for a single variable — count, mean, sd, min,
five percentiles, max and sum, broken down by year, by month **and** by ten-day
period, all in one call:

```r
s <- inia_stats("LE", "precip", "2000-01-01", "2020-12-31")

subset(s, period_type == "year")     # 21 rows
subset(s, period_type == "month")    # 12 rows
subset(s, period_type == "decade")   # 36 rows

# Custom percentiles, and a cut-off that excludes trace rainfall
inia_stats("LE", "precip", "2000-01-01", "2020-12-31",
           percentiles = c(10, 25, 50, 75, 90), min = 0.1)
```

### Exporting

```r
x <- inia_daily("LE", "2024-01-01", "2024-12-31", vars = "all")

inia_write_csv(x, "estanzuela_2024.csv")               # UTF-8 + BOM, "." decimals
inia_write_csv(x, "estanzuela_2024.csv", sep = ";")    # for Excel on es/pt locales
```

INIA's own note on this: Excel does not use standard CSV, so a plain export may
need Data ▸ Get Data ▸ From File ▸ From Text/CSV to import cleanly.
`inia_write_csv()` writes a UTF-8 byte order mark so Excel detects the encoding
of the accented Spanish headers on a double-click, and always uses `.` as the
decimal separator. LibreOffice/OpenOffice handle either file directly.

---

## Missing data

Two different kinds of absence come back from this service, and conflating them
is the easiest way to get a wrong answer:

**A variable with no data at all** in the window is *dropped from the response
entirely* by the server. The package warns and records it, rather than letting a
column disappear unnoticed:

```r
x <- inia_daily("glencoe", "2017-01-01", "2017-01-05",
                vars = c("evap_piche", "precip"))
#> Warning: No data in this period for: Evaporación Piché (mm).
#>   These variables were dropped by the server and are absent from the result.

attr(x, "empty_variables")
#> [1] "Evaporación Piché (mm)"
```

This warning is **not** silenced by `quiet = TRUE`; `quiet` only suppresses
progress messages.

**A variable with gaps** comes back with blank fields, which become `NA`:

```r
inia_daily("LE", "2024-07-01", "2024-07-10",
           vars = c("gdd_4_5", "tmean_minmax"))
#>         date gdd_4_5 tmean_minmax
#> 5 2024-07-05      NA          5.1   # mean below the 4.5 °C base
```

Not every variable is measured at every station, and none over the full record
everywhere. Check the period of record with `inia_stations()`, and the live
end date with `inia_stations(refresh = TRUE)`.

---

## What comes back

`inia_daily()` returns a data frame of `station_id`, `station`, `date` and one
column per variable, plus attributes:

| attribute | contents |
|---|---|
| `attribution` | the credit line INIA's terms require |
| `station_info` | station id, code, name and the dates actually requested |
| `variables` | catalogue rows for the variables returned |
| `definitions` | **INIA's own definition of each variable**, as served |
| `empty_variables` | variables dropped for having no data |
| `query` | the exact URLs used, for reproducibility |

```r
attr(x, "definitions")
#>                    label                                          definition
#> 1 Precip. Acumulada (mm) Precipitación acumulada diaria, medida convencion...
```

---

## Discovery, in one place

```r
inia_cheatsheet()             # stations, categories, examples, terms — one screen
inia_stations()               # the six stations
inia_variables("rain")        # search the 53 variables
inia_station$<Tab>            # autocomplete station ids
inia_var$<Tab>                # autocomplete variable ids
inia_station_id("brujas")     # resolve anything to an id
inia_var_id("soil")           # ... including whole categories
inia_browse()                 # open the official page
```

---

## Notes on the service

- The endpoint is `ver_exporta_datos_consulta/?est=&f_ini=&f_fin=&vars=`, with
  `vars` a `-`-separated list of ids. Statistics use
  `ver_estadisticas_consulta_web/`.
- Requests must be made over **HTTP/1.1**; the host answers HTTP/2 requests with
  a Cloudflare interstitial. The package forces this, and sends an honest
  self-identifying User-Agent (libcurl's default is also rejected). Requests are
  throttled to one per second to be a polite client of a free public service.
- The server returns columns in ascending variable-id order regardless of the
  order requested; the package reorders them to match your `vars` argument.
- Invalid queries are answered with **HTTP 200 and an HTML page**, not an error
  status. The package detects this and raises a readable error. Requests wholly
  outside a station's period of record return HTTP 500, so dates are validated
  and clamped client-side before anything is sent.

## Options

| option | default | effect |
|---|---|---|
| `RmetINIA.quiet` | `FALSE` | silence startup and attribution messages |
| `RmetINIA.rate` | `1` | requests per second |
| `RmetINIA.base_url` | GRAS endpoint | override the service root |
| `RmetINIA.user_agent` | `RmetINIA/<version>` | override the User-Agent |

## Development

```r
devtools::document()    # rebuild NAMESPACE and man/
devtools::test()        # offline tests: parsers, resolvers, catalogues
devtools::check()

# Tests that hit the real service are opt-in
Sys.setenv(RMETINIA_LIVE_TESTS = "true"); devtools::test()
```

## Licence

MIT for the R source code — see `LICENSE`.

The **data is not MIT licensed**. It belongs to INIA and reaches you under the
GRAS terms of use summarised above and reproduced in full by `inia_terms()`.
The station and variable catalogue embedded in this package is reproduced from
the GRAS query form for interoperability, unmodified and attributed; no
observations are shipped with the package.
