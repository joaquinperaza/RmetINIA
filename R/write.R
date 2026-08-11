#' Write INIA data to a CSV that Excel opens cleanly
#'
#' INIA's own guidance on the data bank page notes that files use the standard
#' CSV conventions — a `.` decimal separator and UTF-8 text — which Microsoft
#' Excel does not always honour on a locale that expects `,`. This writes a file
#' that opens correctly by double-click on any locale: UTF-8 with a byte order
#' mark so Excel detects the encoding, `.` for decimals, and a separator you
#' choose.
#'
#' The required source attribution is written as a comment line at the top by
#' default, so the credit does not get lost when the file is shared onward.
#'
#' @param x A data frame, typically from [inia_daily()] or [inia_stats()].
#' @param file Path to write to.
#' @param sep Field separator. `","` (default) is the CSV standard; `";"` is
#'   what Excel expects on locales that use `,` as the decimal mark.
#' @param attribution If `TRUE` (default), prepend the INIA source credit as a
#'   leading comment line.
#' @param bom If `TRUE` (default), write a UTF-8 byte order mark so Excel
#'   detects the encoding of the accented Spanish headers.
#' @return `file`, invisibly.
#' @seealso [inia_daily()], [inia_attribution()]
#' @export
#' @examples
#' \dontrun{
#' x <- inia_daily("LE", "2024-01-01", "2024-01-31", vars = "precip")
#' inia_write_csv(x, "estanzuela_2024.csv")
#'
#' # For Excel on a Spanish/Portuguese locale
#' inia_write_csv(x, "estanzuela_2024.csv", sep = ";")
#' }
inia_write_csv <- function(x, file, sep = ",", attribution = TRUE, bom = TRUE) {
  stopifnot(is.data.frame(x), is.character(file), length(file) == 1)

  con <- file(file, open = "wb")
  on.exit(close(con), add = TRUE)

  if (bom) writeBin(as.raw(c(0xEF, 0xBB, 0xBF)), con)

  txt <- character()
  if (attribution) {
    credit <- attr(x, "attribution") %||% inia_attribution()
    txt <- c(txt, paste0("# ", credit))
  }

  body <- utils::capture.output(
    utils::write.table(as.data.frame(x), sep = sep, dec = ".",
                       row.names = FALSE, qmethod = "double",
                       fileEncoding = "", quote = TRUE)
  )
  writeLines(enc2utf8(c(txt, body)), con, useBytes = TRUE)
  invisible(file)
}
