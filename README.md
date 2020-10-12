# Covid-19 data Twitter bot

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT) 

Welcome. This repository contains a simple twitter bot that replies to twitter posts and DM's with covid-19 data.

## Data sources

* US county level case and death data come from a dataset maintained by the New York Times. These and other datasets are publicly available at the [NYT github page](https://github.com/nytimes/covid-19-data).

## Recommended resources

* For basic information on Covid-19, including symptoms and general prevention strategies see the [CDC website](https://www.cdc.gov/coronavirus/2019-ncov/index.html).
* For detailed state and county level information, including maps, plots and risk level scores see [Covid Act Now](https://covidactnow.org/).
* For assessing the risk level of many person events, including county level maps, see the [COVID-19 Event Risk Assessment Planning Tool](https://covid19risk.biosci.gatech.edu/).

Many counties and states also have their own data dashboards. Often these are not well advertised, but may be well maintained. Googling may yield good results. 

## Details on provided data

We consider case loads and case averages over two week time spans. 

## Event risk calculation

This calculation simply asks the question: **What is the probability that no one is infected?** The probability that at least one person is infected will be 1 minus that value. Credit to [Joshua Weitz](https://twitter.com/joshuasweitz) for this idea.

The probability that any individual person is infected is the overall or population level infection rate, 
$$p_i$$ 

The probability they are not infected is

$$1-p_i$$. 

The probability that multiple people, $n$ are not infected is 

$$(1-p_i)^n$$

Finally, the probability that one or more people are infected among $n$ people is 

$$1-(1-p_i)^n$$

1x, 5x and 10x scenarios are given because cases are undercounts. 
