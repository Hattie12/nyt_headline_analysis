#############################SLIDER

#The following sources were referenced in the creation of this app:
  #For the comboBox (at least, while we had one): https://shiny.rstudio.com/reference/shiny/0.14/selectInput.html
  #For the date input: https://stackoverflow.com/questions/40908808/how-to-sliderinput-for-dates
  #For the date input: https://github.com/rstudio/shiny/issues/1618
  #How to use the bubble extension in R Shiny: https://github.com/rstudio/shiny-examples/blob/master/087-crandash/ui.R
  #Info on the bubbles extension: https://github.com/jcheng5/bubbles
  #Problem with the input: https://stackoverflow.com/questions/23299684/r-error-in-xed-operator-is-invalid-for-atomic-vectors
  #Viewing in app instead of R Studio viewer: https://stackoverflow.com/questions/32161923/plot-in-shiny-display-in-viewer-in-r-studio-instead-of-web-browser
  #Info on the bubbles extension: https://www.rdocumentation.org/packages/bubbles/versions/0.2/topics/bubbles
  #Tooltip: https://www.rdocumentation.org/packages/RLumShiny/versions/0.2.1/topics/tooltip
  #Switches: https://dreamrs.github.io/shinyWidgets/reference/materialSwitch.html
  #More Switches: https://dreamrs.github.io/shinyWidgets/index.html
  #Formatting headlines: https://shiny.rstudio.com/tutorial/written-tutorial/lesson2/
  #Re-color slider: https://stackoverflow.com/questions/36906265/how-to-color-sliderbar-sliderinput
  #Try-Catch Statement: http://mazamascience.com/WorkingWithData/?p=912
  #Dynamic Main Panel: http://shiny.rstudio.com/articles/dynamic-ui.html
  #More on dynamic main panel: https://stackoverflow.com/questions/50939906/conditional-main-panel-in-shiny
  #Javascript Operators: https://www.w3schools.com/jsref/jsref_operators.asp
  #Counting words in a string: https://stackoverflow.com/questions/8920145/count-the-number-of-all-words-in-a-string
  #Leaflet: https://rstudio.github.io/leaflet/shiny.html 

#load libraries
library(shiny)
library(bubbles)
library(tidyverse)
library(shinyWidgets)
library(maps)
library(leaflet)

#load the dataset
############################THIS MUST BE LOADED MANUALLY#######################################
load([Redacted])


ui <- fluidPage(
 
  #grand title
  titlePanel(h1("A Loop Through Time: History in Headlines", style = "font-family: 'times'; font-si16pt")),
 
  sidebarLayout(
  
    #user inputs on the side 
    sidebarPanel(
      
      #change the slider background color (see references)
      tags$style(HTML(".js-irs-0 .irs-single, .js-irs-0 .irs-bar-edge, .js-irs-0 .irs-bar {background:#EB7B59 }")),
      
      #Use slider to select start date
      sliderInput(inputId = "inputDate", label = h2("Year", style = "font-family: 'times'; font-si16pt"), 
                  min=1851,
                  max=2017,
                  value= 2016, 
                  step = 1, 
                  animate = animationOptions(interval = 1500, loop = TRUE, playButton = NULL, pauseButton = NULL),
                  ticks = TRUE,
                  width = NULL, sep = ",", pre = NULL, post = NULL
      ),#closes slider
        
      #include a title over the toggle switches
      h2("Elements:", style = "font-family: 'times'; font-si16pt"),
      
      #Include a toggle switch the user can select to see people, location, or organizations
      materialSwitch(inputId = "People", label = "People", status = "default", right = FALSE),
      materialSwitch(inputId = "Location", label = "Location", status = "default", right = FALSE),
      materialSwitch(inputId = "Organization", label = "Organization", status = "default", right = FALSE)
      
      ),#closes sideBarPanel
    
    mainPanel(
      
      # when the user has selected only location
      conditionalPanel(
        condition = "!input.People & !input.Organization & input.Location",
        
        #display the map
        leafletOutput("map", width = "100%", height = 800)
      ),
      
      #if the user hasn't selected anything
      conditionalPanel(
        condition = "!input.People & !input.Organization & !input.Location & !input.About",
        
        #give them a message
        h1("Please Select Something", style = "font-family: 'times'; font-si16pt")
      ),
      
      #in all other circumstances 
      conditionalPanel(
        condition = "!(!input.People & !input.Organization & input.Location)&&!(!input.People & !input.Organization & !input.Location)",
        
        #show the bubble map
        bubblesOutput("bubbleChart", width = "100%", height = 800)
      )
    )#closes MainPanel

    )#closes sidebarLayout
    
) #closes ui

