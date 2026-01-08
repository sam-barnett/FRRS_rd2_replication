#Import Intraday -- new friendlier approach. Now designed to be called from master_KLMS.do

##################################################
# 1) Load libraries & connect to WRDS
##################################################
rm(list = ls())

library(RPostgres)
library(DBI)
library(data.table)

wrds <- dbConnect(
  Postgres(),
  host    = "wrds-pgdata.wharton.upenn.edu",
  port    = 9737,
  dbname  = "wrds",
  sslmode = "require",
  user    = "sb3357",
  password = "grdBlcker#14"
)

##################################################
# 2) Output path
##################################################
#setwd("C:/Users/illge/Princeton Dropbox/Sam Barnett/FRRS_rd2_replication/data/highfreq/raw/WRDS/Intraday stocks")

args <- commandArgs(trailingOnly = TRUE)
rawh_path <- args[1]
fullpath <- file.path(rawh_path, "WRDS", "Intraday stocks")
setwd(fullpath)

dir.create("Stocks Last Trade", showWarnings = FALSE, recursive = TRUE)
out_dir <- "Stocks Last Trade"

##################################################
# 3) Loop over the years you need
##################################################
years_to_pull <- 2015       # edit as needed

for (yr in years_to_pull) {
  
  #yr <- 2020 
  message("==== Year ", yr, " ====")
  
  ## calendar of trading days for that year
  trading_dates <- dbGetQuery(
    wrds,
    sprintf("SELECT DISTINCT date
             FROM taqmsec.ctm_%d
             ORDER BY date;", yr)
  )$date                                   # keep as vector
  
  #trading_dates <- head(trading_dates, 2) 
  ## list to collect each day’s query result
  y_results <- vector("list", length(trading_dates))
  
  for (i in seq_along(trading_dates)) {
    
    if (!is.null(y_results[[i]])) next
    
    this_day <- trading_dates[i]
    message(" Date: ", this_day)
    
    ## window-function query – server does the 5-minute aggregation
    qry <- sprintf(
      "SELECT  date,
               sym_root,
               sym_suffix,
               extract(hour   FROM time_m)            AS hour,
               floor(extract(minute FROM time_m)/5)*5 AS bar_5min,
               price
       FROM (
         SELECT *,
                row_number() OVER (
                  PARTITION BY date,
                               sym_root,
                               sym_suffix,
                               extract(hour   FROM time_m),
                               floor(extract(minute FROM time_m)/5)*5
                  ORDER BY time_m DESC) AS rn
         FROM   taqmsec.ctm_%d
         WHERE  date = '%s'
       ) t
       WHERE rn = 1;",
      yr, this_day
    )
    
    
    #2 -- faster?
    qry <- sprintf(
      "SELECT date, sym_root, sym_suffix, hour_val AS hour, min5_val AS bar_5min, price
   FROM (
     SELECT date, sym_root, sym_suffix, time_m, price,
            extract(hour FROM time_m) AS hour_val,
            floor(extract(minute FROM time_m)/5)*5 AS min5_val,
            row_number() OVER (
              PARTITION BY date, sym_root, sym_suffix, 
                           extract(hour FROM time_m),
                           floor(extract(minute FROM time_m)/5)*5
              ORDER BY time_m DESC) AS rn
     FROM taqmsec.ctm_%d
     WHERE date = '%s'
   ) t
   WHERE rn = 1;",
      yr, this_day
    )
    
    ## run & fetch – result is already small, so one shot is fine
    y_results[[i]] <- as.data.table(dbGetQuery(wrds, qry))
    
    ## gentle pause so you don’t hammer the server
    Sys.sleep(0.1)
  }
  
  ## bind & write
  fwrite(
    rbindlist(y_results, use.names = TRUE),
    file.path(out_dir, sprintf("%d_5min_stocks.csv", yr))
  )
}

dbDisconnect(wrds)

