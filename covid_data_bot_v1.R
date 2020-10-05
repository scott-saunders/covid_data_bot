

install.packages(c('rtweet','tidyverse','scales'), Ncpus = 2)

library(rtweet)
library(tidyverse)
library(scales)

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

pop <- read_csv('co-est2019-alldata.csv') %>% 
  mutate(fips = paste0(STATE,COUNTY)) %>% 
  filter(COUNTY!='000') %>% 
  select(fips, pop2019 = POPESTIMATE2019)

tweet_state <- NULL
tweet_county <- NULL

draft_tweet_header <- '\U1F6A8***\U1F916***\U1F6A8\n'
draft_tweet_body <- paste0('Greetings. Here is an update for ', tweet_county, ' County, ', tweet_state,':\n')
#post_tweet(paste0(draft_tweet_header, draft_tweet_body))

#READ IN PREVIOUS TWEETS
previous_tweets = read_csv("previous_tweets.csv", col_types = 'cl')

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
        
        most_recent_pop <- left_join(most_recent, pop, by = 'fips') %>% 
          mutate(cases_per_pop = cases / pop2019)
        
        draft_tweet <- paste0("Greetings. Here's covid-19 data reported for ", tweet_county," County, ", tweet_state,
                             ' from ', format(as.Date(most_recent$date),'%D'),
                             '\n\nDaily cases: ', comma(most_recent$daily_cases),
                             '\nDaily deaths: ', comma(most_recent$daily_deaths),
                             '\nTotal cases: ',comma(most_recent$cases), 
                             ' (', percent(most_recent_pop$cases_per_pop, accuracy = 0.01),' of population)',
                             '\nTotal deaths: ', comma(most_recent$deaths),
                             '\n\nData source: NYT'
        )
        
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



