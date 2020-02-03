#History in Headlines
#Final Project, PLS 202, Dec. 12, 2018
#Hattie Pimentel, Rhett Pimentel, Hunter Kuchek, Jonathan Zaremba


#The following links were referenced in the creation of this app:
#API key issue: https://stackoverflow.com/questions/36175529/getting-over-query-limit-after-one-request-with-geocode
#On mutate_geocode: https://rdrr.io/cran/ggmap/man/mutate_geocode.html
#On mutate_geocode: https://www.jessesadler.com/post/geocoding-with-r/


######################################IMPORTANT NOTES#################################################################
#The Google Geocoding API only allows 2500 queries a day without a premium subscription. 
#Therefore, we ran the code on two parts.
#First, we geocode the first 2402 records, then we geocoded the last 1773 and combined the dataframes.
#For this reason, this script cannot be 
#ran as a whole. The two pieces are explained below.

#This requires the development version of ggmap
#devtools::install_github("dkahle/ggmap")

#load libraries
library(ggmap)
library(googleway)
library(tidyverse)

#register Google geocoding api key
register_google(key = [Redacted])

#load the dataset
load([Redacted Path])

#divide the dataframe into 3 parts: people, location, and organizations
peopleFrame <- analyzedDataframe %>% filter(type == "person") 
organizationFrame <- analyzedDataframe %>% filter(type == "organization") 

#Take only 2402 location entries, since we only have 2402 geocodes left
locationFrame <- analyzedDataframe %>% filter(type == "location") %>% head(n=2402)

#create empty  lon/lat columns for people.
#this is so the peopleFrame and locationFrame can be bound together later
peopleFrame$lon <- NA
peopleFrame$lat <- NA

#create empty lon/lat colunms for organizations
organizationFrame$lon <- NA
organizationFrame$lat <- NA

#the mutate_geocode command only works when "stringsAsFactors" is explicitly false, 
#so set it explictly false
locationFrame <- data.frame(selectedWords = as.character(locationFrame$selectedWords), 
                            Freq = locationFrame$Freq, 
                            publish_date = locationFrame$publish_date,
                            type= locationFrame$type,
                            stringsAsFactors = FALSE)

#add on the lat/lon values corresponding to the location
locationFrame <- mutate_geocode(locationFrame, selectedWords)

#bind the location with the people and organizations 
analyzedDataframe2 <- rbind(locationFrame,peopleFrame, organizationFrame)



#########################################DAY 2########################################################

#get the las 1773 location records
locationFrame <- analyzedDataframe %>% filter(type == "location") %>% tail(n=1773)

#make stringsAsFactors explictly false
locationFrame <- data.frame(selectedWords = as.character(locationFrame$selectedWords), 
                            Freq = locationFrame$Freq, 
                            publish_date = locationFrame$publish_date,
                            type= locationFrame$type,
                            stringsAsFactors = FALSE)

#add the lat and long to the corresponding location
locationFrame <- mutate_geocode(locationFrame, selectedWords)

#bind the new loc data to yesterday's dataframe
#in our case, we reloaded both dataframes
analyzedDataframe2 <- rbind(locationFrame,analyzedDataframe2)


#save the dataframe
save(masterFrame,file="analyzedDataFrameHead.Rda")

