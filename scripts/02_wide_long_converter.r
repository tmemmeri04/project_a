#~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!
## this script takes the filtered data and converts it into long format #
####
#######

library(tidyr)
library(dplyr)

#reading necessary data
processed_data_path <- file.path(
    "data",
    "processed",
    "filtered_data.csv"
)
new_fulldata <- read.csv(
    processed_data_path, 
    stringsAsFactors = FALSE
)

#editing new_fulldata characteristics#
new_fulldata$Dissolved_Oxygen_winkler_top = as.numeric(new_fulldata$Dissolved_Oxygen_winkler_top)
new_fulldata$Dissolved_Oxygen_winkler_bottom = as.numeric(new_fulldata$Dissolved_Oxygen_winkler_bottom)
new_fulldata$Sample.Date = as.Date(new_fulldata$Sample.Date, format="%m/%d/%Y")

#taking existing wide data and making it into a long format#

long_data = new_fulldata |>
    pivot_longer(
        cols = starts_with("Dissolved_Oxygen"),
        names_to = "Measurement",
        values_to = "Dissolved_Oxygen"
    )

long_data_path <- file.path(
    "data",
    "processed",
    "long_data.csv"
)

saveRDS(long_data, long_data_path)