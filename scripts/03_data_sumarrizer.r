library(dplyr)

long_data_path <- file.path(
    "data",
    "processed",
    "long_data.csv"
)

long_data <- readRDS(long_data_path)

#statistical summaries#
summarized_data <- long_data |>
    group_by(Sampling.Location, Measurement) |>
    summarise(
        total_rows = n(),
        missing_rows = sum(is.na(Dissolved_Oxygen)),
        usable_rows = total_rows - missing_rows,
        mean = mean(Dissolved_Oxygen, na.rm = TRUE),
        median = median(Dissolved_Oxygen, na.rm = TRUE),
        sd = sd(Dissolved_Oxygen, na.rm = TRUE)
    )
