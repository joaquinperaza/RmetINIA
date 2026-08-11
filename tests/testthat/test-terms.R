test_that("the attribution names INIA, GRAS and the source URL", {
  a <- inia_attribution()
  expect_match(a, "INIA")
  expect_match(a, "GRAS")
  expect_match(a, "inia.uy", fixed = TRUE)
  expect_match(a, "consultado")

  e <- inia_attribution("en")
  expect_match(e, "Source:")
  expect_match(e, "accessed")

  expect_false(grepl("consultado|accessed", inia_attribution(accessed = NULL)))
  expect_match(inia_attribution(accessed = as.Date("2020-01-02")), "2020-01-02")
})

test_that("the terms carry every numbered condition", {
  txt <- paste(capture.output(inia_terms()), collapse = "\n")
  for (i in 1:6) expect_match(txt, paste0(i, ")"), fixed = TRUE)
  expect_match(txt, "gratuito")          # 1) free access
  expect_match(txt, "no tendra responsabilidad")  # 2) no liability
  expect_match(txt, "fuente de la misma")         # 3) attribution
  expect_match(txt, "lucro comercial")            # 4) no commercial resale
  expect_match(txt, "emblemas y logos")           # 5) logos
  expect_match(txt, "recuadro ajeno")             # 6) no framing
})

test_that("inia_browse targets the official, unframed URLs", {
  expect_match(.inia_url("databank"), "^https://www\\.inia\\.uy/gras/")
  expect_match(.inia_url("query"), "^https://gras\\.inia\\.uy/")
  expect_match(.inia_url("opendata"), "catalogodatos\\.gub\\.uy")
})

test_that("inia_write_csv writes a BOM and the attribution comment", {
  path <- tempfile(fileext = ".csv")
  on.exit(unlink(path), add = TRUE)
  x <- data.frame(date = as.Date("2024-01-01"), precip = 1.5)
  inia_write_csv(x, path)

  raw <- readBin(path, "raw", 3)
  expect_equal(raw, as.raw(c(0xEF, 0xBB, 0xBF)))

  lines <- readLines(path, warn = FALSE, encoding = "UTF-8")
  expect_match(lines[1], "^﻿?# ")
  expect_match(lines[1], "INIA")
  expect_match(paste(lines, collapse = "\n"), "1.5", fixed = TRUE)

  # Decimals must stay dot-separated whatever the separator
  path2 <- tempfile(fileext = ".csv")
  on.exit(unlink(path2), add = TRUE)
  inia_write_csv(x, path2, sep = ";", attribution = FALSE, bom = FALSE)
  l2 <- readLines(path2, warn = FALSE)
  expect_false(startsWith(l2[1], "#"))
  expect_match(l2[2], "1\\.5")
})
