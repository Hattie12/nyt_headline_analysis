###################################SLIDER/Color

#load libraries
library(tidyverse)
library(shiny)
library(bubbles) #this is downloaded from GitHub
library(dplyr)
library(shinyWidgets)
library(leaflet)

#Clean up the data, and subset it by the toggle switches the user selected
#Takes in the dataframe subset by year, and the values of the three toggle switches
cleanAndSubset <- function(df1, People, Location, Organization){
  
  #First, clean up the words a little
  #Irrelevant words the annotator found
  wordsToRemove <- c("The", "Paul Krugman", "Joe Nocera", "Music","In","Minor Crimes","Lives","Affadavit.","will","will be",
                     "By Judge Barrett","He","Per","Cent","Per Cent","No","Shoots Himself","By","Bill Approved",
                     "New","New Publications","The Times","Corrections","But","it", "An","His")
  
  #remove the irrelevant words
  df1 <- df1[!(df1$words %in% wordsToRemove),]
  
  #Get rid of the newspaper phrases: "No Title..." and "Chronicle..." and "...News"
  df1 <- df1[!(startsWith(df1$words, "No Title")),]
  df1 <- df1[!(endsWith(df1$words, "News")),]
  df1 <- df1[!(startsWith(df1$words, "Chronicle")),]
  
  #This helped keep some junk out, but it also deletes F.B.I., which is dissapointing
  df1 <- df1[!(endsWith(df1$words, ".")),]
  
  #Delete long phrases (they're often nonsense, and they don't fit in the graph)
  df1 <- df1[!(sapply(strsplit(df1$words, " "), length) >=4),]
  
  #Now, subset the data by the user's toggle switch values
  #Create an empty shopping-basket-dataframe to add rows to
  df2 <- data.frame(words = NULL, percentages = NULL, tooltip = NULL, color = NULL, lon = NULL, lat = NULL)

  #if the user wants to see people
  if (People == TRUE) {
    #add rows with the color that corresponds to names
    df2 <- rbind(df2, df1[df1$color == "#EB7B59",])
  } 
  
  #if the user wants to see locations
  if (Location == TRUE) {
    #add rows with the color corresponding to location
    df2 <- rbind(df2, df1[df1$color == "#028F76",])
  } 
  
 #if the user wants to see organizations
  if (Organization == TRUE) {
    #add rows with the color assigned to organizations
    df2 <- rbind(df2, df1[df1$color == "#E5DDCB",])
  } 
  
  #arrange the words by popularity, so the bubble chart looks nice
  df2 <- df2 %>% arrange(desc(percentages))
  
  #Select 30 words at most
  if (nrow(df2) > 30) {
    df2 <- head(df2, 30)
  } 
  
  #If there aren't any rows, inform the user
  if (nrow(df2) == 0) {
    df2 <- data.frame(words = c("No Words"), percentages = 4, tooltip = "No Words", color = "#E5DDCB", lat = NA, lon = NA)
  } 
  
  #return the subsetted and cleaned dataframe
  return(df2)
}


server <- function(input, output) {
    
  getWords <- reactive({ #IMPORTANT need the "reactive" function
    
    #Get variable inputs from UI
    startDate <- input$inputDate #slider year
    People <- input$People #show people
    Location <- input$Location #add location
    Organization <- input$Organization #add organizations
    
    #Get the words for the current year
    wordsForYear <- masterFrame %>% filter(publish_date == startDate)
   
    #Set the tooltip equal to the word (incase the bubble chart covers it up)
    wordsForYear$tooltip <- paste(wordsForYear$selectedWords)
    
    #put words in capitalization case, and assign colors based on what kind of word it is (location, place, people)
    wordsForYear <- wordsForYear %>% mutate(words = tools::toTitleCase(tolower((selectedWords))), percentages=Freq, tooltip = tooltip, 
                            color = ifelse(type == "person","#EB7B59",
                                             ifelse(type == "location","#028F76", "#E5DDCB"))) %>% 
                                  select(words, percentages, tooltip, color, lat, lon)
  
    #clean up the words and subset by the kind of words the user wants to see
    wordsForYear <- cleanAndSubset(wordsForYear, People, Location, Organization)
    
    #return the df of words
    return(wordsForYear)
    
  }) #close Reactive function
  
  
  #gathers data and outputs a bubble chart
  output$bubbleChart <- renderBubbles({ #the output bubble chart
    
    #call the data function from above
    words <- getWords()
    
    #make a bubble chart
    #the key is used to track each bubble so the bubbles slide around
    bubbles(words$percentages, words$words, key=words$words, tooltip = words$tooltip, color = words$color)
  })#close output bubbles
  
  #when only location is on, this will be called to render the world map once
  output$map <- renderLeaflet({
    
    #get the map dataframe from the maps library
    mapStates = map("world", fill = TRUE, plot = FALSE)
   # leaflet(data = mapStates) %>% addTiles()# %>% setView(0,0,zoom=20)
    m <- leaflet() %>% addTiles() %>% setView(0,0, zoom = 2)
  })

  #this updates the leaflet without without wiping out the map every time
  observe({
    #get the data
    words <- getWords()
    
    #remove any NAs
    words <- words %>% filter((is.numeric(lat) && is.numeric(lon)))
    
    #we had trouble getting the leafletProxy function to work
    #so we vectorized the words dataframe and used that instead 
    lo <- as.numeric(words$lon)
    la <- as.numeric(words$lat)
    ra <- as.numeric(words$Freq) * 100
    po <- words$selectedWords
    
    #add circles to the map by location
    leafletProxy("map", data = words) %>% addTiles() %>%
      clearShapes() %>% #clear every new year
      addCircles(lng = ~(lo), lat = ~(la), weight = 15
     )
  })
  
  
}#close server function

