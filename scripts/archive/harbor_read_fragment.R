# script to analyze NYC harbor data
# note that all non extended ascii characters had to be removed from the headers
# also need to turn off strings as factors so that R will not try to
# numericalize character strings.  Also eliminate parenthesis, divisions...
# use '.' to fill spaces in headers

options(show.error.locations = TRUE)

fulldata = read.csv(file.path("data", "raw", "Harbor_Water_Quality_fixed.csv"),stringsAsFactors=F)

ourlocations = c('N4','TR1','TR2','N3C') # were for the triathalon
Nloc = length(ourlocations)

# note use of . as spaces
locationheader = 'Sampling.Location'
dateheader = 'Sample.Date'
DOheader = 'Winkler.Method.Top.Dissolved.Oxygen.mgperL'

# locations = fulldata$Sampling.Location
locations = fulldata[[locationheader]]

#dates = fulldata$Sample.Date
dates = fulldata[[dateheader]]
print(dates[1:3])
rowcount = length(dates)

date_array = strsplit(dates,split='/')
print(date_array[1:3])
years = integer(rowcount)
for (i in 1:rowcount){ years[i] = as.integer(date_array[[i]][3])}

# pick out data from 2024 only
data = fulldata[which(years == 24),]
print(data[1:3,1:5])
