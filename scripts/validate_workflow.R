# Run from the project root: Rscript --vanilla scripts/validate_workflow.R
# Rebuilds outputs and checks the current source snapshot without changing raw data.
raw_path <- "data/raw/Harbor_Water_Quality_20260929.csv"
raw_hash_before <- tools::md5sum(raw_path)
runtime_warnings <- character()
workflow_log <- withCallingHandlers(
  capture.output(source("scripts/000_runtime.R")),
  warning = function(w) {
    runtime_warnings <<- c(runtime_warnings, conditionMessage(w))
    invokeRestart("muffleWarning")
  }
)
writeLines(workflow_log, "outputs/tables/workflow_validation_log.txt")

check <- function(condition, description) {
  if (!isTRUE(condition)) stop("FAIL: ", description)
  cat("PASS:", description, "\n")
}
same <- function(x, y) isTRUE(all.equal(x, y, tolerance = 1e-12, check.attributes = FALSE))
keys <- c("Sampling.Location", "Measurement", "Season")

# All active and optional R scripts must parse, including the archived references.
script_paths <- list.files("scripts", pattern = "\\.[Rr]$", recursive = TRUE, full.names = TRUE)
invisible(lapply(script_paths, parse))
check(identical(raw_hash_before, tools::md5sum(raw_path)), "raw source checksum unchanged")
check(nrow(new_fulldata) == 2224L && nrow(long_data) == 8895L,
      "filtered and retained-long row counts")
check(!anyNA(long_data$Sample.Date) && sum(is.na(long_data$Dissolved_Oxygen)) == 2424L &&
      sum(!is.na(long_data$Dissolved_Oxygen)) == 6471L &&
      sum(long_data$Dissolved_Oxygen == 0, na.rm = TRUE) == 41L &&
      !any(long_data$Dissolved_Oxygen < 0, na.rm = TRUE) &&
      nrow(invalid_oxygen_readings) == 1L, "dates, missing values, zeros and negative exclusion")
check(sum(new_fulldata$Season == "Summer", na.rm = TRUE) == 1090L &&
      sum(new_fulldata$Season == "Winter", na.rm = TRUE) == 156L &&
      sum(is.na(new_fulldata$Season)) == 978L, "season membership counts")

# Verify selection against the raw source, then reconstruct the long readings.
selected <- fulldata$Sampling.Location %in% c("NC1", "NC2", "NC3")
raw_columns <- c(
  Dissolved_Oxygen_CTD_top = DO_CTD_top_h,
  Dissolved_Oxygen_CTD_bottom = DO_CTD_bottom_h,
  Dissolved_Oxygen_winkler_top = DO_winkler_top_h,
  Dissolved_Oxygen_winkler_bottom = DO_winkler_bottom_h
)
filtered <- readr::read_csv("data/processed/filtered_data.csv",
  col_types = readr::cols(Sample.Date = readr::col_date(), Sample.Time = readr::col_character()))
check(same(filtered$Sampling.Location, fulldata$Sampling.Location[selected]) &&
      same(filtered$Sample.Date, fulldata$Sample.Date[selected]), "site and date traceability to raw records")
for (measurement in names(raw_columns)) {
  check(same(as.numeric(filtered[[measurement]]), as.numeric(fulldata[[raw_columns[[measurement]]]][selected])),
        paste("raw-value traceability", measurement))
}
reconstructed_long <- filtered |>
  mutate(Sample.Time.raw = Sample.Time,
         Sample.Time = suppressWarnings(readr::parse_time(Sample.Time))) |>
  tidyr::pivot_longer(cols = starts_with("Dissolved_Oxygen"),
                     names_to = "Measurement", values_to = "Dissolved_Oxygen") |>
  filter(is.na(Dissolved_Oxygen) | Dissolved_Oxygen >= 0)
check(same(as.data.frame(reconstructed_long[names(long_data)]), as.data.frame(long_data)),
      "all retained long rows reconstruct from the source selection")
check(nrow(summarized_data) == 24L && nrow(condensed_summary) == 8L &&
      nrow(year_specific_summary) == 4L &&
      all(summarized_data$total_rows == summarized_data$missing_rows + summarized_data$usable_rows) &&
      all(summarized_data$min <= summarized_data$mean & summarized_data$mean <= summarized_data$max),
      "summary dimensions, count identities and min/mean/max bounds")

