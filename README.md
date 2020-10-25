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

## Special geographic cases

In general, the most consistent way for COVID data bot to read counties and states is to use the full names, not abbreviations. E.g. Los Angeles, California (not CA). Capitalization and punctuation should not matter.

### New York City 

NYC is actually comprised of 5 different counties, but NYT only reports data for the city as a whole. Therefore COVID data bot can respond to a request like so "@covid_data_bot New York City NY." However, New York City is not included in the county level state map.

### Washington, D.C.

Washington is actually in  the District of Columbia County, within the 'state' District of Columbia. Therefore COVID data bot will respond to any request with DC spelled out: "@covid_data_bot District of Columbia." For now, it cannot deal with the D.C. abbreviation alone, because it also needs the county "District of Columbia."

### Counties with State names (e.g. Washington County, Georgia)

Many states have counties named "Washington", which is also a state. Previously COVID data bot could not handle this, but now the issue should be resolved and should function correctly. 

There are also states that have counties with identical names (e.g. Arkansas County, Arkansas). COVID data bot should handle these correctly now. 

There are 9 other US counties that have state names (besides 'Washington') that were an issue. For example, "Colorado County, Texas." Now this issue should be resolved.

### Other issues

If you believe COVID data bot is not recognizing your county / state request, please message on twitter or open issue in github. 

Note that beyond simply identifying the correct state and county, COVID data bot must be able to find data for that county in the NYT dataset. If no data exists or there is an issue, then COVID data bot may fail or provide an empty report. 

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



