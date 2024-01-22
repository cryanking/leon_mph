# Create fake dataset from ASOS dataset

## Install and load necessary packages
# install.packages("tidyverse")
library(tidyverse)
library(dplyr)
# install.packages("synthpop")
library(synthpop)
library(lubridate)
library(forcats)
library(data.table)

# Load existing dataset
options(warn = 1)
setwd("C:/Users/leona/Box/Research & Publications/ASOS dataset/")

ASOS_data <- read.csv("C:/Users/leona/Box/Research & Publications/ASOS dataset/ASOS_data.csv")

# prepare data for analysis
# change missing values to NA
ASOS_data[ASOS_data == "#NULL!"] <- NA

# get variables names
dput(names(ASOS_data))

# remove the variables we won't use in the analysis
ASOS_data <- ASOS_data %>% 
  dplyr::select("country", "age", "gender", "smoker", "asa", "black_ethnicity", 
                "chronic_comorbid___1", "chronic_comorbid___2", "chronic_comorbid___3", 
                "chronic_comorbid___4", "chronic_comorbid___5", "chronic_comorbid___6", 
                "chronic_comorbid___7", "chronic_comorbid___8", "chronic_comorbid___9", 
                "chronic_comorbid___10", "chronic_comorbid___11", "Hb", "induction_time", 
                "anaest_technique___1", "anaest_technique___2", "anaest_technique___3", 
                "anaest_technique___4", "anaest_technique___5", "anaest_technique___6", 
                "surg_proc_category", "urgency_surg", "surg_severity", "primary_indication_surg", 
                "surg_checklist", "blood_loss", "surg_duration", "ccafter_surg", 
                "anaest_complications___1", "anaest_complications___2", "anaest_complications___3", 
                "anaest_complications___4", "anaest_complications___5", "snr_anaest", 
                "snr_surg", "superficial_surg_site", "deep_surg_site", "body_cavity", 
                "pneumonia", "urinary_tract", "bloodstream", "myocardial_infarction", 
                "arrythmia", "pulmonary_oedema", "pulmonary_embolism", "stroke", 
                "cardiac_arrest", "gi_bleed", "acute_kidney_injury", "postop_bleed", 
                "ards", "anastomotic_leak", "other", "critical_care_admission", 
                "status_hosp_discharge", "Complications", 
                "Complications_infectious", "Complications_cardiovascular", "Complications_other", 
                "Severe_Complications", "DAG", "Hospital_Category", "DCP3_hospital_category", 
                "Cases_per_hospital", "hosp_beds", "hosp_theatres", "ccb_inv_vent", 
                "obstets", "surgeons", "anaesth", "Specialists")

# create combined anes_techniq variable, 1|General, 2|spinal-epidural, 3|Local-regional-sedation
ASOS_data$anes_techniq <-
  as.factor(with(ASOS_data,
                 ifelse(anaest_technique___1==1, 1,
                        ifelse(anaest_technique___2==1 & anaest_technique___1 !=1 | anaest_technique___3==1 & anaest_technique___1!=1,2,3))))


# transform numerical variables to numerical format
ASOS_data <- ASOS_data %>% 
  mutate_at(c("age", "Hb", "blood_loss", "surg_duration", "Specialists",
              "anaesth", "surgeons", "obstets", "ccb_inv_vent", "hosp_theatres", 
              "hosp_beds","Cases_per_hospital"), as.numeric)

#transform character variables to factor format
ASOS_data <- ASOS_data %>% 
  mutate_at(c("country", "gender", "smoker", "asa", "black_ethnicity", 
              "chronic_comorbid___1", "chronic_comorbid___2", "chronic_comorbid___3", 
              "chronic_comorbid___4", "chronic_comorbid___5", "chronic_comorbid___6", 
              "chronic_comorbid___7", "chronic_comorbid___8", "chronic_comorbid___9", 
              "chronic_comorbid___10", "chronic_comorbid___11", 
              "anaest_technique___1", "anaest_technique___2", "anaest_technique___3", 
              "anaest_technique___4", "anaest_technique___5", "anaest_technique___6", 
              "surg_proc_category", "urgency_surg", "surg_severity", "primary_indication_surg", 
              "surg_checklist", "ccafter_surg", 
              "anaest_complications___1", "anaest_complications___2", "anaest_complications___3", 
              "anaest_complications___4", "anaest_complications___5", "snr_anaest", 
              "snr_surg", "superficial_surg_site", "deep_surg_site", "body_cavity", 
              "pneumonia", "urinary_tract", "bloodstream", "myocardial_infarction", 
              "arrythmia", "pulmonary_oedema", "pulmonary_embolism", "stroke", 
              "cardiac_arrest", "gi_bleed", "acute_kidney_injury", "postop_bleed", 
              "ards", "anastomotic_leak", "other", "critical_care_admission", 
              "status_hosp_discharge", "Complications", "Complications_infectious", 
              "Complications_cardiovascular", "Complications_other", 
              "Severe_Complications", "DAG","Hospital_Category", "DCP3_hospital_category"),
            as.factor)

# transform datetime variable to datatime format
ASOS_data$induction_time <- as_datetime(ASOS_data$induction_time, format = "%Y/%m/%d %H:%M")
# problem: this creates NAs because not all datetime obs captured with same format
  
# check dataframe
head(ASOS_data)
summary(ASOS_data)

# Set a seed for reproducibility
set.seed(42)

# select random sample from ASOS_data to base fake dataset on
# limit to 10 countries and 40 hopitals to keep model stable
countries <- levels(ASOS_data$country)
rand.country <- sample(countries, 10, replace = F)
ltd_data <- ASOS_data[ASOS_data$country %in% rand.country, ]

DAG.names <- levels(ltd_data$DAG)
rand.hosp <- sample(DAG.names,40,replace = F)
ltd_data <- ltd_data[ltd_data$DAG %in% rand.hosp, ]

ltd_data <- droplevels(ltd_data) # remove empty levels in factors

# remove datetime from ltd_data because it causes problems with data synthesis 
# will add random sample from ASOS datetime variable to final fake dataset
ltd_data <- ltd_data %>% select(-induction_time)

# synthesize fake dataset 
# break dataset into indiv-level and hosp-level data for synthpop package
indiv_ltd <- ltd_data[,1:65]
fake_indiv <- syn(indiv_ltd, seed = 1072024)
hosp_ltd <- ltd_data[66:76]
fake_hosp <- syn(hosp_ltd, seed = 1072024)
# join indiv and hosp-level data side by side
fake_asos_ltd <- cbind(fake_indiv$syn, fake_hosp$syn)

# anonymize hospital names with fct_anon
fake_asos_ltd$DAG <- fct_anon(fake_asos_ltd$DAG)

# add datetime variable 
fake_asos_ltd$induction_time <- sample(ASOS_data$induction_time, 1450, replace = F)
summary(fake_asos_ltd)

#save to file
write.csv(fake_asos_ltd, file="fake_asos_ltd.csv")
