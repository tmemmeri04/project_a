library(dplyr)
library(readr)

long_data_path <- file.path("data", "processed", "long_data.csv")
summarized_data_path <- file.path("data", "processed", "summarized_data.csv")
long_data <- read_csv(
  long_data_path,
  col_types = cols(Sample.Date = col_date(), Sample.Time = col_time(),
                   Sample.Time.raw = col_character())
)
stopifnot(!anyNA(long_data$Sample.Date))

# Script 02 has removed negative measurements; missing DO and zeros remain.
summarized_data <- long_data |>
  filter(Season %in% c("Summer", "Winter")) |>
  group_by(Sampling.Location, Measurement, Season) |>
  summarise(
    total_rows = n(),
    missing_rows = sum(is.na(Dissolved_Oxygen)),
    usable_rows = sum(!is.na(Dissolved_Oxygen)),
    zero_rows = sum(Dissolved_Oxygen == 0, na.rm = TRUE),
    mean = mean(Dissolved_Oxygen, na.rm = TRUE),
    sd = sd(Dissolved_Oxygen, na.rm = TRUE),
    skewness = skewness(Dissolved_Oxygen),
    min = if (usable_rows > 0) min(Dissolved_Oxygen, na.rm = TRUE) else NA_real_,
    max = if (usable_rows > 0) max(Dissolved_Oxygen, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  )

condensed_summary <- long_data |>
  filter(Season %in% c("Summer", "Winter")) |>
  group_by(Measurement, Season) |>
  summarise(
    total_rows = n(),
    missing_rows = sum(is.na(Dissolved_Oxygen)),
    usable_values = sum(!is.na(Dissolved_Oxygen)),
    zero_rows = sum(Dissolved_Oxygen == 0, na.rm = TRUE),
    mean = mean(Dissolved_Oxygen, na.rm = TRUE),
    sd = sd(Dissolved_Oxygen, na.rm = TRUE),
    min = if (usable_values > 0) min(Dissolved_Oxygen, na.rm = TRUE) else NA_real_,
    max = if (usable_values > 0) max(Dissolved_Oxygen, na.rm = TRUE) else NA_real_,
    .groups = "drop"
  )

year_specific_summary <- long_data |>
  filter(Season %in% c("Summer", "Winter"), format(Sample.Date, "%Y") == "2025",
         !Measurement %in% c("Dissolved_Oxygen_CTD_bottom", "Dissolved_Oxygen_winkler_bottom")) |>
  group_by(Measurement, Season) |>
  summarise(
    total_rows = n(),
    missing_rows = sum(is.na(Dissolved_Oxygen)),
    usable_values = sum(!is.na(Dissolved_Oxygen)),
    zero_rows = sum(Dissolved_Oxygen == 0, na.rm = TRUE),
    mean = mean(Dissolved_Oxygen, na.rm = TRUE),
    sd = sd(Dissolved_Oxygen, na.rm = TRUE),
    .groups = "drop"
  )

# Quality counts for retained analysis rows, including spring/fall observations.
# The separate exclusion log was created before filtering in script 02.
data_quality_summary <- long_data |>
  group_by(Sampling.Location, Measurement) |>
  summarise(
    total_rows = n(),
    missing_rows = sum(is.na(Dissolved_Oxygen)),
    usable_rows = sum(!is.na(Dissolved_Oxygen)),
    zero_rows = sum(Dissolved_Oxygen == 0, na.rm = TRUE),
    unavailable_time_rows = sum(is.na(Sample.Time)),
    .groups = "drop"
  )
unavailable_sample_times <- long_data |>
  filter(is.na(Sample.Time)) |>
  distinct(Sampling.Location, Sample.Date, Sample.Time.raw)

write_plain_csv(summarized_data, summarized_data_path)
export_table(summarized_data, "summarized_data",
             "Seasonal DO summaries by site and measurement. Mean and SD in mg/L; user-defined skewness is dimensionless.")
export_table(condensed_summary, "condensed_summary",
             "Seasonal DO summaries pooled across sites. Mean, SD, minimum and maximum in mg/L.")
export_table(year_specific_summary, "year_specific_summary_2025",
             "2025 seasonal top-water DO summaries pooled across sites. Mean and SD in mg/L.")
export_table(data_quality_summary, "data_quality_summary", "DO data quality counts across all dates.")
export_table(invalid_oxygen_readings, "invalid_oxygen_readings", "Negative DO readings excluded from analysis; raw readings in mg/L.")
export_table(unavailable_sample_times, "unavailable_sample_times", "Sampling events with missing or unparseable times; original time text retained.")
