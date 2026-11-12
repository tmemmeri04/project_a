#~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!
## this script takes the filtered data and converts it into long format #
####
#######

library(tidyr)
library(dplyr)
library(readr)

#reading necessary data
processed_data_path <- file.path(
    "data",
    "processed",
    "filtered_data.csv"
)
new_fulldata <- read_csv(
    processed_data_path,
    col_types = cols(Sample.Date = col_date(), Sample.Time = col_character())
)

#editing new_fulldata characteristics#
new_fulldata$Dissolved_Oxygen_winkler_top = as.numeric(new_fulldata$Dissolved_Oxygen_winkler_top)
new_fulldata$Dissolved_Oxygen_winkler_bottom = as.numeric(new_fulldata$Dissolved_Oxygen_winkler_bottom)
# Keep unparseable source times for review; do not invent replacements.
new_fulldata$Sample.Time.raw <- new_fulldata$Sample.Time
new_fulldata$Sample.Time <- suppressWarnings(parse_time(new_fulldata$Sample.Time))
stopifnot(!anyNA(new_fulldata$Sample.Date))

#taking existing wide data and making it into a long format#

long_data = new_fulldata |>
    pivot_longer(
        cols = starts_with("Dissolved_Oxygen"),
        names_to = "Measurement",
        values_to = "Dissolved_Oxygen"
    )

# Exclude negative measurements entirely; keep the single-row log separately.
# Explicitly retain missing DO so missingness counts remain available.
invalid_oxygen_readings <- long_data |>
    filter(!is.na(Dissolved_Oxygen), Dissolved_Oxygen < 0)
long_data <- long_data |>
    filter(is.na(Dissolved_Oxygen) | Dissolved_Oxygen >= 0)

long_data_path <- file.path(
    "data",
    "processed",
    "long_data.csv"
)

write_csv(long_data, long_data_path)
