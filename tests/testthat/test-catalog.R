test_that("the station catalogue is well formed", {
  st <- inia_stations()
  expect_equal(nrow(st), 6L)
  expect_false(any(duplicated(st$id)))
  expect_false(any(duplicated(st$slug)))
  expect_false(any(duplicated(st$code)))
  expect_false(anyNA(as.Date(st$first_date)))
})

test_that("the variable catalogue is well formed", {
  v <- inia_variables()
  expect_equal(nrow(v), 53L)
  expect_false(any(duplicated(v$id)))
  expect_false(any(duplicated(v$key)))
  expect_false(any(duplicated(v$label)))
  expect_true(all(nzchar(v$unit)))
  expect_true(all(nzchar(v$description)))
  # Keys must stay usable as R names, since they become column names
  expect_equal(v$key, make.names(v$key))
})

test_that("variable search matches English and Spanish, accents aside", {
  expect_true("rh_mean" %in% inia_variables("humidity")$key)
  expect_true("frost_agro" %in% inia_variables("helada")$key)
  expect_true("frost_agro" %in% inia_variables("HELADA")$key)
  expect_equal(nrow(inia_variables(category = "soil")), 18L)
})

test_that("an unknown category is rejected with the valid ones listed", {
  expect_error(inia_variables(category = "ocean"), "Unknown category")
  expect_error(inia_variables(category = "ocean"), "Soil")
})

test_that("every category shortcut maps onto real catalogue keys", {
  v <- inia_variables()
  for (nm in names(.var_shortcuts())) {
    expect_true(all(.var_shortcuts()[[nm]] %in% v$key), info = nm)
  }
})

test_that("completion objects agree with the catalogues", {
  expect_equal(sort(unlist(inia_station, use.names = FALSE)),
               sort(inia_stations()$id))
  expect_equal(sort(unlist(inia_var, use.names = FALSE)),
               sort(inia_variables()$id))
  expect_equal(inia_station$la_estanzuela, 2L)
  expect_equal(inia_var$precip, 51L)
  expect_equal(.DollarNames.inia_choices(inia_var, "^gdd"),
               grep("^gdd", names(inia_var), value = TRUE))
})

test_that("the labelled default of inia_daily(est=) resolves", {
  default <- eval(formals(inia_daily)$est)
  expect_length(default, 6L)
  expect_equal(sort(inia_station_id(default)), 1:6)
})
