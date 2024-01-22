# MI for ASOS SSC analysis

# Multiple imputation for missing data: individual level covariates

# load packages
.libPaths( c( "/root/R/x86_64-pc-linux-gnu-library/4.3/" , .libPaths() ) )
library(groundhog) 
set.groundhog.folder('/root/R_groundhog/')
groundhog.library(c(
"dplyr" ,
"magrittr" ,
"lubridate" ,
"readr" ,
"mitml" 
) , '2024-01-15')


# set seed, warning, and working directory
set.seed(123)
options(warn = 1)

## RIS is kind of wierd in that the storage directory historically does not like how git manages files. Your home directory on RIS is limited to  (I think) 5 GB of space, which is usually adequate for code.
setwd("/code/")

# load dataset
ASOS_data <- read_csv("/code/fake_asos_ltd.csv")

# change all variables to factor or numeric
factor.cols <- c("country", "gender", "smoker", "asa", "black_ethnicity", 
                 "chronic_comorbid___1", "chronic_comorbid___2", "chronic_comorbid___3", 
                 "chronic_comorbid___4", "chronic_comorbid___5", "chronic_comorbid___6", 
                 "chronic_comorbid___7", "chronic_comorbid___8", "chronic_comorbid___9", 
                 "chronic_comorbid___10", "chronic_comorbid___11","induction_time", 
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
                 "Severe_Complications", "Hospital_Category", "DCP3_hospital_category")

numeric.cols <- c("blood_loss", "surg_duration","age","Hb",
                  "Cases_per_hospital", "hosp_beds", "hosp_theatres", 
                  "ccb_inv_vent", "obstets", "surgeons", "anaesth", "Specialists")

ASOS_data[factor.cols] <- lapply(ASOS_data[factor.cols], factor)
ASOS_data[numeric.cols] <- lapply(ASOS_data[numeric.cols], as.numeric)

# the clustering variable must be an integer for mice package
ASOS_data$DAG <- as.integer(ASOS_data$DAG)

# remove subjects with missing status_hosp_discharge (primary outcome)
ASOS_compl_death_dta <- ASOS_data[!(ASOS_data$status_hosp_discharge %in% NA),]

# MI with mitml package
# install.packages("mitml")

fml <- X + country + age + gender + smoker + asa + black_ethnicity + 
chronic_comorbid___1 + chronic_comorbid___2 + chronic_comorbid___3 + 
chronic_comorbid___4 + chronic_comorbid___5 + chronic_comorbid___6 + 
chronic_comorbid___7 + chronic_comorbid___8 + chronic_comorbid___9 +  
chronic_comorbid___10 + chronic_comorbid___11 + Hb + surg_proc_category +
urgency_surg + surg_severity + primary_indication_surg + surg_checklist + 
blood_loss + surg_duration + ccafter_surg + anaest_complications___1 + 
anaest_complications___2 + anaest_complications___3 + anaest_complications___4 + 
anaest_complications___5 + snr_anaest + snr_surg + superficial_surg_site + 
deep_surg_site + body_cavity + pneumonia + urinary_tract + bloodstream + 
myocardial_infarction + arrythmia + pulmonary_oedema + pulmonary_embolism + 
stroke + cardiac_arrest + gi_bleed + acute_kidney_injury + postop_bleed + 
ards + anastomotic_leak + other + critical_care_admission + status_hosp_discharge + 
Severe_Complications + Hospital_Category + DCP3_hospital_category + 
Cases_per_hospital + hosp_beds + hosp_theatres + ccb_inv_vent + obstets + 
surgeons + anaesth + Specialists + anes_techniq + induction_time ~
  1 + (1|DAG)

imp <- jomoImpute(ASOS_compl_death_dta, formula = fml, n.burn=50, n.iter = 10, m = 3)

summary(imp)
# increase n.burn (burn in number) to address potential scale reduction > 1.05
# increasing the n.burn to 50000 significantly improves potential scale reduction

plot(imp, trace = "all", print = "beta", pos = c(1,2))

# evaluate plots for convergience and autocorrelation

implist <- mitmlComplete(imp, "all")

# install.packages("howManyImputations")
impdata <- mitools::imputationList(split(imp, imp$data))
modelfit <- with(impdata, lmer(stasus_hosp_discharge ~ surg_checklist + anes_tegniq + age + asa + Hb + surg_severity + (1|DAG)))
how_many_imputations(modelfit)
