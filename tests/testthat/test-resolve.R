test_that("stations resolve from every accepted form", {
  expect_equal(inia_station_id(2), 2L)
  expect_equal(inia_station_id("2"), 2L)
  expect_equal(inia_station_id("LE"), 2L)
  expect_equal(inia_station_id("le"), 2L)
  expect_equal(inia_station_id("la_estanzuela"), 2L)
  expect_equal(inia_station_id("INIA La Estanzuela"), 2L)
  expect_equal(inia_station_id("estanzuela"), 2L)
  # The labelled form the editor completion offers
  expect_equal(inia_station_id("2 = INIA La Estanzuela (LE)"), 2L)
})

test_that("station matching ignores accents and normalisation form", {
  # The GRAS pages mix both Unicode forms of the same name, so both must match.
  nfc <- "INIA Tacuaremb\u00f3 - Glencoe"     # precomposed U+00F3
  nfd <- "INIA Tacuarembo\u0301 - Glencoe"    # o + combining acute U+0301
  expect_false(identical(nfc, nfd))
  expect_equal(inia_station_id(nfc), 6L)
  expect_equal(inia_station_id(nfd), 6L)
  expect_equal(inia_station_id("tacuarembo - glencoe"), 6L)
})

test_that("stations resolve as a vector", {
  expect_equal(inia_station_id(c("LE", "Las Brujas", 5)), c(2L, 1L, 5L))
})

test_that("unresolvable stations error with the list of valid ones", {
  expect_error(inia_station_id("montevideo"), "does not match any station")
  expect_error(inia_station_id("montevideo"), "INIA La Estanzuela")
  expect_error(inia_station_id(99), "not a station id")
  expect_error(inia_station_id("tacuarembo"), "ambiguous")
})

test_that("variables resolve from every accepted form", {
  expect_equal(inia_var_id("precip"), 51L)
  expect_equal(inia_var_id(51), 51L)
  expect_equal(inia_var_id("Precip. Acumulada (mm)"), 51L)
  expect_equal(inia_var_id("Precipitation, accumulated"), 51L)
  expect_equal(inia_var_id(c("tmax", "tmin")), c(58L, 59L))
})

test_that("category shortcuts expand", {
  expect_equal(sort(inia_var_id("radiation")), c(1L, 84L, 86L))
  expect_length(inia_var_id("all"), 53L)
  expect_length(inia_var_id("soil"), 18L)
  expect_length(inia_var_id("common"), 7L)
})

test_that("variable ids are de-duplicated but keep first-seen order", {
  expect_equal(inia_var_id(c("precip", 51, "precip")), 51L)
  expect_equal(inia_var_id(c("tmax", "precip", "tmax")), c(58L, 51L))
})

test_that("unresolvable variables error helpfully", {
  expect_error(inia_var_id("zzzz"), "does not match any variable")
  expect_error(inia_var_id("zzzz"), "Did you mean")
  expect_error(inia_var_id(9999), "not a known variable id")
  expect_error(inia_var_id("temperature"), "ambiguous")
})

test_that("normalisation helper folds case, accents and punctuation", {
  expect_equal(.norm("Precip. Acumulada (mm)"), "precipacumuladamm")
  expect_equal(.norm("Heliofanía"), .norm("Heliofanía"))
  expect_equal(.norm("HELIOFANIA"), .norm("heliofanía"))
})

test_that("padding is display-width aware", {
  expect_equal(nchar(.pad("abc", 6), type = "width"), 6L)
  expect_equal(nchar(.pad("Tacuarembó", 12), type = "width"), 12L)
})