readings_for <- function(row) {
  data <- long_data |> filter(Season == row$Season)
  if (row$Sampling.Location != "All sites") data <- data |> filter(Sampling.Location == row$Sampling.Location)
  if (startsWith(row$Measurement, "Combined")) {
    depth <- if (grepl("top", row$Measurement)) "top" else "bottom"
    data <- data |> filter(Measurement %in% c(paste0("Dissolved_Oxygen_CTD_", depth),
                                            paste0("Dissolved_Oxygen_winkler_", depth)))
  } else data <- data |> filter(Measurement == row$Measurement)
  data$Dissolved_Oxygen
}
for (table_name in c("seasonal_probabilities", "top_seasonal_probabilities", "bottom_seasonal_probabilities")) {
  result <- get(table_name)
  check(nrow(result) == if (table_name == "seasonal_probabilities") 24L else 20L,
        paste(table_name, "group count"))
  for (i in seq_len(nrow(result))) {
    row <- result[i, ]
    x <- readings_for(row)
    n <- sum(!is.na(x))
    failures <- sum(x <= 5, na.rm = TRUE)
    interval <- binom.test(failures, n, conf.level = 0.95)$conf.int
    stopifnot(length(x) == row$total_rows, n == row$nonmissing_rows,
      sum(is.na(x)) == row$missing_rows, failures == row$low_oxygen_rows,
      same(failures / n, row$simple_fraction), same(interval[1], row$fraction_CI_lower),
      same(interval[2], row$fraction_CI_upper),
      same(pnorm(5, mean(x, na.rm = TRUE), sd(x, na.rm = TRUE)), row$assumed_normal))
  }
  check(TRUE, paste(table_name, "all counts, fractions, normal estimates and 95% intervals"))
}

# Reconstruct matching independently from long data and preserve dates and seasons.
matched <- long_data |>
  mutate(Season = ifelse(is.na(Season), "Spring/Fall", Season)) |>
  group_by(Sample.Date, Measurement, Sampling.Location) |>
  arrange(Sample.Time, .by_group = TRUE) |>
  mutate(sample_round = row_number()) |>
  ungroup() |>
  tidyr::pivot_wider(id_cols = c(Measurement, Sample.Date, sample_round, Season),
                     names_from = Sampling.Location, values_from = Dissolved_Oxygen)
triples <- matched |> filter(!is.na(NC1), !is.na(NC2), !is.na(NC3))
event_keys <- c("Measurement", "Sample.Date", "sample_round")
check(!anyDuplicated(triples[event_keys]), "complete matched-event keys are unique")
expected_triples <- triples |> select(-Season) |> arrange(Measurement, Sample.Date, sample_round)
actual_triples <- simultaneous_measurements |> arrange(Measurement, Sample.Date, sample_round)
check(same(expected_triples[names(actual_triples)], actual_triples), "three-site matches reconstruct independently")
expected_counts <- c(506L, 508L, 562L, 570L)
for (i in seq_len(nrow(summarized_simultaneous_measurements))) {
  row <- summarized_simultaneous_measurements[i, ]
  data <- triples |> filter(Measurement == row$Measurement)
  failed_sites <- rowSums(as.matrix(data[c("NC1", "NC2", "NC3")]) <= 5)
  stopifnot(nrow(data) == expected_counts[i], nrow(data) == row$total_complete_measurements,
            same(mean(failed_sites == 3), row$all_three_fail),
            same(mean(failed_sites == 1), row$only_one_fails))
}
check(TRUE, "Question 2 event counts and joint probabilities")

method_labels <- c(Dissolved_Oxygen_CTD_top = "CTD top", Dissolved_Oxygen_CTD_bottom = "CTD bottom",
                  Dissolved_Oxygen_winkler_top = "Winkler top", Dissolved_Oxygen_winkler_bottom = "Winkler bottom")
check(nrow(t_test_mean_diff) == 12L && ncol(t_test_mean_diff) == 6L &&
      all(as.character(t_test_mean_diff$Season[10:12]) == "All year"), "Question 3 table layout")
for (pair in c("NC1-NC2", "NC2-NC3", "NC1-NC3")) {
  sites <- strsplit(pair, "-", fixed = TRUE)[[1]]
  for (season in c("Winter", "Summer", "Spring/Fall", "All year")) {
    for (measurement in names(method_labels)) {
      data <- matched |> filter(Measurement == measurement)
      if (season != "All year") data <- data |> filter(Season == season)
      complete <- !is.na(data[[sites[1]]]) & !is.na(data[[sites[2]]])
      differences <- data[[sites[1]]][complete] - data[[sites[2]]][complete]
      row <- t_test_mean_diff |> filter(Pair == pair, Season == season)
      stopifnot(length(differences) >= 2, is.finite(row[[method_labels[[measurement]]]]),
                same(signif(t.test(differences, mu = 0)$p.value, 3), row[[method_labels[[measurement]]]]))
    }
  }
}
check(TRUE, "all 48 paired p-values agree with independent one-sample difference tests")

