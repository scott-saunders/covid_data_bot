
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

#READ IN PREVIOUS TWEETS
previous_messages = read_csv("previous_messages.csv", col_types = 'cl')

print(previous_messages)

#SEARCH FOR ALL RECENT TWEETS TO HANDLE
raw_messages <-  direct_messages()

messages <- tibble(id = raw_messages$events$id,
       sender_id = raw_messages$events$message_create$sender_id,
       text = raw_messages$events$message_create$message_data$text) %>% 
  filter(sender_id != 1309922170487730176)

print(messages)

for (i in 1:nrow(messages)){
  print(messages$id[i])
  
  
  #IF ID IS NOT IN PREVIOUS TWEETS
  if (!(messages$id[i] %in% previous_messages$id)){
    
    tweet_state <- states$state[str_detect(messages$text[i], fixed(states$state, ignore_case = T))]
    print(tweet_state)
    
    
    if(length(tweet_state)==1){
      print('state found')
      
      counties_subset <- counties %>% filter(state == tweet_state)
      
      tweet_county <- counties_subset$county[str_detect(messages$text[i], fixed(counties_subset$county, ignore_case = T))]
      print(tweet_county)
      
      if(length(tweet_county)==1){
        print('county found')
        
        source('draft_tweet_functions.R')
        
        nyt_data <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')
        
        pop_data <- read_csv('us_county_census.csv') %>% filter(COUNTY!='000')  %>% 
          mutate(fips = paste0(STATE,COUNTY)) %>% 
          filter(COUNTY!='000') %>% 
          select(fips, pop2019 = POPESTIMATE2019)
        
        #print(list.files())
        
        text <- draft_tweet(tweet_state, tweet_county, nyt_data, pop_data)
        
        print(text)
        
        #print(list.files())
        
        post_message(text, user = messages$sender_id[i], media = 'plot_cases.png')
        post_message('deaths', user = messages$sender_id[i], media = 'plot_deaths.png')
        post_message('risk', user = messages$sender_id[i], media = 'plot_risk.png')
        post_message('map', user = messages$sender_id[i], media = 'plot_state_map.png')
      }
      else{ print('county not found')}
      
    } 
    else{ print('state not found')}
    
    #ADD TO PREVIOUS TWEETS
    previous_messages = bind_rows(previous_messages, tibble(id = messages$id[i], replied = T))
    print('tweet archived')
    
  }
  
  print("Done!")
  
}

#previous_tweets = tibble(id = tweets$status_id, replied = T)
write_csv(previous_messages,"previous_messages.csv")
