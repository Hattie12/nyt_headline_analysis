###########
###########
# DATA ACQUISITION AND ANALYSIS
# The following code performs two functions: 
#   1) Scrapes headline data from the New York Times for a specified range of years.
#   2) Analyzes the scraped data using word tagging and outputs a (much!) smaller final dataframe that is usable in a Shiny app.
# !NOTE! Running this code takes a long time; expect >24 hours for the whole date range. The actual analysis was run via a remote connection
# to an engineering computer and took ~24 hours to complete.
###########
###########

#######
# STEP 1: Install/load libraries
#######

  ### Uncomment libraries that are not already downloaded
  #install.packages("rvest") # This was necessary to install for the html/web scraping https://blog.rstudio.com/2014/11/24/rvest-easy-web-scraping-with-r/
  #install.packages("rlist") # This was used while appending the datasets https://www.rdocumentation.org/packages/rlist/versions/0.4.6.1/topics/list.append
  #install.packages("rJava")
  #install.packages("NLP)
  #install.packages("openNLP")
  #install.packages("RWeka")
  #install.packages("qdap")
  ### NOTE: We could only get the openNLPmodels.en library to work on other machines by manually copying the library folder (also turned in) 
  ### into the appropriate location in the file explorer. The library is no longer available on CRAN and does not function correctly
  ### when downloaded from other sources.
  
  library(rvest)
  library(rlist)
  library(rJava) # openNLP requires Java
  library(NLP)
  library(openNLP)
  library(magrittr)
  library(tidyverse)
  library(openNLPmodels.en) 
  library(RWeka)
  library(qdap)

