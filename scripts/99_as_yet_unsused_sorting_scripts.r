#This is code i wrote but no longer really need. I might use it in the future

#sorting by location, this is not really being used...#
nc1_data = new_fulldata[new_fulldata$Sampling.Location == 'NC1', ]
nc2_data = new_fulldata[new_fulldata$Sampling.Location == 'NC2', ]
nc3_data = new_fulldata[new_fulldata$Sampling.Location == 'NC3', ]

nc1_data$Sample.Date = as.Date(nc1_data$Sample.Date, format="%m/%d/%Y")
nc2_data$Sample.Date = as.Date(nc2_data$Sample.Date, format="%m/%d/%Y")
nc3_data$Sample.Date = as.Date(nc3_data$Sample.Date, format="%m/%d/%Y")

#changing char columns to num columns#
nc1_data$Dissolved_Oxygen_winkler_top = as.numeric(nc1_data$Dissolved_Oxygen_winkler_top)
nc1_data$Dissolved_Oxygen_winkler_bottom = as.numeric(nc1_data$Dissolved_Oxygen_winkler_bottom)
nc2_data$Dissolved_Oxygen_winkler_top = as.numeric(nc2_data$Dissolved_Oxygen_winkler_top)
nc2_data$Dissolved_Oxygen_winkler_bottom = as.numeric(nc2_data$Dissolved_Oxygen_winkler_bottom)
nc3_data$Dissolved_Oxygen_winkler_top = as.numeric(nc3_data$Dissolved_Oxygen_winkler_top)
nc3_data$Dissolved_Oxygen_winkler_bottom = as.numeric(nc3_data$Dissolved_Oxygen_winkler_bottom)


#this code will most likely be needed in the future, but is not currently being used
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
