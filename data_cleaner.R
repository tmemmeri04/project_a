#this is my data cleaner, it should take the full dataset from nycopendata and condense it
#down to only the relevant data needed for my analysis
#this code is very much bespoke, and not meant to be used for any other purposes. 
#data source: https://data.cityofnewyork.us/Environment/Harbor-Water-Quality/5uug-f49n/about_data

#We want to extract only the data for NC1, NC2, and NC3
library(readr)
options(show.error.locations = T) #makes error locations visible

fulldata <- read.csv("Harbor_Water_Quality_20260929.csv", stringsAsFactors = F) #strings as factors keeps the char strings as char strings


relavant_locations = c('NC1', 'NC2', 'NC3')

location_header = 'Sampling.Location'
date_header = 'Sample.Date'
DO_CTD_top_h= 'CTD..conductivity..temperature..depth.profiler..Top.Dissolved.Oxygen..mg.L.' #names(fulldata)[15]
DO_CTD_bottom_h = 'CTD..conductivity..temperature..depth.profiler..Bottom.Dissolved.Oxygen..mg.L.' #names(fulldata)[15]
DO_winkler_top_h = 'Winkler.Method.Top.Dissolved.Oxygen..mg.L.' #names(fulldata)[37]
DO_winkler_bottom_h = 'Winkler.Method.Bottom.Dissolved.Oxygen..mg.L.' #names(fulldata)[38]

#####################################################################################
## this creates a new output file with only the relevant locations (NC1, NC2, NC3) ##
#####################################################################################


locations = fulldata[[location_header]] #extracting the column for sampling locations

new_fulldata = data.frame(
    Sampling.Location = locations[locations %in% relavant_locations],
    Sample.Date = fulldata[[date_header]][locations %in% relavant_locations],
    Dissolved_Oxygen_CTD_top = fulldata[[DO_CTD_top_h]][locations %in% relavant_locations],
    Dissolved_Oxygen_CTD_bottom = fulldata[[DO_CTD_bottom_h]][locations %in% relavant_locations],
    Dissolved_Oxygen_winkler_top = fulldata[[DO_winkler_top_h]][locations %in% relavant_locations],
    Dissolved_Oxygen_winkler_bottom = fulldata[[DO_winkler_bottom_h]][locations %in% relavant_locations]
)

############################@#@@!@@#@!#!@#!@#!@#!@#!###
######                                                #
# THIS HAS BEEN DONE!!! BE CAREFUL NOT TO DO IT AGAIN #
# write_csv(new_fulldata, "filtered_data.csv")        #
#                                                ######
###############!@#@!#@!$@%#@#$!$!$@#@#@#@#@############

#######################################################################
## this separates the sample dates into winter and summer categories ##
#######################################################################
    
new_dates = fulldata[[date_header]] #extracting the column for sample dates
rowcount = length(new_dates) #determining the number of rows in the dataset
date_array = strsplit(new_dates,split='/') #splitting the date strings into day, month, and year components

winter_dates = list()
summer_dates = list()
for (i in 1:rowcount){ 
    month = as.integer(date_array[[i]][1]) #extracting the month from the split date array
    day = as.integer(date_array[[i]][2]) #extracting the day from the split date array
    
    is_winter = (month == 12 & day >=21) | (month %in% c(1, 2)) | (month == 3 & day <= 20)
    is_summer = (month == 6 & day >= 21) | (month %in% c(7, 8)) | (month == 9 & day <= 20)
    
    if (is_winter) {
        winter_dates[[length(winter_dates) + 1]] = new_dates[i]
    } else if (is_summer) {
        summer_dates[[length(summer_dates) + 1]] = new_dates[i]
    }
}

winter_dates = unlist(winter_dates) #converting the list of winter dates into a vector
summer_dates = unlist(summer_dates) #converting the list of summer dates into a vector

