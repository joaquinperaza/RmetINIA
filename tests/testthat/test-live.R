# Tests that hit the real INIA GRAS service. Skipped unless
# RMETINIA_LIVE_TESTS=true, so a routine `R CMD check` never depends on a free
# public server being reachable, nor adds load to it.

test_that("a daily query returns the requested variables in order", {
  skip_if_offline_inia()

  x <- inia_daily(2, "2024-01-01", "2024-01-10",
                  vars = c(60, 86, 71, 65, 51), quiet = TRUE)

  expect_s3_class(x, "inia_data")
  expect_equal(nrow(x), 10L)
  expect_equal(names(x),
               c("station_id", "station", "date",
                 "tmean_minmax", "solar_radiation", "rh_mean",
                 "wind_run", "precip"))
  expect_equal(unique(x$station), "LE")
  expect_s3_class(x$date, "Date")
  expect_true(all(vapply(x[-(1:3)], is.numeric, logical(1))))
  expect_match(attr(x, "attribution"), "INIA")
})

test_that("station and variable spellings are interchangeable", {
  skip_if_offline_inia()

  a <- inia_daily(2, "2024-01-01", "2024-01-05", vars = 51, quiet = TRUE)
  b <- inia_daily("LE", "2024-01-01", "2024-01-05", vars = "precip", quiet = TRUE)
  d <- inia_daily("estanzuela", "2024-01-01", "2024-01-05",
                  vars = "Precip. Acumulada (mm)", quiet = TRUE)

  expect_equal(as.data.frame(a), as.data.frame(b))
  expect_equal(as.data.frame(a), as.data.frame(d))
})

test_that("several stations stack, and long form pivots", {
  skip_if_offline_inia()

  x <- inia_daily(c("LE", "LB"), "2024-03-01", "2024-03-03",
                  vars = c("tmax", "tmin"), quiet = TRUE)
  expect_equal(nrow(x), 6L)
  expect_setequal(unique(x$station_id), c(1L, 2L))

  l <- inia_daily(c("LE", "LB"), "2024-03-01", "2024-03-03",
                  vars = c("tmax", "tmin"), long = TRUE, quiet = TRUE)
  expect_equal(nrow(l), 12L)
  expect_setequal(names(l),
                  c("station_id", "station", "date", "variable", "value", "unit"))
  expect_setequal(unique(l$unit), "degC")
})

test_that("variables with no data in the window are reported, not dropped silently", {
  skip_if_offline_inia()

  expect_warning(
    x <- inia_daily("glencoe", "2017-01-01", "2017-01-05",
                    vars = c("evap_piche", "precip"), quiet = TRUE),
    "No data in this period"
  )
  expect_false("evap_piche" %in% names(x))
  expect_true("precip" %in% names(x))
  expect_length(attr(x, "empty_variables"), 1L)
})

test_that("gaps within a series become NA", {
  skip_if_offline_inia()

  x <- inia_daily("LE", "2024-07-01", "2024-07-10",
                  vars = c("gdd_4_5", "tmean_minmax"), quiet = TRUE)
  expect_true(anyNA(x$gdd_4_5))
  expect_false(anyNA(x$tmean_minmax))
})

test_that("dates outside the period of record are clamped, not sent", {
  skip_if_offline_inia()

  x <- inia_daily("glencoe", "1990-01-01", "2016-11-05",
                  vars = "precip", quiet = TRUE)
  expect_equal(min(x$date), as.Date("2016-11-01"))
})

test_that("statistics come back in three period types", {
  skip_if_offline_inia()

  s <- inia_stats("LE", "precip", "2000-01-01", "2005-12-31", quiet = TRUE)
  expect_setequal(unique(s$period_type), c("year", "month", "decade"))
  expect_equal(sum(s$period_type == "year"), 6L)
  expect_equal(sum(s$period_type == "month"), 12L)
  expect_equal(sum(s$period_type == "decade"), 36L)
  expect_true(all(s$n > 0))
})

test_that("the live catalogues still match the embedded ones", {
  skip_if_offline_inia()

  live_st <- inia_stations(refresh = TRUE)
  expect_setequal(live_st$id, inia_stations()$id)
  expect_setequal(live_st$name, inia_stations()$name)
  expect_true(all(!is.na(as.Date(live_st$last_date))))

  skip_if_not_installed("rvest")
  live_v <- inia_variables(refresh = TRUE)
  expect_setequal(live_v$id, inia_variables()$id)
  expect_setequal(live_v$label, inia_variables()$label)
})

test_that("a rejected query produces a readable error, not a bad parse", {
  skip_if_offline_inia()

  # est=99 is not a station; the server answers 200 OK with an HTML page.
  expect_error(
    .inia_get("/ver_exporta_datos_consulta/",
              list(est = 99, f_ini = "2024-01-01", f_fin = "2024-01-03",
                   vars = 51)),
    "HTML page instead of data"
  )
})
