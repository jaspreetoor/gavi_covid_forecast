library(nimue)
library(ggplot2)
library(dplyr)
library(purrr)
library(furrr)
library(tidyverse)

source("R/functions.R")

# read in the gavi forecast data
gavi_data <- read_csv("data/cov_scenarios.csv") %>%
  select(scenario, iso3c, country, june_2021_cov, dec_2021_cov, dec_2022_cov_global_recov) %>%
  filter(!iso3c %in% c("DMA", "FSM", "MHL", "TUV", "XKX", "KIR", "PRK", "SLB", "TON", "WSM")) %>%
  mutate(vacc_scenario = "Vaccine")

# create 0 coverage option
gavi_data_0 <- gavi_data %>%
  mutate(dec_2021_cov = 0,
         dec_2022_cov_global_recov = 0,
         vacc_scenario = "Counterfactual")

gavi_data <- rbind(gavi_data, gavi_data_0)

# include other parameters
gavi_data$future_Rt <- 2
gavi_data$forecast <- as.integer(as.Date("2022-12-31") - as.Date("2021-08-19"))

gavi_data_2 <- gavi_data %>%
  mutate(future_Rt = 3.5)


scenarios <- rbind(gavi_data, gavi_data_2)

# save the parameters
write_csv(scenarios, "scenarios.csv")

#### Run the model #############################################################
plan(multiprocess, workers = 2)
system.time({out <- future_pmap(select(scenarios, -country, -june_2021_cov), create_vacc_fit, .progress = TRUE)})

#### Format output #############################################################
out <- do.call(rbind,out)

### Save output ################################################################
saveRDS(out, "output/output.rds")

