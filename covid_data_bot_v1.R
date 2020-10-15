

install.packages(c('rtweet', 'tidyverse'),Ncpus = 2)

library(tidyverse)
library(rtweet)


# create token named "twitter_token"
create_token(
  app = "covid_data_bot",  # the name of the Twitter app
  consumer_key = Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token = Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret = Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)

counties <- read_csv('nyt_county_list.csv')

states <- read_csv('nyt_state_list.csv')

#tweet_state <- 'Cobb'
#tweet_county <- 'Georgia'


#READ IN PREVIOUS TWEETS
previous_tweets = read_csv("previous_tweets.csv", col_types = c('cl'))

print(previous_tweets)

#SEARCH FOR ALL RECENT TWEETS TO HANDLE
tweets = search_tweets(q = "@covid_data_bot", include_rts = F)

print(tweets)

#tweets = tibble(status_id = c('1'), text = c('Cobb County, Georgia'))

#LOOP THROUGH TWEET STATUS ID'S. IF STATUS IS NOT IN PREVIOUS TWEETS THEN REPLY.
for (i in 1:nrow(tweets)){
  print(tweets$status_id[i])
  
  
  #IF ID IS NOT IN PREVIOUS TWEETS
  if (!(tweets$status_id[i] %in% previous_tweets$id)){
    
    tweet_state <- states$state[str_detect(tweets$text[i], fixed(states$state,ignore_case = T))]
    print(tweet_state)
    
    
    if(length(tweet_state)==1){
      print('state found')
      
      counties_subset <- counties %>% filter(state == tweet_state)
      
      tweet_county <- counties_subset$county[str_detect(tweets$text[i], fixed(counties_subset$county, ignore_case = T))]
      print(tweet_county)
      
      if(length(tweet_county)==1){
        print('county found')
        
        ###############
        
        source('draft_tweet_functions.R')
        
        nyt_data <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')
        
        pop_data <- read_csv('us_county_census.csv') %>% filter(COUNTY!='000')  %>% 
          mutate(fips = paste0(STATE,COUNTY)) %>% 
          filter(COUNTY!='000') %>% 
          select(fips, pop2019 = POPESTIMATE2019)
        
        text <- draft_tweet(tweet_state, tweet_county, nyt_data, pop_data)
        
        print(text)
        
        post_tweet(status = text, media = c('plot_cases.png', 'plot_deaths.png', 'plot_risk.png', 'plot_state_map.png'), in_reply_to_status_id = tweets$status_id[i])
      
      }
      else{ print('county not found')}
      
    } 
    else{ print('state not found')}
    
    #ADD TO PREVIOUS TWEETS
    previous_tweets = bind_rows(previous_tweets, tibble(id = tweets$status_id[i], replied = T))
    print('tweet archived')

  }
  
  print("Done!")
  
}

#previous_tweets = tibble(id = tweets$status_id, replied = T)
write_csv(previous_tweets,"previous_tweets.csv")



