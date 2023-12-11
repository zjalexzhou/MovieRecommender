## ui.R
library(shiny)
library(shinydashboard)
library(recommenderlab)
library(data.table)
library(ShinyRatingInput)
library(shinyjs)
library(shinythemes)



source('functions/helpers.R')
# 
# jsCode <- "shinyjs.tabNameChange = function() {
#         if (tabName == 'home') {
#           shinyjs.toggleElement('#homePanel', true);
#         } else {
#           shinyjs.toggleElement('#homePanel', false);
#         }
#       };"

shinyUI(
  dashboardPage(
    skin = "purple",
    dashboardHeader(title = "Movie Recommender"),
    
    dashboardSidebar(
      sidebarMenu(
        menuItem("Home Page", tabName = "home"),
        menuItem("Recommendation by Genre", tabName = "dashboard1", icon = icon("th")),
        menuItem("Recommendation by Rating", tabName = "dashboard2", icon = icon("dashboard"))
      )
      # disable = TRUE
    ),
    dashboardBody(
      includeCSS("css/movies.css"),
      # 
      # useShinyjs(),  # Initialize shinyjs
      # # Use shinyjs to hide/show the conditionalPanel based on tabName
      # extendShinyjs(text = jsCode, functions = c("tabNameChange")),
      # 
      tabItems(
        tabItem(
        tabName = 'home',
        fluidRow(
          box(width = 12,
                 h2("Your Personalized Movie Recommednation Syste at One-Click"),
                 p("Please choose a dashboard from the menu."),
                 p("System I: Allow users to input their favorite movie genre. 
                   Provide 10 movie recommendations based on the user’s selected genre."),
              p("System II: Present users with a set of sample movies and ask them to rate them.
                Use the ratings provided by the user as input for your myIBCF function. 
                Display 10 movie recommendations for the user based on their ratings."),
              br(),
              p("Developed by Yilun Zhao (yilun3@illinois.edu) and Zhijie 'ZJ' Zhou (zhijiez2@illinois.edu)"),
          )
        )
      ),
     tabItem(
       tabName = 'dashboard1',
       fluidRow(
         useShinyjs(),
         box(
           width = 12, status = "primary", solidHeader = TRUE,
           title = "We'll generate a list of videos based on your genre preference!",
           br(),
           textInput("genreInput", "Enter Movie Genre:", placeholder = "e.g., Action"),
           withBusyIndicatorUI(
             actionButton("submitGenre", "Submit Genre")
           ),
           br(),
           tableOutput("results1")
           )
       )

      ),
      tabItem(
        tabName = 'dashboard2',
        fluidRow(
            box(width = 12, title = "Step 1: Rate as many movies as possible", 
                status = "primary", solidHeader = TRUE, collapsible = TRUE,
                div(class = "rateitems",
                    uiOutput('ratings')
                )
            )
          ),
        fluidRow(
            useShinyjs(),
            box(
              width = 12, status = "primary", solidHeader = TRUE,
              title = "Step 2: Discover Movies you might like",
              br(),
              withBusyIndicatorUI(
                actionButton("btn", "Click here to get your TOP 10 recommendations", class = "btn-warning")
              ),
              br(),
              tableOutput("results2")
            )
        )
      )
    )
  )
) )