#######
# STEP 2: Create variables for datascraping functions
#######

  # This vector contains every possible css code that could be used to scrape the data from the website.
  # These consist of 2-3 "terms" that describe whether it is in the first or second half of the year, which month it is, and which "part" it is
  # https://spiderbites.nytimes.com/1960/ this link is helpful in understanding the distinction described above.
  
  parts <- c("#mainContent :nth-child(3) :nth-child(1) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(1) a",
             "#mainContent :nth-child(3) :nth-child(2) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(2) a",
             "#mainContent :nth-child(3) :nth-child(3) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(3) a",
             "#mainContent :nth-child(3) :nth-child(4) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(4) a",
             "#mainContent :nth-child(3) :nth-child(5) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(5) a",
             "#mainContent :nth-child(3) :nth-child(6) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(6) a",
             "#mainContent :nth-child(3) :nth-child(7) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(7) a",
             "#mainContent :nth-child(3) :nth-child(8) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(8) a",
             
             "#mainContent :nth-child(3) :nth-child(1) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(1) a",
             "#mainContent :nth-child(3) :nth-child(2) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(2) a",
             "#mainContent :nth-child(3) :nth-child(3) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(3) a",
             "#mainContent :nth-child(3) :nth-child(4) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(4) a",
             "#mainContent :nth-child(3) :nth-child(5) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(5) a",
             "#mainContent :nth-child(3) :nth-child(6) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(6) a",
             "#mainContent :nth-child(3) :nth-child(7) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(7) a",
             "#mainContent :nth-child(3) :nth-child(8) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(8) a",
             
             "#mainContent :nth-child(3) :nth-child(1) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(1) a",
             "#mainContent :nth-child(3) :nth-child(2) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(2) a",
             "#mainContent :nth-child(3) :nth-child(3) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(3) a",
             "#mainContent :nth-child(3) :nth-child(4) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(4) a",
             "#mainContent :nth-child(3) :nth-child(5) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(5) a",
             "#mainContent :nth-child(3) :nth-child(6) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(6) a",
             "#mainContent :nth-child(3) :nth-child(7) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(7) a",
             "#mainContent :nth-child(3) :nth-child(8) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(8) a",
             
             "#mainContent :nth-child(3) :nth-child(1) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(1) a",
             "#mainContent :nth-child(3) :nth-child(2) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(2) a",
             "#mainContent :nth-child(3) :nth-child(3) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(3) a",
             "#mainContent :nth-child(3) :nth-child(4) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(4) a",
             "#mainContent :nth-child(3) :nth-child(5) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(5) a",
             "#mainContent :nth-child(3) :nth-child(6) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(6) a",
             "#mainContent :nth-child(3) :nth-child(7) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(7) a",
             "#mainContent :nth-child(3) :nth-child(8) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(8) a",
             
             "#mainContent :nth-child(3) :nth-child(1) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(1) a",
             "#mainContent :nth-child(3) :nth-child(2) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(2) a",
             "#mainContent :nth-child(3) :nth-child(3) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(3) a",
             "#mainContent :nth-child(3) :nth-child(4) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(4) a",
             "#mainContent :nth-child(3) :nth-child(5) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(5) a",
             "#mainContent :nth-child(3) :nth-child(6) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(6) a",
             "#mainContent :nth-child(3) :nth-child(7) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(7) a",
             "#mainContent :nth-child(3) :nth-child(8) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(8) a",
             
             "#mainContent :nth-child(3) :nth-child(1) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(1) a",
             "#mainContent :nth-child(3) :nth-child(2) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(2) a",
             "#mainContent :nth-child(3) :nth-child(3) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(3) a",
             "#mainContent :nth-child(3) :nth-child(4) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(4) a",
             "#mainContent :nth-child(3) :nth-child(5) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(5) a",
             "#mainContent :nth-child(3) :nth-child(6) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(6) a",
             "#mainContent :nth-child(3) :nth-child(7) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(7) a",
             "#mainContent :nth-child(3) :nth-child(8) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(8) a",
             
             ####
             
             "#mainContent :nth-child(4) :nth-child(1) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(1) a",
             "#mainContent :nth-child(4) :nth-child(2) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(2) a",
             "#mainContent :nth-child(4) :nth-child(3) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(3) a",
             "#mainContent :nth-child(4) :nth-child(4) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(4) a",
             "#mainContent :nth-child(4) :nth-child(5) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(5) a",
             "#mainContent :nth-child(4) :nth-child(6) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(6) a",
             "#mainContent :nth-child(4) :nth-child(7) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(7) a",
             "#mainContent :nth-child(4) :nth-child(8) li:nth-child(1) a",
             "#mainContent :nth-child(1) li:nth-child(8) a",
             
             "#mainContent :nth-child(4) :nth-child(1) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(1) a",
             "#mainContent :nth-child(4) :nth-child(2) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(2) a",
             "#mainContent :nth-child(4) :nth-child(3) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(3) a",
             "#mainContent :nth-child(4) :nth-child(4) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(4) a",
             "#mainContent :nth-child(4) :nth-child(5) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(5) a",
             "#mainContent :nth-child(4) :nth-child(6) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(6) a",
             "#mainContent :nth-child(4) :nth-child(7) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(7) a",
             "#mainContent :nth-child(4) :nth-child(8) li:nth-child(2) a",
             "#mainContent :nth-child(2) li:nth-child(8) a",
             
             "#mainContent :nth-child(4) :nth-child(1) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(1) a",
             "#mainContent :nth-child(4) :nth-child(2) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(2) a",
             "#mainContent :nth-child(4) :nth-child(3) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(3) a",
             "#mainContent :nth-child(4) :nth-child(4) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(4) a",
             "#mainContent :nth-child(4) :nth-child(5) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(5) a",
             "#mainContent :nth-child(4) :nth-child(6) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(6) a",
             "#mainContent :nth-child(4) :nth-child(7) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(7) a",
             "#mainContent :nth-child(4) :nth-child(8) li:nth-child(3) a",
             "#mainContent :nth-child(3) li:nth-child(8) a",
             
             "#mainContent :nth-child(4) :nth-child(1) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(1) a",
             "#mainContent :nth-child(4) :nth-child(2) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(2) a",
             "#mainContent :nth-child(4) :nth-child(3) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(3) a",
             "#mainContent :nth-child(4) :nth-child(4) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(4) a",
             "#mainContent :nth-child(4) :nth-child(5) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(5) a",
             "#mainContent :nth-child(4) :nth-child(6) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(6) a",
             "#mainContent :nth-child(4) :nth-child(7) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(7) a",
             "#mainContent :nth-child(4) :nth-child(8) li:nth-child(4) a",
             "#mainContent :nth-child(4) li:nth-child(8) a",
             
             "#mainContent :nth-child(4) :nth-child(1) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(1) a",
             "#mainContent :nth-child(4) :nth-child(2) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(2) a",
             "#mainContent :nth-child(4) :nth-child(3) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(3) a",
             "#mainContent :nth-child(4) :nth-child(4) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(4) a",
             "#mainContent :nth-child(4) :nth-child(5) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(5) a",
             "#mainContent :nth-child(4) :nth-child(6) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(6) a",
             "#mainContent :nth-child(4) :nth-child(7) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(7) a",
             "#mainContent :nth-child(4) :nth-child(8) li:nth-child(5) a",
             "#mainContent :nth-child(5) li:nth-child(8) a",
             
             "#mainContent :nth-child(4) :nth-child(1) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(1) a",
             "#mainContent :nth-child(4) :nth-child(2) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(2) a",
             "#mainContent :nth-child(4) :nth-child(3) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(3) a",
             "#mainContent :nth-child(4) :nth-child(4) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(4) a",
             "#mainContent :nth-child(4) :nth-child(5) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(5) a",
             "#mainContent :nth-child(4) :nth-child(6) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(6) a",
             "#mainContent :nth-child(4) :nth-child(7) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(7) a",
             "#mainContent :nth-child(4) :nth-child(8) li:nth-child(6) a",
             "#mainContent :nth-child(6) li:nth-child(8) a"
  )
  
  # This creates a blank dataframe for us to append everything else to
  dftotal <- data.frame("Year"=0,"Headlines"=0)

