* Setup paths for FRRS replication
* Include this at the top of any .do file you want to run independently

version 19
clear all

/* ========== SET PATHS HERE ========== */
global code_folder "C:/Users/sb3357.SPI-9VS5N34/Princeton Dropbox/Sam Barnett/FRRS_rd2_replication/FRRS_code"
global code_folder "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_code"
global data_folder "C:\Users\sb3357.SPI-9VS5N34\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_data\data"
global data_folder "C:\Users\illge\Princeton Dropbox\Sam Barnett\FRRS_rd2_replication\FRRS_data\data"

global output "$code_folder/output"
global output_fig "$output/figures"
global output_tab "$output/tables"

global rawh "$data_folder/highfreq/raw"
global proch "$data_folder/highfreq/proc"

global rawq "$data_folder/quarterly/raw"
global procq "$data_folder/quarterly/proc"

global proc_analysis "$data_folder/proc_analysis"

global bootstrap_calculation "$code_folder/src/bootstrap_calculation"
global bootstrap_data "$data_folder/bootstrap"

global import_fred_snapshot "$data_folder/import_fred_snapshot"

sysdir set PERSONAL "$code_folder/ado"
set scheme sol, perm
