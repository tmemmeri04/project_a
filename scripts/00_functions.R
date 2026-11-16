# User-defined skewness: sum((x - mean(x))^3) / ((n - 1) * sd(x)^3).
# Retained intentionally; this is not adjusted Fisher-Pearson skewness.
skewness <- function(vec, na.rm = TRUE) {
  if (na.rm) {
    vec <- vec[!is.na(vec)]
  }

  if (length(vec) < 2 || is.na(sd(vec)) || sd(vec) == 0) {
    return(NA_real_)
  }
  mean_vec <- mean(vec)
  sd_vec <- sd(vec)
  skew <- (sum((vec-mean_vec)^3))/((length(vec)-1)*sd_vec^3)

  return(skew)
}

# Write plain CSV even when replacing an older gzip-compressed file.
write_plain_csv <- function(table, path) {
  dir.create(dirname(path), recursive = TRUE, showWarnings = FALSE)
  connection <- file(path, open = "wb")
  on.exit(close(connection))
  readr::write_csv(table, connection)
}

export_table <- function(table, name, caption, digits = 5, format_args = list(),
                         significant_digits = NULL) {
  table_path <- file.path("outputs", "tables", name)
  write_plain_csv(table, paste0(table_path, ".csv"))
  latex_data <- table
  if (!is.null(significant_digits)) {
    # Choose decimal/scientific notation per value; retain significant zeros.
    numeric_columns <- vapply(latex_data, is.numeric, logical(1))
    latex_data[numeric_columns] <- lapply(latex_data[numeric_columns], function(values) {
      trimws(formatC(values, format = "g", digits = significant_digits, flag = "#"))
    })
  }
  latex_table <- knitr::kable(
    latex_data, format = "latex", row.names = FALSE, digits = digits,
    caption = caption, format.args = format_args
  )
  writeLines(as.character(latex_table), paste0(table_path, ".tex"))
}

export_plot <- function(plot, name, width = 14, height = 9) {
  dir.create(file.path("outputs", "figures"), recursive = TRUE, showWarnings = FALSE)
  for (extension in c("png", "pdf")) {
    ggplot2::ggsave(
      file.path("outputs", "figures", paste0(name, ".", extension)),
      plot = plot, width = width, height = height, dpi = 160, bg = "white"
    )
  }
  if (interactive()) print(plot)
}