#######
# STEP 3: Define scraping function
#######
  
  # This function takes year (or years) as input, scrapes the headlines for that year, and outputs a dataframe containing those headlines
  
  scraper <- function(year) {
    # This loops through the years entered (we generally run a decade at a time)
    for(i in year){
      # Creates a blank vector to fill with data
      base <- vector()
      # This loops through everything in the "parts" list
      for(j in parts){
        # "Tries" each possibility without throwing up an error sign if unsuccessful
        result = tryCatch({
          #Navigate to archieve home
          session <- html_session("https://spiderbites.nytimes.com/")
          # follows specific year
          session <- session %>% follow_link(i) %>%
            # chooses which part/month to view
            follow_link(css = j)
          # Scrapes the headlines from this page
          nyttitlesadd <- session %>%
            html_nodes("#headlines a") %>%
            html_text()
          # Adds the scraped data to the base
          base <- list.append(base,list = nyttitlesadd)
          # "Back" in the internet 
          session <- session %>% back()
          
        }, warning = function(w) {
          #warning-handler-code
        }, error = function(e) {
          # error-handler-code
        }, finally = {
          #cleanup-code
          
        })
        
      }
      # Once data for the entire year is collected and appended in "base" it is then added to the main dataframe
      dfadd <- data.frame("Year"=i,"Headlines" =base) 
      dftotal <- rbind(dftotal, dfadd)
      
    }
    
    return(dftotal)
  }

#######
# STEP 4: Scrape the data!
#######    
  # Converts desired range of years to character - the necessary format for the html session
  yearrange <- as.character(1940:1949)
    
  # runs data acquisition function and saves the scraped data in a dataframe
  completeHeadlinesDataframe <- scraper(yearrange)
  
  #View(completeHeadlinesDataframe)
  
  # Converts headlines to .csv- not necessary because dataframe is used; also too big of a file to write successfully
  #write.csv(scraper_output,file="NYT_Headlines.csv")

#######
# STEP 5: Define annotators for the word tagging functions
#######

  # Create entity annotators
  sentence_token_annotator <- Maxent_Sent_Token_Annotator()
  word_token_annotator <- Maxent_Word_Token_Annotator()
  pos_tag_annotator <- Maxent_POS_Tag_Annotator() 
  person <- Maxent_Entity_Annotator(kind = "person") # people
  location <- Maxent_Entity_Annotator(kind = "location") # location
  organization <- Maxent_Entity_Annotator(kind = "organization") # organizations (ex.- Google, Costco)
  #date <- Maxent_Entity_Annotator(kind = "date") # dates
  
  # Compile annotators into a list for easy transfer
  pipeline <- list("sentence_token_annotator" = sentence_token_annotator,
                   "word_token_annotator" = word_token_annotator,
                   "person" = person,
                   "location" = location,
                   "organization" = organization,
                   "pos_tag_annotator" = pos_tag_annotator) 
  
  # Create the dataframe that will store all of the generated information
  analyzedDataframe <- data.frame("selectedWords" = NULL, "Freq" = NULL, "publish_date" = NULL, "type" = NULL)
  
  
