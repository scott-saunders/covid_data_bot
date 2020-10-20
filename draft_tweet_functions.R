#This script is called when the bot finds a new tweet or message to respond


if(!(require('ggplot2') & require('scales') & require('zoo') & require('mapproj') & require('tidyr'))){
  install.packages(c('ggplot2','scales','zoo','mapproj','tidyr'), Ncpus = 2)
}

library(ggplot2)
library(tidyr)
library(scales)
library(zoo)
library(mapproj)

#tweet_state <- 'Oklahoma'

#tweet_county <- 'Tulsa'
calculate_risk <- function(p_i, n){
  1-(1-p_i)^n
}

per_thousand_label <- function(x){
  # from s to ns
  lab <-  paste(x * 1000, "per 1k", sep = ' ')
}

per_hundred_thousand_label <- function(x){
  # from s to ns
  lab <-  paste(x * 100000, "per 100k", sep = ' ')
}

per_million_label <- function(x){
  # from s to ns
  lab <-  paste(x * 1000000, "per M", sep = ' ')
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

draft_tweet <- function(state, county, case_data, pop_data, screen_name){
  
  county_data <- case_data %>% 
    filter(state == !!state) %>% 
    filter(county == !!county) %>% 
    arrange(date) %>% 
    mutate(daily_cases = cases - lag(cases,1,default = 0),
           daily_deaths = deaths - lag(deaths,1,default = 0)) %>% 
    mutate(daily_cases = ifelse(daily_cases<0,0,daily_cases)) %>% 
    mutate(daily_deaths = ifelse(daily_deaths<0,0,daily_deaths)) %>% 
    mutate(day10_cases = cases - lag(cases,10),
           day10_deaths = deaths - lag(deaths,10)) %>% 
    filter(date == max(date)) %>% 
    left_join(.,pop_data,by = c('state','county','fips')) %>% 
    mutate(total_cases_pop = cases / pop2019,
           day10_cases_pop = day10_cases / pop2019,
           total_deaths_pop = deaths / pop2019)
  
  base_url <- 'https://covidactnow.org/us/'
  
  link <- paste0(base_url,
         str_replace(county_data$state,' ','_'),'-',
         county_data$abbreviation,'/county/',
         str_replace(county_data$county, ' ','_'),'_county')
  
  text <- paste0('@',screen_name," Here's #COVID19 data for #", str_replace(county,' ','')," County, #", str_replace(state,' ',''),
                 ' ', format(as.Date(county_data$date),'%D'),
                 '\n\n1d cases: ',comma(county_data$daily_cases),
                 '\nTotal: ', comma(county_data$cases), ' (', percent(county_data$total_cases_pop, accuracy = 0.1),' of pop)',
                 
                 '\n\n1d deaths: ',comma(county_data$daily_deaths),
                 '\nTotal: ', comma(county_data$deaths), ' (', comma(county_data$total_deaths_pop*100000), ' per 100k)' ,
                 '\n\nEst risk of ≥1 case in a random group of 100: ', 
                 percent(calculate_risk(county_data$day10_cases_pop, 100)),
                 ' - ',percent(calculate_risk(10*county_data$day10_cases_pop, 100)),
                 '\n\nFurther info: ', link
  )
  
  
  
  ####### Generate Plots
  
  county_data_series <- case_data %>% 
    filter(state == !!state) %>% 
    filter(county == !!county) %>% 
    arrange(date) %>% 
    mutate(daily_cases = cases - lag(cases,1,default = 0),
           daily_deaths = deaths - lag(deaths,1,default = 0)) %>% 
    mutate(daily_cases = ifelse(daily_cases<0,0,daily_cases)) %>% 
    mutate(daily_deaths = ifelse(daily_deaths<0,0,daily_deaths)) %>% 
    mutate(avg_daily_cases = rollmean(daily_cases, 7, fill = NA),
           avg_daily_deaths = rollmean(daily_deaths, 7, fill = NA))
  
  county_data_series <- case_data %>% 
    filter(state == !!state) %>% 
    filter(county == !!county) %>% 
    left_join(.,pop_data,by = 'fips') %>% 
    arrange(date) %>% 
    mutate(daily_cases = cases - lag(cases,1,default = 0),
           daily_deaths = deaths - lag(deaths,1,default = 0)) %>% 
    mutate(daily_cases = ifelse(daily_cases<0,0,daily_cases)) %>% 
    mutate(daily_deaths = ifelse(daily_deaths<0,0,daily_deaths)) %>% 
    mutate(daily_cases_pop = daily_cases / pop2019,
           daily_deaths_pop = daily_deaths / pop2019) %>% 
    mutate(avg_daily_cases_pop = rollmean(daily_cases_pop, 7, fill = NA),
           avg_daily_deaths_pop = rollmean(daily_deaths_pop, 7, fill = NA))
  
  plot_cases <- ggplot(county_data_series, aes(x = date, y = daily_cases_pop)) + 
    geom_point(size = 1, shape = 21) + 
    geom_line(aes(y = avg_daily_cases_pop), color = 'red', size = 1) +
    labs(x = 'Date', y = 'Daily reported cases', 
         title = paste0('Daily reported cases for ',county, ' County, ', state, ' - ',format(as.Date(county_data$date),'%D')),
         caption = 'Dots show daily reported cases per hundred thousand people. Red line shows 7 day rolling average. Source: NYT case data from @covid_data_bot') + 
    scale_y_continuous(labels = per_hundred_thousand_label)+
    theme_bw()+
    theme(plot.title = element_text(hjust = 0.5, size = 6), 
          axis.title = element_text(size=6),
          axis.text = element_text(size = 4),
          plot.caption = element_text(size = 4))
  
  ggsave("plot_cases.png",plot = plot_cases, width = 4, height = 2, units = 'in',dpi = 500)
  
  plot_deaths <- ggplot(county_data_series, aes(x = date, y = daily_deaths_pop)) + 
    geom_point(size = 1, shape = 21) + geom_line(aes(y = avg_daily_deaths_pop), color = 'red', size = 1) + 
    labs(x = 'Date', y = 'Daily reported deaths', 
         title = paste0('Daily reported deaths for ',county, ' County, ', state, ' - ',format(as.Date(county_data$date),'%D')),
         caption = 'Dots show daily reported deaths per million people. Red line shows 7 day rolling average. Source: NYT case data from @covid_data_bot') + 
    scale_y_continuous(labels = per_million_label)+
    theme_bw()+
    theme(plot.title = element_text(hjust = 0.5, size = 6), 
          axis.title = element_text(size=6),
          axis.text = element_text(size = 4),
          plot.caption = element_text(size = 4))
  
  ggsave("plot_deaths.png",plot = plot_deaths, width = 4, height = 2, units = 'in',dpi = 500)
  
  df_grid <- expand_grid(f_inf = c(county_data$day10_cases_pop, county_data$day10_cases_pop*5, county_data$day10_cases_pop*10), n = seq(0, 250, 10))
  df_calc <- df_grid %>% 
    mutate(risk = calculate_risk(f_inf, n))
  
  
  legend_labels <- c(paste0("Low\n1x (", percent(county_data$day10_cases_pop, accuracy = 0.01), ")"), 
                     paste0("Medium\n5x (", percent(county_data$day10_cases_pop*5,accuracy = 0.01), ")"),
                     paste0("High\n10x (", percent(county_data$day10_cases_pop*10, accuracy = 0.01), ")"))
  
  caption <- 'Note that all cases cannot be found & reported, so medium & high undercount scenarios are given. The chance an individual is infected is assumed to be the\n10 day case incidence, p. For a group of, n, people, the chance 1 or more are infected is, 1-(1-p)^n. Source: NYT case data analyzed by @covid_data_bot'
  
  plot_risk <- ggplot(df_calc, aes(x = n , y = risk, color = factor(percent(f_inf)), fill = factor(percent(f_inf)))) + 
    geom_path() + 
    geom_point(shape = 21, color = 'black', size = 1) +
    scale_y_continuous(labels = percent)+
    scale_color_viridis_d(name = '10 day county incidence\nfor 1-10x undercount', labels = legend_labels,option = 'B',)+ 
    scale_fill_viridis_d(name = '10 day county incidence\nfor 1-10x undercount', labels = legend_labels,option = 'B',) +
    labs(title = paste0('Group size risk assessment for ',county,' County, ', state, ' - ', format(as.Date(county_data$date),'%D')),
         caption = caption ,
         x = 'Number of people in a group', y = 'Chance at least 1 person is infected') + 
    theme_bw()+
    theme(plot.title = element_text(hjust = 0.5, size = 6), 
          axis.title = element_text(size=6),
          axis.text = element_text(size = 4),
          plot.caption = element_text(size = 4, hjust = 0.22),
          legend.title = element_text(size = 6, hjust = 0.5),
          legend.text = element_text(size = 6, hjust = 0.5))
  
  ggsave('plot_risk.png', plot_risk, width = 4, height = 2, units = 'in',dpi = 500)
  
  case_pop_state <- case_data %>% 
    filter(state == !!state) %>% 
    arrange(date) %>% 
    group_by(county,fips) %>% 
    mutate(day10_cases = cases-lag(cases,10)) %>% 
    filter(date == max(date)) %>% 
    ungroup() %>% 
    left_join(.,pop_data,by = c('state','county','fips')) %>% 
    mutate(total_cases_pop = cases / pop2019,
           day10_cases_pop = day10_cases / pop2019)
  
  county_map <- read_csv("us_county_map.csv")
  
  county_data_map <- left_join(county_map %>% filter(state_name == !!state), case_pop_state, by = c('county_fips' = 'fips'))
  
  plot_state_map <- ggplot(county_data_map, aes(long,lat, group = group)) +
    geom_polygon(aes(fill = day10_cases_pop), color = "white", size = 0.1)+
    geom_polygon(data = . %>% filter(county == !!county), fill = NA, color = 'red', size = 0.5)+
    coord_map(projection = "albers", lat0 = 39, lat1 = 45) +
    scale_fill_viridis_c(labels = per_hundred_thousand_label, 
                         option = 'B',
                         name = paste0('Ten day cases per capita\nfor ',state,' counties\n',
                                       format(as.Date(county_data$date),'%D'),
                                       '\nNYT data via\n@covid_data_bot'))+
    theme_nothing(legend = T) + 
    theme(legend.text = element_text(size = 4), legend.title = element_text(size = 4)) + guides(fill = guide_colourbar(label.position = "right", barwidth = 0.5))
  
  ggsave('plot_state_map.png', plot_state_map, width = 4, height = 2, units = 'in',dpi = 500)

  
  return(text)
}
