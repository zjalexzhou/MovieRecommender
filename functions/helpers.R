# All the code in this file needs to be copied to your Shiny app, and you need
# to call `withBusyIndicatorUI()` and `withBusyIndicatorServer()` in your app.
# You can also include the `appCSS` in your UI, as the example app shows.

# =============================================

# Set up a button to have an animated loading indicator and a checkmark
# for better user experience
# Need to use with the corresponding `withBusyIndicator` server function
withBusyIndicatorUI <- function(button) {
  id <- button[['attribs']][['id']]
  div(
    `data-for-btn` = id,
    button,
    span(
      class = "btn-loading-container",
      hidden(
        img(src = "ajax-loader-bar.gif", class = "btn-loading-indicator"),
        icon("check", class = "btn-done-indicator")
      )
    ),
    hidden(
      div(class = "btn-err",
          div(icon("exclamation-circle"),
              tags$b("Error: "),
              span(class = "btn-err-msg")
          )
      )
    )
  )
}

# Call this function from the server with the button id that is clicked and the
# expression to run when the button is clicked
withBusyIndicatorServer <- function(buttonId, expr) {
  # UX stuff: show the "busy" message, hide the other messages, disable the button
  loadingEl <- sprintf("[data-for-btn=%s] .btn-loading-indicator", buttonId)
  doneEl <- sprintf("[data-for-btn=%s] .btn-done-indicator", buttonId)
  errEl <- sprintf("[data-for-btn=%s] .btn-err", buttonId)
  shinyjs::disable(buttonId)
  shinyjs::show(selector = loadingEl)
  shinyjs::hide(selector = doneEl)
  shinyjs::hide(selector = errEl)
  on.exit({
    shinyjs::enable(buttonId)
    shinyjs::hide(selector = loadingEl)
  })
  
  # Try to run the code when the button is clicked and show an error message if
  # an error occurs or a success message if it completes
  tryCatch({
    value <- expr
    shinyjs::show(selector = doneEl)
    shinyjs::delay(2000, shinyjs::hide(selector = doneEl, anim = TRUE, animType = "fade",
                     time = 0.5))
    value
  }, error = function(err) { errorFunc(err, buttonId) })
}

# When an error happens after a button click, show the error
errorFunc <- function(err, buttonId) {
  errEl <- sprintf("[data-for-btn=%s] .btn-err", buttonId)
  errElMsg <- sprintf("[data-for-btn=%s] .btn-err-msg", buttonId)
  errMessage <- gsub("^ddpcr: (.*)", "\\1", err$message)
  shinyjs::html(html = errMessage, selector = errElMsg)
  shinyjs::show(selector = errEl, anim = TRUE, animType = "fade")
}

appCSS <- "
.btn-loading-container {
  margin-left: 10px;
  font-size: 1.2em;
}
.btn-done-indicator {
  color: green;
}
.btn-err {
  margin-top: 10px;
  color: red;
}
"

# =============================================

# for system I: recommend movies by genre

# Function to find the closest matching genre
find_closest_genre <- function(user_input, genre_list) {
  distances <- stringdist::stringdistmatrix(tolower(user_input), tolower(genre_list), method = "jaccard")
  closest_index <- which.min(distances)
  closest_genre <- genre_list[closest_index]
  return(closest_genre)
}


# =============================================

# for system II: recommend movies by user-input ratings
get_user_ratings = function(value_list) {
  
  # Filter out entries without "select_"
  filtered_entries <- value_list[startsWith(names(value_list), "select_")]
  
  # Create movie IDs for the two ranges
  movie_ids_range1 <- paste0("m", 1:91)
  movie_ids_range2 <- paste0("m", 93:121)
  
  # Combine the two ranges
  movie_ids <- c(movie_ids_range1, movie_ids_range2)
  
  # Extract ratings
  ratings <- sapply(filtered_entries, function(x) as.numeric(str_extract(x, "\\d+")))
  
  # Combine movie IDs and ratings into a data frame
  movie_data <- data.frame(movie_id = unlist(movie_ids), rating = unlist(ratings))
  
  newuser_data <- movie_id_join %>% left_join(movie_data, by = c("MovieID"="movie_id"))
  
  # print(newuser_data)
  
  return(newuser_data)
}

my_IBCF <- function(newuser, SS){
  # Initialize a vector to store predictions
  
  for (l in 1:length(newuser)) {
    
    # Skip movies that the new user has already rated
    if (!is.na(newuser[l])) {
      next
    }
    # Calculate the prediction for movie l
    numerator <- sum(SS[,l] * newuser, na.rm = TRUE)
    denominator <- sum(SS[,l], na.rm = TRUE)
    
    # Update the predictions vector
    predictions[l] <- ifelse(denominator != 0, numerator / denominator, NA)
  }
  # Get the indices of the top ten predictions
  top_indices <- order(predictions, decreasing = TRUE)[1:10]
  recommended_movies <- data.frame()
  
  # Recommend the top 10 movies
  # Populate the data frame with names and scores
  recommended_movies <- data.frame(
    name = colnames(Rmat)[top_indices],
    score = predictions[top_indices]
  )
  
  return(recommended_movies)
}

