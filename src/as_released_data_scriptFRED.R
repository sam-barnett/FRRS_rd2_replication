#install.packages("fredr")
#install.packages("readxl")
#install.packages("tidyverse")


#clear directory 
rm(list=ls())

##### Importing libraries
library(fredr)
library(tidyverse)
library(readxl)



##### Setting up directory and FRED key
args <- commandArgs(trailingOnly = TRUE)
rawq_path <- args[1]
#setwd("C:/Users/illge/Princeton Dropbox/Sam Barnett/MianSufiRoll/round2_response/data_2024_update")
setwd(rawq_path)
fredr_set_key("cafdaa19383b90778737d5a663706ce5")



#### Creating function to get dates/values
original_data_creator = function(df, series_name, units){
for (obs in 1:nrow(df)){
  print(obs)
  month = format(df$release_date[obs], "%m")
  year = format(df$release_date[obs], "%Y")
  if (month == "01"){
    month = "12"
    year = as.numeric(year) - 1
  } else {
    month = as.numeric(month) - 1
  }
  # In this month CPI was released later than usual
  if (series_name == "CPILFESL" & df$release_date[obs] == "1996-02-01") {
    month = "12"
    year = "1995"
  }
  analyzed_date = paste(year, month, "01", sep = "-")
  df$month_pred[obs] = month
  df$year_pred[obs] = year
  vintage = df$release_date[obs]
  if (series_name == "CPILFESL" & year <= 1996) {
    vintage = "1996/12/12"
  }
  if (series_name == "GDPC1" & year <= 1991) {
    vintage = "1991/12/04"
  }
  df$observed_value[obs] = fredr(
    series_id = series_name,
    observation_start = as.Date(analyzed_date),
    observation_end = as.Date(analyzed_date),
    units = units, # change over previous value
    vintage_dates = as.Date(vintage)
  )$value[1]
}
return(df)
}




########### GDP
# get release dates from here: https://alfred.stlouisfed.org/release/downloaddates?rid=53
# the subscript xx after file denotes the "rid=xx" to include in the url
# gdp_dates = read_excel("data/orig/gdp_release_dates_53.xls")
# gdp_dates = tail(gdp_dates, -54)
gdp_dates = read_excel("FRED/release_dates_53_GDP.xlsx", sheet = "Release Dates") 
gdp_dates = gdp_dates[, 1]
names(gdp_dates) = "release_date"
#gdp_dates$release_date = as.Date(as.numeric(gdp_dates$release_date), origin = "1899-12-30")
gdp_dates = gdp_dates[format(gdp_dates$release_date, "%Y") >= 1993, ]

# For GDP, we need to only select the months with advanced report, which are: Jan, April, Jul, Oct
gdp_dates$month_released = format(gdp_dates$release_date, "%m")
gdp_dates = gdp_dates %>% filter(month_released %in% c("01", "04", "07", "10"))

# Loading up observations and creating the dataset
gdp_dates = original_data_creator(gdp_dates, "GDPC1", "pch")
gdp_dates$observed_value = ((gdp_dates$observed_value/100 + 1)^4 - 1)*100
gdp_dates = gdp_dates %>% drop_na(observed_value)
gdp_dates = gdp_dates %>% distinct(year_pred, month_pred, .keep_all = TRUE)
#write.csv(gdp_dates, "data/orig/gdp_values_dates.csv", row.names = FALSE)
write.csv(gdp_dates, "gdp_asreleased.csv", row.names= FALSE)


########### Payroll
### Loading up the dates
#payroll_dates = read_excel("data/orig/employment_release_dates_50.xls")
#payroll_dates = tail(payroll_dates, -35)
payroll_dates = read_excel("FRED/release_dates_50_UNEMP.xlsx", sheet = "Release Dates")
payroll_dates = payroll_dates[, 1]
names(payroll_dates) = "release_date"
#payroll_dates$release_date = as.Date(as.numeric(payroll_dates$release_date), origin = "1899-12-30")
payroll_dates = payroll_dates[format(payroll_dates$release_date, "%Y") >= 1990, ]

# Loading up observations and creating the dataset
payroll_dates = original_data_creator(payroll_dates, "PAYEMS", "chg")
payroll_dates = payroll_dates %>% distinct(year_pred, month_pred, .keep_all = TRUE)
write.csv(payroll_dates, "payroll_asreleased.csv", row.names = FALSE)


########### Unemployment
### Loading up the dates
unemp_dates = read_excel("FRED/release_dates_50_UNEMP.xlsx", sheet = "Release Dates")
unemp_dates = tail(unemp_dates, -35)
unemp_dates = unemp_dates[, 1]
names(unemp_dates) = "release_date"
#unemp_dates$release_date = as.Date(as.numeric(unemp_dates$release_date), origin = "1899-12-30")
unemp_dates = unemp_dates[format(unemp_dates$release_date, "%Y") >= 1990, ]

# Loading up observations and creating the dataset
unemp_dates = original_data_creator(unemp_dates, "UNRATE", "lin")
unemp_dates = unemp_dates %>% distinct(year_pred, month_pred, .keep_all = TRUE)
write.csv(unemp_dates, "unemp_asreleased.csv", row.names = FALSE)


########### CPI
#cpi_dates = read_excel("FRED/cpi_release_dates_10.xls")
#cpi_dates = tail(cpi_dates, -35)
cpi_dates = read_excel("FRED/release_dates_10_CPI.xlsx", sheet = "Release Dates")
cpi_dates = cpi_dates[, 1]
names(cpi_dates) = "release_date"
#cpi_dates$release_date = as.Date(as.numeric(cpi_dates$release_date), origin = "1899-12-30")
cpi_dates = cpi_dates[format(cpi_dates$release_date, "%Y") >= 1990, ]

# Loading up observations and creating the dataset
cpi_dates = original_data_creator(cpi_dates, "CPILFESL", "pch")
# Annualizing monthly CPI
cpi_dates = cpi_dates %>% group_by(month_pred, year_pred) %>% mutate(n_obs = n()) %>% ungroup()
cpi_dates = cpi_dates %>% filter(!(is.na(observed_value)) | n_obs == 1)
cpi_dates = cpi_dates %>% distinct(year_pred, month_pred, .keep_all = TRUE) %>% select(-c(n_obs))
write.csv(cpi_dates, "cpi_asreleased.csv", row.names = FALSE)


#fredr(
#  series_id = "GDPC1",
#  observation_start = as.Date("2017/09/01"),
#  observation_end = as.Date("2017/09/01"),
#  units = "pc1", # change over previous value
#  vintage_dates = as.Date("2017-10-03")
#)
