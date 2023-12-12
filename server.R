## server.R
# install.packages('rsconnect')
library(rsconnect)
library(stringr)
library(stringdist)
library(dplyr)

# # for app deployment on shiny.io
# rsconnect::setAccountInfo(name='alex-zhou-1013',
#                           token='A6F9600021D632D67EA6AC25259F1D7E',
#                           secret='IZBMOoxH4AuKVgiNDhkP/nzlZQPTWxlRJpGakcTU')
# 
# rsconnect::deployApp(forceUpdate = TRUE)

# read in movie data
myurl = "https://liangfgithub.github.io/MovieData/"
movies = readLines(paste0(myurl, 'movies.dat?raw=true'))
movies = strsplit(movies, split = "::", fixed = TRUE, useBytes = TRUE)
movies = matrix(unlist(movies), ncol = 3, byrow = TRUE)
movies = data.frame(movies, stringsAsFactors = FALSE)
colnames(movies) = c('MovieID', 'Title', 'Genres')
movies$MovieID = as.integer(movies$MovieID)
movies$Title = iconv(movies$Title, "latin1", "UTF-8")
small_image_url = "https://liangfgithub.github.io/MovieImages/"
movies$image_url = sapply(movies$MovieID, 
                          function(x) paste0(small_image_url, x, '.jpg?raw=true'))

# List of genres
genres = c("Action", "Adventure", "Animation", 
           "Children's", "Comedy", "Crime",
           "Documentary", "Drama", "Fantasy",
           "Film-Noir", "Horror", "Musical", 
           "Mystery", "Romance", "Sci-Fi", 
           "Thriller", "War", "Western")

# read in movie recommendation by genre data
github_url <- "https://raw.githubusercontent.com/zjalexzhou/MovieRecommender/master/data/genre-recommendations.csv"
genre_final <- read.csv(github_url)

# read in movie ratings data
github_url <- "https://raw.githubusercontent.com/zjalexzhou/MovieRecommender/master/data/Rmat.csv"
Rmat <- read.csv(github_url)

# read in movie ratings similarity matrix
github_url <- "https://raw.githubusercontent.com/zjalexzhou/MovieRecommender/master/data/movie_similarity_top30.csv"
SSS <- read.csv(github_url)
rownames(SSS) <- SSS$X
SSS <- SSS[, -1]

movie_id_list <- colnames(Rmat)
movie_id_join <- data.frame(MovieID = movie_id_list,
                            stringsAsFactors = FALSE)

# ===============
# server function
shinyServer(function(input, output, session) {
  
  # show the books to be rated
  output$ratings <- renderUI({
    num_rows <- 20
    num_movies <- 6 # movies per row
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        list(box(width = 2,
                 div(style = "text-align:center", img(src = movies$image_url[(i - 1) * num_movies + j], height = 150)),
                 #div(style = "text-align:center; color: #999999; font-size: 80%", books$authors[(i - 1) * num_books + j]),
                 div(style = "text-align:center", strong(movies$Title[(i - 1) * num_movies + j])),
                 div(style = "text-align:center; font-size: 150%; color: #f0ad4e;", ratingInput(paste0("select_", movies$MovieID[(i - 1) * num_movies + j]), label = "", dataStop = 5)))) #00c0ef
      })))
    })
  })
  # Calculate recommendations when the submitGenre button is clicked
  df1 <- eventReactive(input$submitGenre, {
    withBusyIndicatorServer("submitGenre", { # showing the busy indicator
      value_list1 <- reactiveValuesToList(input)
      # print(value_list)
      

      # User input genre
      user_genre <- input$genreInput
      
      if(input$genreInput %in% genres){
        shinyjs::disable("result_message")  # Disable the message
      } else {
        # Find the closest matching genre
        user_genre <- find_closest_genre(input$genreInput, genres)
        shinyjs::enable("result_message")  # Enable the message
        shinyjs::html("result_message", "Invalid input. Showing closest match.")
      }
      
      # # Print the closest matching genre
      # cat("Closest Matching Genre:", user_genre , "\n")
      
      user_predicted_ids1 = genre_final$MovieID[genre_final$genre == user_genre]
      recom_results1 <- data.table(Rank = 1:10,
                                  MovieID = movies$MovieID[user_predicted_ids1],
                                  Title = movies$Title[user_predicted_ids1])
      
    }) # still busy
    
  }) # clicked on button
  
  
  # display the recommendations
  output$results1 <- renderUI({
    num_rows <- 2
    num_movies <- 5
    recom_result1 <- df1()
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, 
            title = paste0(find_closest_genre(input$genreInput, genres), " ", (i - 1) * num_movies + j),
            
            div(style = "text-align:center", 
                a(img(src = movies$image_url[recom_result1$MovieID[(i - 1) * num_movies + j]], height = 150))
            ),
            div(style="text-align:center; font-size: 100%", 
                strong(movies$Title[recom_result1$MovieID[(i - 1) * num_movies + j]])
            )
            
        )        
      }))) # columns
    }) # rows
    
  }) # renderUI function  
  # Calculate recommendations when the sbumbutton is clicked
  df2 <- eventReactive(input$btn, {
    withBusyIndicatorServer("btn", { # showing the busy indicator
        # hide the rating container
        useShinyjs()
        jsCode <- "document.querySelector('[data-widget=collapse]').click();"
        runjs(jsCode)
        
        # get the user's rating data
        value_list2 <- reactiveValuesToList(input)
        
        user_movie_input <- get_user_ratings(value_list2)
        
        # print("user_movie_input")
        # print(user_movie_input)
        
        # print(value_list2)
        user_rated <- user_movie_input$MovieID
        user_ratings <- user_movie_input$rating

        # print(value_list)
        user_predicted_ids <- my_IBCF(user_ratings, SSS)$name
        
        user_predicted_ids <- as.numeric(gsub("^m", "", user_predicted_ids))
        
        print(user_predicted_ids)
        # change to the prediction function
        # user_results = (1:10)/10
        # user_predicted_ids = 11:20
        # user_predicted_ids2 = final_list_recommend$MovieID[final_list_recommend$genre == 'Action']
        recom_results2 <- data.table(Rank = 1:10,
                                    MovieID = movies$MovieID[user_predicted_ids],
                                    Title = movies$Title[user_predicted_ids])
        
        # if recomresults2 Title has NA, we replace that row's user predicted ids with another ramdon movie id generated

    }) # still busy
    # 
  }) # clicked on button
  

  # display the recommendations
  output$results2 <- renderUI({
    num_rows <- 2
    num_movies <- 5
    recom_result2 <- df2()
    
    lapply(1:num_rows, function(i) {
      list(fluidRow(lapply(1:num_movies, function(j) {
        box(width = 2, status = "success", solidHeader = TRUE, title = paste0("Rank ", (i - 1) * num_movies + j),
            
          div(style = "text-align:center", 
              a(img(src = movies$image_url[recom_result2$MovieID[(i - 1) * num_movies + j]], height = 150))
             ),
          div(style="text-align:center; font-size: 100%", 
              strong(movies$Title[recom_result2$MovieID[(i - 1) * num_movies + j]])
             )
          
        )        
      }))) # columns
    }) # rows
    
  }) # renderUI function
  
}) # server function