#######
# STEP 6: Function to tag, select, and return relevant words
#######
  analyzeWords <- function(dataframe_name, headline_date_range, sort_by_types, doingPOS, output_word_count) {
  
  # Read in the data frame
  headlinesDF <- dataframe_name
  
  # Select the headlines that correspond to the desired dates
  selectedHeadlines <- headlinesDF$headline_text[headlinesDF$publish_date %in% headline_date_range]
  
  # Count how many entries in selectedHeadlines
  headlineCount <- NROW(selectedHeadlines)
  
  # Find 12000 random integer #'s in the range 1 and # of entries
  # If we tried to do all of the headlines, the program would be too big too run
  selectingNums <- seq(from = 1, to = headlineCount, by = round(headlineCount/12000))
  
  # Subset the headlines where the random #'s equals the headlines
  selectedHeadlines <- selectedHeadlines[selectingNums]
  
  # Cast the headline as a string datatype
  headline <- as.String(selectedHeadlines)
  
  # Progress report
  print("I have reached line 50") 
  
  # Create a variable to store the words that will be selected
  selectedWords <- vector()
  
  # Compile annotators that are requested in the function parameters
  # We only do the required annotators to minimize computing time
  pipeline <- list(sentence_token_annotator, 
                   word_token_annotator,
                  if(doingPOS){
                    pipeline[["pos_tag_annotator"]]
                   } else{
                    pipeline[[sort_by_types]]
                  }
                   )
  
  # Apply annotations
  text_annotations <- NLP::annotate(headline, pipeline) 
  
  # Progress report
  print("I have completed annotating")
  
  # Create an AnnotatedPlainTextDocument 
  text_doc <- AnnotatedPlainTextDocument(headline, text_annotations) 
    
  # If there is an input argument for types to sort by
  if(hasArg(sort_by_types)) { 
    k <- sapply(text_annotations$features, '[[', "kind") # Make the word tags accessible
    b <- sapply(text_annotations$features, '[[', "POS") # Make the word tags accessible
    identifiers <- text_doc$content[text_annotations[k %in% sort_by_types]] # Subset the word/phrases matching the identifier kinds
    POS <- text_doc$content[text_annotations[b %in% sort_by_types]] # Subset the word/phrases matching the parts of speech (POS) kinds
    selectedWords <- append(selectedWords, c(identifiers, POS)) # Add the new words to the selectedWords variable
    #selectedWords <- append(selectedWords, c(identifiers)) # Add the new words to the selectedWords variable
  } else { # If there aren't input arguments for "kind" or "POS"
    selectedWords <- append(selectedWords, text_doc$content[text_annotations[text_annotations$type == 'entity']])
  }
  
  # Progress report
  print("I have extracted the words (line 86)")
  
  # Arrange the selectedWords in order of frequency 
  selectedWords <- sort(table(selectedWords), decreasing = TRUE)
  
  # Select the most frequent words
  selectedWords <- selectedWords[1:output_word_count]
  
  # Convert to a data frame
  selectedWords <- data.frame(selectedWords)
  
  # Add a couple of important columns
  selectedWords$publish_date <- headline_date_range
  selectedWords$type <- sort_by_types
  
  # Progress report
  print("I am about to return the selectedWords")
  
  # Return the dataframe
  return(selectedWords)
  
} # end analyzeWords function

#######
# STEP 7: Loop to analyze each year in the headline dataset. 
# !NOTE! Running this operation takes a long time; expect 10 minutes per year/24 hours for the whole date range
#######
  for(year in c(1851:2017)){
    
    # Status update
    print(year)
    
    # Get the top 25 person names for the current year
    newRows <- analyzeWords(completeHeadlinesDataframe, year, "person", FALSE, 25)
    # Status update
    print("I am about to bind the person")
    # Append the new words to the master output dataframe
    analyzedDataframe <- rbind(analyzedDataframe, newRows)
    
    # Get the top 25 location related words for the current year
    newRows <- analyzeWords(completeHeadlinesDataframe, year, "location", FALSE, 25)
    # Status update
    print("I am about to bind the location")
    # Append the new words to the master output dataframe
    analyzedDataframe <- rbind(analyzedDataframe, newRows)
    
    # Get the top 25 organization names for the current year
    newRows <- analyzeWords(completeHeadlinesDataframe, year, "organization", FALSE, 25)
    # Status update
    print("I am about to bind the organization")
    # Append the new words to the master output dataframe
    analyzedDataframe <- rbind(analyzedDataframe, newRows)
  }
  
#######
# STEP 8: Save the dataframe so that it can be loaded in to the Shiny app code
#######
save(analyzedDataframe,file="analyzedDataframe.Rda")
  