for (measurement in names(method_labels)) {
  data <- triples |> filter(Measurement == measurement) |> arrange(Sample.Date)
  gaps <- as.numeric(diff(data$Sample.Date))
  stopifnot(all(gaps > 0))
  expected_rates <- lapply(data[c("NC1", "NC2", "NC3")], function(x) diff(x) / gaps)
  actual_rates <- daily_changes |> filter(Measurement == measurement) |> arrange(Sample.Date)
  for (site in c("NC1", "NC2", "NC3")) {
    stopifnot(sum(is.na(actual_rates[[paste0(site, "_change")]])) == 1L,
              same(expected_rates[[site]], actual_rates[[paste0(site, "_change")]][-1]))
  }
  row <- corr_coeff_btwn_sites |> filter(Measurement == measurement)
  for (pair in list(c("NC1", "NC2"), c("NC2", "NC3"), c("NC1", "NC3"))) {
    expected_r <- cor(expected_rates[[pair[1]]], expected_rates[[pair[2]]])
    stopifnot(same(expected_r, row[[paste(pair, collapse = "_")]]))
  }
}
check(TRUE, "Question 4 positive date gaps, interval rates and all 12 Pearson correlations")
check(nrow(ggplot_build(daily_change_regression_plot)$layout$layout) == 12L,
      "regression plot contains three pairs at four method/depth combinations")

for (depth in c("top", "bottom")) {
  diagnostic <- get(paste0(depth, "_distribution_diagnostics"))
  probability_table <- get(paste0(depth, "_seasonal_probabilities"))
  stopifnot(nrow(diagnostic$normality_results) == 20L, nrow(diagnostic$lognormality_results) == 20L,
            nrow(diagnostic$comparison) == 15L, all(diagnostic$comparison$minimum > 0))
  for (i in seq_len(20)) {
    x <- readings_for(probability_table[i, ])
    normal <- diagnostic$normality_results[i, ]
    logged <- diagnostic$lognormality_results[i, ]
    stopifnot(normal$usable_rows == sum(!is.na(x)), normal$zero_rows == sum(x == 0, na.rm = TRUE),
      logged$usable_rows == sum(x > 0, na.rm = TRUE),
      same(nortest::ad.test(x)$p.value, normal$p_value),
      same(nortest::ad.test(log(x[x > 0 & !is.na(x)]))$p.value, logged$p_value),
      normal$pass_fail == ifelse(normal$p_value > 0.05, "Pass", "Fail"),
      logged$pass_fail == ifelse(logged$p_value > 0.05, "Pass", "Fail"))
  }
  for (logged in c(FALSE, TRUE)) {
    plot <- if (logged) diagnostic$log_histograms else diagnostic$histograms
    built <- ggplot_build(plot)
    n <- if (logged) sum(diagnostic$lognormality_results$usable_rows) else sum(diagnostic$normality_results$usable_rows)
    stopifnot(nrow(built$layout$layout) == 20L, sum(built$data[[1]]$count) == n)
  }
  pooled <- diagnostic$grouped_data |>
    filter(Measurement == paste("Combined", depth, "methods"), !is.na(Dissolved_Oxygen))
  built <- ggplot_build(diagnostic$pooled_histograms)
  expected_counts <- pooled |> count(panel)
  for (i in seq_len(nrow(expected_counts))) {
    panel_id <- built$layout$layout$PANEL[
      as.character(built$layout$layout$panel) == as.character(expected_counts$panel[i])]
    stopifnot(sum(built$data[[1]]$count[built$data[[1]]$PANEL == panel_id]) == expected_counts$n[i])
  }
  stopifnot(nrow(built$layout$layout) == 8L)
  check(TRUE, paste(depth, "AD tests and histogram counts match probability group readings"))
}
check(nrow(normality_results) == 24L && nrow(lognormality_results) == 24L &&
      all(is.finite(normality_results$p_value)) && all(is.finite(lognormality_results$p_value)),
      "original 24-group AD diagnostics")
invisible(capture.output(source("scripts/06_compare_distribution_tests.R")))
check(nrow(distribution_test_comparison) == 20L && all(distribution_test_comparison$minimum > 0),
      "optional script 06 zero-free comparison")

table_names <- c("daily_change_correlations", "summarized_data", "condensed_summary", "year_specific_summary_2025",
  "data_quality_summary", "invalid_oxygen_readings", "unavailable_sample_times",
  "seasonal_probabilities", "joint_probabilities", "paired_site_t_tests",
  "top_seasonal_probabilities", "bottom_seasonal_probabilities",
  "top_normality_results", "top_lognormality_results", "top_distribution_test_comparison",
  "bottom_normality_results", "bottom_lognormality_results", "bottom_distribution_test_comparison")
