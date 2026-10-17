#~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!~~~~~~~`/\`!!!!
#this is my data cleaner, it should take the full dataset from nycopendata and condense it
#down to only the relevant data needed for my analysis
#this code is very much bespoke, and not meant to be used for any other purposes. 
#data source: https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data

#declaring packages needed for this script
library(readr)

#We want to extract only the data for NC1, NC2, and NC3
options(show.error.locations = TRUE) #makes error locations visible

raw_data_path <- file.path("data", "raw", "Harbor_Water_Quality_20260929.csv")
processed_data_path <- file.path("data", "processed", "filtered_data.csv")

fulldata <- read.csv(raw_data_path, stringsAsFactors = FALSE) #strings as factors keeps the char strings as char strings

relevant_locations <- c('NC1', 'NC2', 'NC3')

location_header <- 'Sampling.Location'
date_header <- 'Sample.Date'
DO_CTD_top_h <- 'CTD..conductivity..temperature..depth.profiler..Top.Dissolved.Oxygen..mg.L.' #names(fulldata)[15]
DO_CTD_bottom_h <- 'CTD..conductivity..temperature..depth.profiler..Bottom.Dissolved.Oxygen..mg.L.' #names(fulldata)[15]
DO_winkler_top_h <- 'Winkler.Method.Top.Dissolved.Oxygen..mg.L.' #names(fulldata)[37]
DO_winkler_bottom_h <- 'Winkler.Method.Bottom.Dissolved.Oxygen..mg.L.' #names(fulldata)[38]

#####################################################################################
## this creates a new output file with only the relevant locations (NC1, NC2, NC3) ##
#####################################################################################

locations = fulldata[[location_header]] #extracting the column for sampling locations

new_fulldata = data.frame(
    Sampling.Location = locations[locations %in% relevant_locations],
    Sample.Date = fulldata[[date_header]][locations %in% relevant_locations],
    Dissolved_Oxygen_CTD_top = fulldata[[DO_CTD_top_h]][locations %in% relevant_locations],
    Dissolved_Oxygen_CTD_bottom = fulldata[[DO_CTD_bottom_h]][locations %in% relevant_locations],
    Dissolved_Oxygen_winkler_top = fulldata[[DO_winkler_top_h]][locations %in% relevant_locations],
    Dissolved_Oxygen_winkler_bottom = fulldata[[DO_winkler_bottom_h]][locations %in% relevant_locations]
)

############################@#@@!@@#@!#!@#!@#!@#!@#!###
######                                                #
# THIS HAS BEEN DONE!!! BE CAREFUL NOT TO DO IT AGAIN #
# write_csv(new_fulldata, processed_data_path)        #
#                                                ######
###############!@#@!#@!$@%#@#$!$!$@#@#@#@#@############
