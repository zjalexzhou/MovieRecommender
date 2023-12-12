# MovieRecommender

This is code for a shiny app for a movie recommender based on item-based collaborative filtering. 

By Yilun Zhao & Zhijie Zhou.
STAT 542: Practical Statistics Learning, Fall 2023

System I: Allow users to input their favorite movie genre. Provide 10 movie recommendations based on the user’s selected genre. 
- designed to recommend the top movies in a specified genre based on average ratings and total ratings. The function takes parameters such as the target genre (genre), the number of top movies to recommend (top_n), and a minimum threshold for the number of ratings a movie must have to be considered (min_ratings).
- could take "obscure" inputs, for example: "actions" "action movie" "actinioning" will be treated as "Actions" and this app would return a list of top 10 Actions movies to the user.

System II: Present users with a set of sample movies and ask them to rate them. Use the ratings provided by the user as input for your myIBCF function. Display 10 movie recommendations for the user based on their ratings.

[update] Dec 11th 8pm
We seemed to face some issues with deployment. The app would drop connection in a few seconds you open the web link.

**Run app.R** for local deployment after download and unzip the file associated with the repo.

