if(!(require('rtweet') & require('dplyr') & require('readr') & require('stringr'))){
  install.packages(c('rtweet', 'dplyr','readr','stringr'),Ncpus = 2, repos = "https://cloud.r-project.org/")
}

library(dplyr)
library(stringr)
library(readr)
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
previous_tweets = read_csv("previous_tweets.csv", col_types = c('c'))
print(previous_tweets)

#Update previous tweets with timeline tweets to avoid discrepancy
timeline <- get_timeline('covid_data_bot') %>% select(id = reply_to_status_id)
previous_tweets <- bind_rows(previous_tweets, timeline) %>% distinct()
print(previous_tweets)

#SEARCH FOR ALL RECENT TWEETS TO HANDLE
tweets = search_tweets(q = "@covid_data_bot", include_rts = F)
#tweets <- get_mentions()
print(tweets)

#states_not_found <- tweets[1,]
#counties_not_found_2 <- tweets[1,]
#tweets = tibble(status_id = c('1'), text = c('Santa Clara County, CA, please'))

#LOOP THROUGH TWEET STATUS ID'S. IF STATUS IS NOT IN PREVIOUS TWEETS, AND COUNTY/STATE FOUND THEN REPLY.
for (i in 1:nrow(tweets)){
  print(tweets$status_id[i])
  
  
  #IF ID IS NOT IN PREVIOUS TWEETS
  if (!(tweets$status_id[i] %in% previous_tweets$id)){
    
    tweet_state <- states$state[str_detect(tweets$text[i], fixed(states$state,ignore_case = T))]
    print(tweet_state)
    
    #If multiple states are found, check for the most common issue: counties called 'Washington'
    if(length(tweet_state)>1){
      
      if('Washington' %in% tweet_state){
        tweet_state <- as_tibble(tweet_state) %>% 
          filter(value != 'Washington') %>% 
          as.vector()
        
        print(tweet_state)
      }
    }
    
    #If multiple states are still found, try to just take the longest state. 
    #This is specifically for West Virginia / Virginia and Arkansas / kansas
    if(length(tweet_state)>1){
        
        tweet_state <- tibble(tweet_state) %>% 
          mutate(length = str_length(tweet_state)) %>% 
          filter(length == max(length)) %>% 
          select(tweet_state) %>% 
          as.character()
      
      print(tweet_state)
    }
    
    #If a full state name is not found, check for capital abbreviation
    if(length(tweet_state) == 0){
      
      tweet_state <- states$state[str_detect(tweets$text[i], fixed(states$abbreviation,ignore_case = F))]
      print(tweet_state)
      
    }
    
    # IF A STATE IS FOUND
    if(length(tweet_state)==1){
      print('state found')
      
      #Look for counties only in the found state
      counties_subset <- counties %>% filter(state == as.character(tweet_state))
      
      tweet_county <- counties_subset$county[str_detect(tweets$text[i], fixed(counties_subset$county, ignore_case = T))]
      print(tweet_county)
      
      #If multiple counties are found, check to see if that state has a county named the same
      # E.g. arkansas county, arkansas
      if(length(tweet_county)>1 & (tweet_state %in% (counties %>% filter(state==county))$state ) ){
        
        tweet_county <- tibble(tweet_county) %>% 
          filter(tweet_county != tweet_state) %>% 
          as.vector()
        
        print(tweet_county)
      }
      
      
      #If multiple counties are still found, take the longest, most specific one
      if(length(tweet_county)>1){
        tweet_county <- tibble(tweet_county) %>% 
          mutate(length = str_length(tweet_county)) %>% 
          filter(length == max(length)) %>% 
          select(tweet_county) %>% 
          as.character()
      }
      
      #If county is not found, check for confusing counties with the same names as states
      if(length(tweet_county)==0){
        counties_not_found <- read_csv('counties_not_found.csv') 
        
        for(j in 1:length(counties_not_found$state)){
          
          tweet_state <- states$state[str_detect(tweets$text[i], fixed(states$state,ignore_case = T))]
          
          vec_1 <- c(counties_not_found$state[j], counties_not_found$county[j])
          
          if(length(intersect(vec_1,tweet_state))==2){
            tweet_state <- counties_not_found$state[j]
            tweet_county <- counties_not_found$county[j]
            
            print(tweet_state)
            print(tweet_county)
          }
        }
          
      }
      

      # IF A COUNTY IS FOUND
      if(length(tweet_county)==1){
        print('county found')
        
        #Get functions and data to draft tweet
        source('draft_tweet_functions.R')

        nyt_data <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv')
        pop_data <- read_csv('us_county_census.csv')

        #draft tweet. returns tweet text. plots are files written to directory
        
        ### Update to draft tweet based on fips!
        text <- draft_tweet(as.character(tweet_state), as.character(tweet_county), nyt_data, pop_data, tweets$screen_name[i])
        print(text)

        #Check again to see if tweet has already been replied to, because github actions are slow and can overlap
        #previous_tweets = read_csv("previous_tweets.csv", col_types = c('c'))

        update_timeline <- get_timeline('covid_data_bot') %>% select(id = reply_to_status_id)

         if (!(tweets$status_id[i] %in% update_timeline$id)){
           post_tweet(status = text,
                      media = c('plot_cases.png', 'plot_deaths.png', 'plot_risk.png', 'plot_state_map.png'),
                      in_reply_to_status_id = tweets$status_id[i])
         }

      }
      else{ 
        #counties_not_found_2 <- bind_rows(counties_not_found_2, tweets[i,])
        print('county not found')
      }
      
    } 
    else{ 
      #states_not_found <- bind_rows(states_not_found, tweets[i,])
      print('state not found')
      }
    
    #ADD TO PREVIOUS TWEETS
    previous_tweets = bind_rows(previous_tweets, tibble(id = tweets$status_id[i]))
    print('tweet archived')

  }
  
  print("Done!")
  
}

#previous_tweets = tibble(id = tweets$status_id, replied = T)
write_csv(previous_tweets,"previous_tweets.csv")



