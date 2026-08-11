test_that("the export format parses into typed columns", {
  p <- .parse_export(fixture_export())

  expect_equal(p$station$name, "INIA La Estanzuela")
  expect_equal(p$station$code, "LE")
  expect_s3_class(p$data$date, "Date")
  expect_equal(nrow(p$data), 3L)
  expect_type(p$data[[2]], "double")
  expect_equal(p$data[[2]], c(1.1, 0.0, NA))   # blank field -> NA
})

test_that("trailer prose is never mistaken for data", {
  p <- .parse_export(fixture_export())
  expect_equal(max(p$data$date), as.Date("2024-01-03"))
  expect_equal(ncol(p$data), 3L)
})

test_that("INIA's own variable definitions are extracted", {
  p <- .parse_export(fixture_export())
  expect_equal(nrow(p$definitions), 2L)
  expect_true(any(grepl("Precipitaci", p$definitions$definition)))
  # A quoted definition containing a comma stays one field
  d <- p$definitions$definition[p$definitions$label == "Precip. Acumulada (mm)"]
  expect_true(grepl("medida convencionalmente", d))
})

test_that("variables the server dropped are reported", {
  p <- .parse_export(fixture_export_empty_var())
  expect_equal(p$empty_variables, "Evaporación Piché (mm)")
  expect_equal(names(p$data)[-1], "Precip. Acumulada (mm)")
})

test_that("a response with no Fecha header is an error, not a bad parse", {
  expect_error(.parse_export("something else entirely"), "no 'Fecha' header")
})

test_that("the statistics report splits into its three period types", {
  s <- .parse_stats(fixture_stats(), c(5, 25, 50, 75, 95))

  expect_equal(nrow(s), 4L)
  expect_equal(unique(s$period_type), c("year", "month", "decade"))
  expect_true(all(c("p5", "p50", "p95", "sum") %in% names(s)))
  expect_type(s$mean, "double")
  expect_equal(s$sum[s$period == "2000"], 1300)
  # Header rows of the second and third blocks must not become data
  expect_false(any(s$period %in% c("Mes", "Década", "Año")))
})

test_that("percentile columns follow the requested percentiles", {
  s <- .parse_stats(fixture_stats(), c(10, 20, 50, 80, 90))
  expect_true(all(c("p10", "p20", "p80", "p90") %in% names(s)))
})

test_that("station header parsing tolerates a missing code", {
  expect_equal(.parse_station_header("INIA Somewhere")$name, "INIA Somewhere")
  expect_true(is.na(.parse_station_header("INIA Somewhere")$code))
})
