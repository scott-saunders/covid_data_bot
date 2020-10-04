install.packages(c('rtweet','tidyverse'))

library(rtweet)
library(tidyverse)

# create token named "twitter_token"
create_token(
  app = "covid_data_bot",  # the name of the Twitter app
  consumer_key = Sys.getenv("TWITTER_CONSUMER_API_KEY"),
  consumer_secret = Sys.getenv("TWITTER_CONSUMER_API_SECRET"),
  access_token = Sys.getenv("TWITTER_ACCESS_TOKEN"),
  access_secret = Sys.getenv("TWITTER_ACCESS_TOKEN_SECRET")
)


nyt_data <- read_csv('https://raw.githubusercontent.com/nytimes/covid-19-data/master/us-counties.csv') %>% 
  group_by(state, county, fips) %>% arrange(date) %>% 
  mutate(daily_cases = cases - lag(cases,1,default = 0),
         daily_deaths = deaths - lag(deaths,1,default = 0)) %>% 
  mutate(daily_cases = ifelse(daily_cases<0,0,daily_cases)) %>% 
  mutate(daily_deaths = ifelse(daily_deaths<0,0,daily_deaths))

counties <- nyt_data %>% group_by(state,county,fips) %>% summarise()

states <- counties %>% group_by(state) %>% summarise()


#READ IN PREVIOUS TWEETS
previous_tweets = read_csv("previous_tweets.csv", col_types = 'cl')

#SEARCH FOR ALL RECENT TWEETS TO HANDLE
tweets = search_tweets(q = "@covid_data_bot", include_rts = F)
#tweets$status_id
#tweets$text[1]
#post_tweet("This is a test with media", media = c("county_template_files/figure-html/unnamed-chunk-2-1.png","county_template_files/figure-html/unnamed-chunk-3-1.png" ))

#test set of tweet
#tweets = tibble(status_id = c(1,2,3), text =c('Cobb County, Georgia', 'a;lsdkjf', 'a;lskfj, Georgia'))


#LOOP THROUGH TWEET STATUS ID'S. IF STATUS IS NOT IN PREVIOUS TWEETS THEN REPLY.
for (i in 1:nrow(tweets)){
  print(tweets$status_id[i])
  
  
  #IF ID IS NOT IN PREVIOUS TWEETS
  if (!(tweets$status_id[i] %in% previous_tweets$id)){
    
    tweet_state <- states$state[str_detect(tweets$text[i], fixed(states$state))]
    print(tweet_state)
    
    
    if(length(tweet_state)==1){
      print('state found')
      
      counties_subset <- counties %>% filter(state == tweet_state)
      
      tweet_county <- counties_subset$county[str_detect(tweets$text[i], fixed(counties_subset$county))]
      print(tweet_county)
      
      if(length(tweet_county)==1){
        print('county found')
        
        #find most recent daily case / death count for this county
        most_recent <- nyt_data %>% 
          filter(state == tweet_state & county == tweet_county) %>% 
          filter(date == max(date))
        
        draft_tweet <- paste("This is a test reply to ",tweets$status_id[i],
                             '\nHere is some covid-19 info for ', tweet_county," County, ", tweet_state,
                             '\nfrom: ', most_recent$date,
                             '\nDaily cases: ', most_recent$daily_cases,
                             '\nDaily deaths: ', most_recent$daily_deaths,
                             '\nTotal cases to date: ',most_recent$cases,
                             '\nTotal deaths to date: ', most_recent$deaths,sep = '')
        print(draft_tweet)
        post_tweet(draft_tweet, in_reply_to_status_id = tweets$status_id[i])
        
        
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



