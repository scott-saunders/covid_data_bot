#This script is called when the bot finds a new tweet or message to respond

install.packages(c('tidyverse','scales','zoo'), Ncpus = 2)

library(tidyverse)
library(scales)
library(zoo)

#tweet_state <- 'Oklahoma'
#tweet_county <- 'Tulsa'
calculate_risk <- function(p_i, n){
  1-(1-p_i)^n
}

per_thousand_label <- function(x){
  # from s to ns
  lab <-  paste(x * 1000, "per 1k", sep = ' ')
}

theme_nothing <- function(base_size = 12, legend = FALSE){
  if(legend){
    theme(
      axis.text =          element_blank(),
      axis.title =         element_blank(),
      panel.background =   element_blank(),
      panel.grid.major =   element_blank(),
      panel.grid.minor =   element_blank(),
      axis.ticks.length =  unit(0, "cm"),
      panel.spacing =      unit(0, "lines"),
      plot.margin =        unit(c(0, 0, 0, 0), "lines")
    )
  } else {
    theme(
      line =               element_blank(),
      rect =               element_blank(),
      text =               element_blank(),
      axis.ticks.length =  unit(0, "cm"),
      legend.position =    "none",
      panel.spacing =      unit(0, "lines"),
      plot.margin =        unit(c(0, 0, 0, 0), "lines")
    )
  }
}

draft_tweet <- function(state, county, case_data, pop_data){
  
  county_data <- case_data %>% 
    filter(state == !!state) %>% 
    filter(county == !!county) %>% 
    arrange(date) %>% 
    mutate(biweekly_cases = cases - lag(cases,14),
           biweekly_deaths = deaths - lag(deaths,14)) %>% 
    filter(date == max(date)) %>% 
    left_join(.,pop_data,by = 'fips') %>% 
    mutate(total_cases_pop = cases / pop2019,
           biweekly_cases_pop = biweekly_cases / pop2019)
  
  #county_data
  
  text <- paste0("Here's a report for ", county," County, ", state,
                 ' - ', format(as.Date(county_data$date),'%D'),
                 '\n\nPast 2 weeks',
                 '\nCases: ', comma(county_data$biweekly_cases),
                 '\nDeaths: ', comma(county_data$biweekly_deaths),
                 '\n\nTotal',
                 '\nCases: ',comma(county_data$cases), 
                 ' (', percent(county_data$total_cases_pop, accuracy = 0.01),' of pop)',
                 '\nDeaths: ', comma(county_data$deaths),
                 '\n\nChance someone is infected in a random group of 100',
                 '\n1x reported cases: ', percent(calculate_risk(county_data$biweekly_cases_pop, 100)),
                 '\n5x: ',  percent(calculate_risk(5*county_data$biweekly_cases_pop, 100)),
                 '\n10x: ',  percent(calculate_risk(10*county_data$biweekly_cases_pop, 100))
  )
  
  return(text)
  
  ####### Generate Plots
  
  county_data_series <- case_data %>% 
    filter(state == !!state) %>% 
    filter(county == !!county) %>% 
    arrange(date) %>% 
    mutate(daily_cases = cases - lag(cases,1,default = 0),
           daily_deaths = deaths - lag(deaths,1,default = 0)) %>% 
    mutate(daily_cases = ifelse(daily_cases<0,0,daily_cases)) %>% 
    mutate(daily_deaths = ifelse(daily_deaths<0,0,daily_deaths)) %>% 
    mutate(avg_daily_cases = rollmean(daily_cases, 14, fill = NA),
           avg_daily_deaths = rollmean(daily_deaths, 14, fill = NA))
  
  plot_cases <- ggplot(county_data_series, aes(x = date, y = daily_cases)) + geom_point() + geom_line(aes(y = avg_daily_cases), color = 'red') + theme_bw()
  
  ggsave("plot_cases.png",plot = plot_cases, width = 4, height = 2, units = 'in')
  
  plot_deaths <- ggplot(county_data_series, aes(x = date, y = daily_deaths)) + geom_point() + geom_line(aes(y = avg_daily_deaths), color = 'red') + theme_bw()
  
  ggsave("plot_deaths.png",plot = plot_deaths, width = 4, height = 2, units = 'in')
  
  df_grid <- expand_grid(f_inf = c(county_data$biweekly_cases_pop, county_data$biweekly_cases_pop*5, county_data$biweekly_cases_pop*10), n = seq(0, 250, 10))
  df_calc <- df_grid %>% 
    mutate(risk = calculate_risk(f_inf, n))
  
  
  legend_labels <- c(paste0("1x Reported (", percent(county_data$biweekly_cases_pop), ")"), 
                     paste0("5x (", percent(county_data$biweekly_cases_pop*5), ")"),
                     paste0("10x (", percent(county_data$biweekly_cases_pop*10), ")"))
  
  plot_risk <- ggplot(df_calc, aes(x = n , y = risk, color = factor(percent(f_inf)), fill = factor(percent(f_inf)))) + 
    geom_path() + 
    geom_point(shape = 21, color = 'black') + theme_bw() + 
    scale_y_continuous(labels = percent)+
    scale_color_viridis_d(name = 'Percentage of county\nrecently infected', labels = legend_labels)+ 
    scale_fill_viridis_d(name = 'Percentage of county\nrecently infected', labels = legend_labels) +
    labs(title = paste0('What is the chance of someone being infected\nfor different scenarios in ',county,' county?'), 
         x = 'Number of people in a group', y = 'Chance at least 1 person is infected') + 
    theme(plot.title = element_text(hjust = 0.5), legend.position = 'bottom')
  
  ggsave('plot_risk.png', plot_risk, width = 4, height = 2, units = 'in')
  
  case_pop_state <- case_data %>% 
    filter(state == !!state) %>% 
    arrange(date) %>% 
    group_by(county,fips) %>% 
    mutate(biweekly_cases = cases-lag(cases,14)) %>% 
    filter(date == max(date)) %>% 
    ungroup() %>% 
    left_join(.,pop,by = 'fips') %>% 
    mutate(total_cases_pop = cases / pop2019,
           biweekly_cases_pop = biweekly_cases / pop2019)
  
  county_map <- read_csv("us_county_map.csv")
  
  county_data_map <- left_join(county_map %>% filter(state_name == !!state), case_pop_state, by = c('county_fips' = 'fips'))
  
  plot_state_map <- ggplot(county_data_map, aes(long,lat, group = group)) +
    geom_polygon(aes(fill = biweekly_cases_pop), color = "white", size = 0.1)+
    geom_polygon(data = . %>% filter(county == !!county), fill = NA, color = 'black', size = 0.5)+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
    scale_fill_viridis_c(labels = per_thousand_label, 
                         option = 'B',
                         name = paste0('Two week cases per capita\nfor ',state,' counties\n',
                                       format(as.Date(county_data$date),'%D'),
                                       '\nNYT data via\n@covid_data_bot'))+
    theme_nothing(legend = T) + 
    theme(legend.text = element_text(size = 4), legend.title = element_text(size = 4)) + guides(fill = guide_colourbar(label.position = "right", barwidth = 0.5))
  
  ggsave('plot_state_map.png', plot_state_map, width = 4, height = 2, units = 'in')
  
}
