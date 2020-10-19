# [COVID-19 data Twitter bot](https://twitter.com/covid_data_bot)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

Welcome. This repository contains a simple twitter bot, called @covid_data_bot, that replies to twitter posts and DM's with COVID-19 data for US counties.

## Data sources

* US county level case and death data come from a dataset maintained by the New York Times. These and other datasets are publicly available at the [NYT github page](https://github.com/nytimes/covid-19-data).

## Recommended resources

* For basic information on COVID-19, including symptoms and general prevention strategies see the [CDC website](https://www.cdc.gov/coronavirus/2019-ncov/index.html).
* For detailed state and county level information, including maps, plots and risk level scores see [Covid Act Now](https://covidactnow.org/).
* For assessing the risk level of many person events, including county level maps, see the [COVID-19 Event Risk Assessment Planning Tool](https://covid19risk.biosci.gatech.edu/).

Many counties and states also have their own data dashboards. Often these are not well advertised, but may be well maintained. Googling may yield good results. 

## Event risk calculation

This calculation simply asks the question: **What is the probability that no one is infected?** The probability that at least one person is infected will be 1 minus that value. Credit to [Joshua Weitz](https://twitter.com/joshuasweitz) and the [COVID-19 Event Risk Assessment Planning Tool](https://covid19risk.biosci.gatech.edu/) for this idea.

The probability that any individual person is infected is the overall or population level infection rate, <img src="https://render.githubusercontent.com/render/math?math=p_i">

The probability they are not infected is, <img src="https://render.githubusercontent.com/render/math?math=1 - p_i">

The probability that multiple people, <img src="https://render.githubusercontent.com/render/math?math=n"> are not infected is, <img src="https://render.githubusercontent.com/render/math?math=(1 - p_i)^n">

Finally, the probability that one or more people are infected among <img src="https://render.githubusercontent.com/render/math?math=n"> people is, <img src="https://render.githubusercontent.com/render/math?math=1 - (1 - p_i)^n">

1x, 5x and 10x scenarios are given because cases are undercounts. 

## How was this bot made?

This project was initially modeled on recent work by [Matt Dray](https://www.rostrum.blog/2020/09/21/londonmapbot/#fn2). This bot works through github actions. You can see the workflow file in the repository under `.github/workflows/`. This file runs a scheduled job approximately every 15 min. This workflow sets up an R environment, then runs the main .R script `covid_data_bot_v1.R`. 

This main script uses the package [rtweet](https://github.com/ropensci/rtweet) to search for recent tweets to @covid_data_bot. For each new tweet, the script tries to find a US state and county in the text. If found, the script reads in case data from the [NYT github](https://github.com/nytimes/covid-19-data) and then uses script `draft_tweet_functions.R` to generate a county level report.

The script then posts the tweet with associated plots and records that the response was completed. 