figure_names <- c("seasonal_histograms", "seasonal_normal_qq", "seasonal_positive_log_histograms",
  "seasonal_positive_log_qq", "exploratory_oxygen_over_time", "exploratory_nc1_winkler_top",
  "exploratory_nc1_winkler_top_after_2010", "seasonal_probabilities", "top_seasonal_probabilities",
  "bottom_seasonal_probabilities", "daily_change_regressions",
  "all_sites_combined_histograms", "joint_probabilities",
  "top_combined_methods_histograms", "bottom_combined_methods_histograms", "top_grouped_histograms",
  "top_grouped_positive_log_histograms", "bottom_grouped_histograms", "bottom_grouped_positive_log_histograms")
for (name in table_names) {
  paths <- file.path("outputs", "tables", paste0(name, c(".csv", ".tex")))
  stopifnot(all(file.exists(paths)), all(file.info(paths)$size > 0))
  object_name <- switch(name, joint_probabilities = "summarized_simultaneous_measurements",
                        paired_site_t_tests = "t_test_mean_diff", year_specific_summary_2025 = "year_specific_summary", name)
  expected <- as.data.frame(get(object_name))
  # CSV stores dates/times/factors as text. Preserve text that looks numeric.
  column_types <- vapply(expected, function(column) {
    if (is.numeric(column) && !inherits(column, c("Date", "difftime"))) "numeric" else "character"
  }, character(1))
  for (column in names(expected)[column_types == "character"]) {
    expected[[column]] <- as.character(expected[[column]])
  }
  csv <- read.csv(paths[1], colClasses = column_types)
  check(same(csv, expected), paste("CSV round trip", name))
  stopifnot(any(grepl("\\begin{tabular}", readLines(paths[2]), fixed = TRUE)))
}
saved_matches <- readr::read_csv("outputs/tables/matched_observations_date_order.csv",
  col_types = readr::cols(Sample.Date = readr::col_date()))
check(same(saved_matches, simultaneous_measurements), "matched-observation CSV round trip")
for (name in figure_names) {
  png <- file.path("outputs", "figures", paste0(name, ".png"))
  pdf <- file.path("outputs", "figures", paste0(name, ".pdf"))
  stopifnot(file.info(png)$size > 0, file.info(pdf)$size > 0,
    identical(readBin(png, "raw", 8), as.raw(c(137, 80, 78, 71, 13, 10, 26, 10))),
    rawToChar(readBin(pdf, "raw", 5)) == "%PDF-")
}
for (name in c("filtered_data.csv", "long_data.csv", "summarized_data.csv")) {
  header <- readBin(file.path("data", "processed", name), "raw", 2)
  stopifnot(!identical(header, as.raw(c(31, 139))))
}
four_panel_build <- ggplot_build(all_sites_combined_histograms)
stopifnot(nrow(four_panel_build$layout$layout) == 4L)
for (i in seq_len(nrow(all_sites_histogram_counts))) {
  panel_id <- four_panel_build$layout$layout$PANEL[
    as.character(four_panel_build$layout$layout$panel) == as.character(all_sites_histogram_counts$panel[i])]
  stopifnot(sum(four_panel_build$data[[1]]$count[
    four_panel_build$data[[1]]$PANEL == panel_id]) == all_sites_histogram_counts$sample_size[i])
}
for (i in seq_len(nrow(joint_probability_plot_data))) {
  row <- joint_probability_plot_data[i, ]
  events <- simultaneous_measurements |> filter(Measurement == row$Measurement)
  failures <- (events$NC1 <= 5) + (events$NC2 <= 5) + (events$NC3 <= 5)
  expected_count <- if (as.integer(row$Event) == 1L) sum(failures == 3) else sum(failures == 1)
  expected_interval <- binom.test(expected_count, nrow(events))$conf.int
  stopifnot(row$event_count == expected_count,
    same(row$probability, expected_count / nrow(events)),
    same(c(row$lower, row$upper), as.numeric(expected_interval)))
}
stopifnot(nrow(joint_probability_plot_data) == 8L,
  nrow(ggplot_build(joint_probability_plot)$layout$layout) == 2L)
check(TRUE, "18 CSV/LaTeX table pairs, 19 PNG/PDF figure pairs and plain processed CSV files")
cat("\nRuntime warnings:\n")
if (length(runtime_warnings)) cat(paste(unique(runtime_warnings), collapse = "\n"), "\n") else cat("None\n")
cat("\nR:", R.version.string, "\n")
cat("Package versions:\n")
print(vapply(required_packages, function(package) as.character(packageVersion(package)), character(1)))
cat("\nAll workflow validation checks passed. Statistical limitations remain as documented.\n")
